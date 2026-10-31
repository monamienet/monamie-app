const { FieldValue } = require("firebase-admin/firestore");
const { isValidOrganizationId } = require("./organization_id");
const { projectIdFor } = require("./organization_options");
const { personKey } = require("./person_key");
const {
  ACCOUNTS,
  GROUP_MEMBERSHIPS,
  POSITIONS,
  accountPath,
  groupMembershipPath,
  groupPath,
  groupPositionPath,
  organizationMembershipPath,
  organizationPath,
} = require("./firestore_paths");

/**
 * Where memberships live and how the central functions reach them.
 *
 * - Organization project (Standard `monamienet-<id>`, Community
 *   `monamienet-community`), under `organizations/{id}/`:
 *   `organizationMemberships/{personKey}` `{email, role, addedAt}` and
 *   `groups/{groupId}/groupMemberships/{personKey}`
 *   `{email, organizationId, roles, addedAt}`. They are the truth.
 * - Central project: `accounts/{personKey}` `{email, organizationIds}`, an
 *   index of them written after the organization project ("the organization
 *   wins": an extra id is ignored by the app, a missing one is reported by
 *   `tool/organization.dart check`).
 *
 * Every function takes the Firestore it writes to, so tests pass fakes.
 */

/** Roles a person may hold in a group: `maintainer` (*Gestor do grupo*,
 * manages the group, see group_access.js), `publisher`, `subscriber`. */
const GROUP_ROLES = Object.freeze(["maintainer", "publisher", "subscriber"]);

/**
 * Opens organizations' Firestore from the central registry: the project
 * follows the entry's `plan`.
 *
 * @param {FirebaseFirestore.Firestore} centralDb
 * @param {(projectId: string) => FirebaseFirestore.Firestore} projectFirestore
 * @returns {(organizationId: unknown) => Promise<{db: FirebaseFirestore.Firestore,
 *   registry: object}|null>} null for an invalid id or a missing entry
 */
function organizationOpener(centralDb, projectFirestore) {
  return async (organizationId) => {
    if (!isValidOrganizationId(organizationId)) return null;
    const registry = await centralDb.doc(organizationPath(organizationId)).get();
    if (!registry.exists) return null;
    return {
      db: projectFirestore(projectIdFor(organizationId, registry.get("plan"))),
      registry: registry.data(),
    };
  };
}

/** `roles` without duplicates or unknown values, sorted. */
function sortedRoles(roles) {
  return [...new Set(roles ?? [])].filter((r) => GROUP_ROLES.includes(r)).sort();
}

/**
 * The person's membership of the organization, or null.
 *
 * @returns {Promise<{email: string, role: string}|null>}
 */
async function organizationMembership(db, organizationId, email) {
  const doc = await db.doc(organizationMembershipPath(organizationId, personKey(email))).get();
  return doc.exists ? { email: doc.get("email"), role: doc.get("role") } : null;
}

/**
 * The person's group memberships in the organization: a collection-group
 * query on `groupMemberships` by `email` and `organizationId` (the indexes
 * are in firestore.indexes.json).
 *
 * @returns {Promise<Array<{groupId: string, roles: string[]}>>} By group id
 */
async function personGroupMemberships(db, organizationId, email) {
  const snapshot = await db
    .collectionGroup(GROUP_MEMBERSHIPS)
    .where("email", "==", email.toLowerCase())
    .where("organizationId", "==", organizationId)
    .get();
  return snapshot.docs
    .map((doc) => ({ groupId: doc.ref.parent.parent.id, roles: sortedRoles(doc.get("roles")) }))
    .sort((a, b) => a.groupId.localeCompare(b.groupId));
}

/**
 * Makes `email` a member of the organization (`member`, unless they already
 * have a role) and of the group with `roles` added to what they hold, in
 * one batch.
 */
async function joinGroup(db, organizationId, groupId, email, roles, now) {
  email = email.toLowerCase();
  const key = personKey(email);
  const memberRef = db.doc(organizationMembershipPath(organizationId, key));
  const groupRef = db.doc(groupMembershipPath(organizationId, groupId, key));
  const [member, current] = await Promise.all([memberRef.get(), groupRef.get()]);
  const batch = db.batch();
  if (!member.exists) batch.set(memberRef, { email, role: "member", addedAt: now });
  batch.set(groupRef, {
    email,
    organizationId,
    roles: sortedRoles([...(current.exists ? current.get("roles") : []), ...roles]),
    addedAt: current.exists ? current.get("addedAt") ?? now : now,
  });
  await batch.commit();
}

/**
 * Marks the person's position in the group as no longer published
 * (`removedAt`), so the map leaves it out and the history keeps it. Nothing
 * happens when they never published there.
 */
async function markPositionRemoved(db, organizationId, groupId, email, now) {
  const ref = db.doc(groupPositionPath(organizationId, groupId, personKey(email)));
  if ((await ref.get()).exists) await ref.update({ removedAt: now });
}

/** Deletes the person's membership of the group, marking their position. */
async function leaveGroup(db, organizationId, groupId, email, now) {
  await markPositionRemoved(db, organizationId, groupId, email, now);
  await db.doc(groupMembershipPath(organizationId, groupId, personKey(email))).delete();
}

/** Adds the organization to the person's `accounts` entry. */
async function addToAccount(centralDb, email, organizationId) {
  email = email.toLowerCase();
  await centralDb.doc(accountPath(personKey(email))).set(
    { email, organizationIds: FieldValue.arrayUnion(organizationId) },
    { merge: true }
  );
}

/** Removes the organization from the person's `accounts` entry, if any. */
async function removeFromAccount(centralDb, email, organizationId) {
  const ref = centralDb.doc(accountPath(personKey(email)));
  if ((await ref.get()).exists) {
    await ref.update({ organizationIds: FieldValue.arrayRemove(organizationId) });
  }
}

/** The organizations of the person's `accounts` entry. */
async function accountOrganizationIds(centralDb, email) {
  const doc = await centralDb.doc(accountPath(personKey(email))).get();
  const ids = doc.exists ? doc.get("organizationIds") : [];
  return Array.isArray(ids) ? [...new Set(ids.filter((id) => typeof id === "string"))].sort() : [];
}

/** Removes a retired organization from every `accounts` entry. */
async function removeOrganizationFromAccounts(centralDb, organizationId) {
  const snapshot = await centralDb
    .collection(ACCOUNTS)
    .where("organizationIds", "array-contains", organizationId)
    .get();
  for (const doc of snapshot.docs) {
    await doc.ref.update({ organizationIds: FieldValue.arrayRemove(organizationId) });
  }
  return snapshot.docs.length;
}

/**
 * Takes the person out of the organization: their organization membership
 * and the id in their `accounts` entry (organization project first).
 */
async function leaveOrganization(db, centralDb, organizationId, email) {
  await db.doc(organizationMembershipPath(organizationId, personKey(email))).delete();
  await removeFromAccount(centralDb, email, organizationId);
}

/**
 * Takes a non-administrator who is left in no group out of the
 * organization, as leaving every team did with Google Groups.
 *
 * @returns {Promise<boolean>} Whether they left
 */
async function leaveOrganizationIfGroupless(db, centralDb, organizationId, email) {
  const membership = await organizationMembership(db, organizationId, email);
  if (membership?.role === "admin") return false;
  if ((await personGroupMemberships(db, organizationId, email)).length > 0) return false;
  await leaveOrganization(db, centralDb, organizationId, email);
  return true;
}

/**
 * Erases what the organization project keeps of the person: their group
 * memberships, their positions in every group with trail and day summaries
 * (a collection-group query on `positions` by `email`, kept to this
 * organization's path), and their organization membership.
 */
async function erasePerson(db, organizationId, email) {
  email = email.toLowerCase();
  for (const { groupId } of await personGroupMemberships(db, organizationId, email)) {
    await db.doc(groupMembershipPath(organizationId, groupId, personKey(email))).delete();
  }
  const prefix = `${organizationPath(organizationId)}/`;
  const positions = await db.collectionGroup(POSITIONS).where("email", "==", email).get();
  for (const doc of positions.docs) {
    if (doc.ref.path.startsWith(prefix)) await db.recursiveDelete(doc.ref);
  }
  await db.doc(organizationMembershipPath(organizationId, personKey(email))).delete();
}

/** Whether group `groupId` exists in the organization. */
async function groupExists(db, organizationId, groupId) {
  return (await db.doc(groupPath(organizationId, groupId)).get()).exists;
}

module.exports = {
  GROUP_ROLES,
  accountOrganizationIds,
  addToAccount,
  erasePerson,
  groupExists,
  joinGroup,
  leaveGroup,
  leaveOrganization,
  leaveOrganizationIfGroupless,
  markPositionRemoved,
  organizationMembership,
  organizationOpener,
  personGroupMemberships,
  removeFromAccount,
  removeOrganizationFromAccounts,
  sortedRoles,
};
