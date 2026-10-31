const {
  GROUPS,
  GROUP_MEMBERSHIPS,
  ORGANIZATION_MEMBERSHIPS,
  groupMembershipPath,
  groupPath,
  organizationPath,
} = require("./firestore_paths");
const {
  leaveGroup,
  leaveOrganization,
  leaveOrganizationIfGroupless,
  markPositionRemoved,
  GROUP_ROLES,
  sortedRoles,
} = require("./membership_store");
const { personKey } = require("./person_key");

/**
 * An organization's groups, managed by its administrators through the
 * central functions (the rules let no client write them):
 * `organizations/{id}/groups/{groupId}` `{name, createdAt}` with auto ids,
 * never reused, and `groupMemberships/{personKey}` under each.
 */

const MAX_GROUPS = 99;
const MIN_NAME = 2;
const MAX_NAME = 40;

/** The everyday roles in a group, which a maintainer may also give;
 * `maintainer` itself is given and taken only by administrators. */
const ASSIGNABLE_ROLES = Object.freeze(["publisher", "subscriber"]);

/** A Firestore auto id, or any id a test or a migration chose. */
const GROUP_ID = /^[A-Za-z0-9_-]{1,64}$/;

/**
 * Error the group functions return as `invalid-argument` (or
 * `failed-precondition` for `full`), with a message for the administrator.
 */
class GroupError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * The comparison form of a group name: no accents, lower case, single
 * spaces, trimmed. "Guias  Leste" and "guias léste" are the same group.
 *
 * @param {string} name
 * @returns {string}
 */
function normalizeGroupName(name) {
  return String(name)
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Validates a new (or renamed) group name against the organization's other
 * groups.
 *
 * @param {unknown} name - Requested name
 * @param {string[]} existingNames - Names of the other groups
 * @returns {string} The name to store: trimmed, inner spaces collapsed
 * @throws {GroupError} code `name` (too short or long, or not text) or
 *   `duplicate` (same name ignoring case, accents and spaces)
 */
function validateGroupName(name, existingNames) {
  if (typeof name !== "string") {
    throw new GroupError("name", "Dê um nome para o grupo.");
  }
  const clean = name.replace(/\s+/g, " ").trim();
  const letters = clean.replace(/[^\p{L}]/gu, "");
  if (letters.length < MIN_NAME) {
    throw new GroupError("name", "Use pelo menos 2 letras.");
  }
  if (clean.length > MAX_NAME) {
    throw new GroupError("name", `Use no máximo ${MAX_NAME} caracteres.`);
  }
  const wanted = normalizeGroupName(clean);
  const clash = existingNames.find((other) => normalizeGroupName(other) === wanted);
  if (clash !== undefined) {
    throw new GroupError("duplicate", `Já existe o grupo ${clash}.`);
  }
  return clean;
}

/**
 * Roles from a request, validated against `allowed` (by default the
 * everyday ones: `publisher`, who shares their location, and `subscriber`,
 * who sees the map), never none.
 *
 * @param {unknown} roles
 * @param {readonly string[]} [allowed]
 * @returns {string[]} Sorted, without duplicates
 * @throws {GroupError} code `roles`
 */
function validateRoles(roles, allowed = ASSIGNABLE_ROLES) {
  if (!Array.isArray(roles)) {
    throw new GroupError("roles", "Escolha pelo menos um papel.");
  }
  const set = new Set(roles);
  for (const role of set) {
    if (!allowed.includes(role)) {
      throw new GroupError("roles", `Papel desconhecido: ${role}.`);
    }
  }
  if (set.size === 0) {
    throw new GroupError("roles", "Escolha pelo menos um papel.");
  }
  return [...set].sort();
}

/**
 * The roles to store when someone changes a person's roles in a group.
 *
 * - An administrator gives exactly `requested`: any of `maintainer`,
 *   `publisher` and `subscriber`, at least one.
 * - A maintainer gives the everyday roles (at least one) and leaves the
 *   person's `maintainer` state as it is: kept when held, never granted.
 *
 * @param {string[]} currentRoles - The person's roles now
 * @param {unknown} requested
 * @param {boolean} byAdmin - Whether the caller administers the organization
 * @returns {string[]} Sorted
 * @throws {GroupError} `roles`, or `forbidden` when a maintainer asks to
 *   make someone a maintainer
 */
function rolesToStore(currentRoles, requested, byAdmin) {
  if (byAdmin) return validateRoles(requested, GROUP_ROLES);
  const holds = currentRoles.includes("maintainer");
  const asked = Array.isArray(requested) ? requested : null;
  if (asked?.includes("maintainer") && !holds) {
    throw new GroupError("forbidden", "Só um administrador nomeia gestores do grupo.");
  }
  const everyday = validateRoles(asked ? asked.filter((r) => r !== "maintainer") : requested);
  return holds ? sortedRoles([...everyday, "maintainer"]) : everyday;
}

/**
 * A group id from a request.
 *
 * @throws {GroupError} code `group`
 */
function validGroupId(groupId) {
  if (typeof groupId !== "string" || !GROUP_ID.test(groupId)) {
    throw new GroupError("group", "Grupo não encontrado.");
  }
  return groupId;
}

/**
 * Who leaves the organization if `groupId` is deleted: its people who are in
 * no other group and do not administer the organization.
 *
 * @param {string} groupId
 * @param {Array<{id: string, people: Array<{email: string}>}>} groups - Every
 *   group of the organization
 * @param {Set<string>} adminEmails
 * @returns {{loses: string[], stays: string[]}} Sorted e-mails
 */
function whoLosesAccess(groupId, groups, adminEmails) {
  const target = groups.find((g) => g.id === groupId);
  const loses = [];
  const stays = [];
  for (const { email } of target?.people ?? []) {
    const elsewhere =
      adminEmails.has(email) ||
      groups.some((g) => g.id !== groupId && g.people.some((p) => p.email === email));
    (elsewhere ? stays : loses).push(email);
  }
  return { loses: loses.sort(), stays: stays.sort() };
}

/** A Firestore time (or Date) as ISO text: callable responses carry no Date. */
function isoTime(value) {
  const at = value?.toDate?.() ?? value;
  return at instanceof Date && !Number.isNaN(at.getTime()) ? at.toISOString() : null;
}

/**
 * One group with its people, or null when it does not exist.
 *
 * @returns {Promise<{id: string, name: string, createdAt: string|null,
 *   people: Array<{email: string, roles: string[]}>}|null>}
 */
async function readGroup(db, organizationId, groupId) {
  const ref = db.doc(groupPath(organizationId, groupId));
  const doc = await ref.get();
  if (!doc.exists) return null;
  const memberships = await ref.collection(GROUP_MEMBERSHIPS).get();
  return {
    id: doc.id,
    name: String(doc.get("name") ?? ""),
    createdAt: isoTime(doc.get("createdAt")),
    people: memberships.docs
      .map((m) => ({ email: m.get("email"), roles: sortedRoles(m.get("roles")) }))
      .sort((a, b) => a.email.localeCompare(b.email)),
  };
}

/**
 * The organization's groups with their people, sorted by name:
 * `[{id, name, createdAt, people: [{email, roles}]}]`.
 */
async function listGroups(db, organizationId) {
  const snapshot = await db.collection(`${organizationPath(organizationId)}/${GROUPS}`).get();
  const groups = [];
  for (const doc of snapshot.docs) {
    const group = await readGroup(db, organizationId, doc.id);
    if (group) groups.push(group);
  }
  return groups.sort(
    (a, b) => normalizeGroupName(a.name).localeCompare(normalizeGroupName(b.name)) || a.id.localeCompare(b.id)
  );
}

/** The group, or a GroupError `group` when it does not exist. */
async function requireGroup(db, organizationId, groupId) {
  const group = await readGroup(db, organizationId, validGroupId(groupId));
  if (!group) throw new GroupError("group", "Grupo não encontrado.");
  return group;
}

/**
 * Creates a group with an auto id.
 *
 * @returns {Promise<{id: string, name: string}>}
 * @throws {GroupError} `name`, `duplicate` or `full` (99 groups)
 */
async function createGroup(db, organizationId, requestedName, now = new Date()) {
  const existing = await db.collection(`${organizationPath(organizationId)}/${GROUPS}`).get();
  const name = validateGroupName(
    requestedName,
    existing.docs.map((d) => String(d.get("name") ?? ""))
  );
  if (existing.docs.length >= MAX_GROUPS) {
    throw new GroupError("full", `A organização já tem ${MAX_GROUPS} grupos, o máximo.`);
  }
  const ref = await db
    .collection(`${organizationPath(organizationId)}/${GROUPS}`)
    .add({ name, createdAt: now });
  return { id: ref.id, name };
}

/** Changes the group's name; its id never changes. */
async function renameGroup(db, organizationId, groupId, requestedName) {
  const current = await requireGroup(db, organizationId, groupId);
  const others = await db.collection(`${organizationPath(organizationId)}/${GROUPS}`).get();
  const name = validateGroupName(
    requestedName,
    others.docs.filter((d) => d.id !== current.id).map((d) => String(d.get("name") ?? ""))
  );
  await db.doc(groupPath(organizationId, current.id)).update({ name });
  return { id: current.id, name };
}

/** The e-mails of the organization's administrators. */
async function adminEmails(db, organizationId) {
  const snapshot = await db
    .collection(`${organizationPath(organizationId)}/${ORGANIZATION_MEMBERSHIPS}`)
    .where("role", "==", "admin")
    .get();
  return new Set(snapshot.docs.map((d) => d.get("email")));
}

/**
 * Who would leave the organization if the group were deleted, for the
 * confirmation dialog: `{loses, stays}`.
 */
async function groupDeletionImpact(db, organizationId, groupId) {
  validGroupId(groupId);
  const groups = await listGroups(db, organizationId);
  return whoLosesAccess(groupId, groups, await adminEmails(db, organizationId));
}

/**
 * Deletes a group: the people left in no group leave the organization
 * (administrators stay), `cancelInvites` cancels the group's pending
 * invites, then the group goes with everything under it (memberships,
 * positions, trails). Repeating it finishes a deletion that stopped
 * halfway, even after the group document itself is gone.
 *
 * @param {() => Promise<unknown>} cancelInvites
 */
async function deleteGroup(db, centralDb, organizationId, groupId, cancelInvites) {
  const { loses } = await groupDeletionImpact(db, organizationId, groupId);
  for (const email of loses) {
    await leaveOrganization(db, centralDb, organizationId, email);
  }
  await cancelInvites();
  await db.recursiveDelete(db.doc(groupPath(organizationId, groupId)));
}

/**
 * Changes a person's roles in the group (see `rolesToStore`: an
 * administrator gives exactly `roles`, `maintainer` included; anyone else
 * the everyday roles, the person's `maintainer` state unchanged). Losing
 * `publisher` marks their position `removedAt`.
 *
 * @param {{byAdmin?: boolean}} [caller] - Defaults to a maintainer's powers
 * @returns {Promise<{roles: string[]}>} The roles stored
 * @throws {GroupError} `roles`, `forbidden`, `group` or `member` (not in the
 *   group: people join through an invite)
 */
async function setMemberRoles(
  db,
  organizationId,
  groupId,
  email,
  roles,
  now = new Date(),
  { byAdmin = false } = {}
) {
  const group = await requireGroup(db, organizationId, groupId);
  email = String(email ?? "").trim().toLowerCase();
  const person = group.people.find((p) => p.email === email);
  if (!person) throw new GroupError("member", "Essa pessoa não está no grupo.");
  const stored = rolesToStore(person.roles, roles, byAdmin);
  await db
    .doc(groupMembershipPath(organizationId, group.id, personKey(email)))
    .update({ roles: stored });
  if (person.roles.includes("publisher") && !stored.includes("publisher")) {
    await markPositionRemoved(db, organizationId, group.id, email, now);
  }
  return { roles: stored };
}

/**
 * Takes a person out of the group (their position is marked `removedAt`);
 * if that was their last group and they do not administer the
 * organization, they leave it too. Only an administrator removes a
 * maintainer: for anyone else that would take away a `maintainer` role.
 *
 * @param {{byAdmin?: boolean}} [caller] - Defaults to a maintainer's powers
 * @returns {Promise<{leftOrganization: boolean}>}
 * @throws {GroupError} `group`, `member` or `forbidden`
 */
async function removeMember(
  db,
  centralDb,
  organizationId,
  groupId,
  email,
  now = new Date(),
  { byAdmin = false } = {}
) {
  const group = await requireGroup(db, organizationId, groupId);
  email = String(email ?? "").trim().toLowerCase();
  const person = group.people.find((p) => p.email === email);
  if (!person) {
    throw new GroupError("member", "Essa pessoa não está no grupo.");
  }
  if (!byAdmin && person.roles.includes("maintainer")) {
    throw new GroupError("forbidden", "Só um administrador remove um gestor do grupo.");
  }
  await leaveGroup(db, organizationId, group.id, email, now);
  return {
    leftOrganization: await leaveOrganizationIfGroupless(db, centralDb, organizationId, email),
  };
}

module.exports = {
  ASSIGNABLE_ROLES,
  GroupError,
  MAX_GROUPS,
  createGroup,
  deleteGroup,
  groupDeletionImpact,
  listGroups,
  normalizeGroupName,
  readGroup,
  removeMember,
  renameGroup,
  requireGroup,
  rolesToStore,
  setMemberRoles,
  validGroupId,
  validateGroupName,
  validateRoles,
  whoLosesAccess,
};
