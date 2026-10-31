const { parseGroupAddress } = require("./group_address");
const { OrganizationStatusError, transitionOrganizationStatus } = require("./organization_status");
const { ACCOUNT_DELETIONS, ORGANIZATIONS, POSITIONS, organizationPath } = require("./firestore_paths");

const DAY_MS = 24 * 60 * 60 * 1000;

/** A deleted account (and an owner's organization) can be restored for 30
 * days; then everything is erased. */
const ACCOUNT_GRACE_MS = 30 * DAY_MS;

class DeletionError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * Which of a person's direct groups they leave at once, grouped by
 * organization: every leaf (`<id>NNr` / `<id>NNw`) and the root group `<id>00`
 * of an organization they administer without owning it. The root group of a
 * organization they own is kept: the organization itself goes to `deleting`.
 *
 * @param {string[]} groupEmails - The person's direct groups
 * @param {string[]} [ownedOrganizationIds] - The organizations they own
 * @returns {Map<string, string[]>} organizationId → group e-mails
 */
function leavesByOrganization(groupEmails, ownedOrganizationIds = []) {
  const byOrganization = new Map();
  for (const email of groupEmails) {
    const address = parseGroupAddress(email);
    if (!address || address.level === 1) continue;
    if (address.level === 0 && ownedOrganizationIds.includes(address.organizationId)) continue;
    const group = `${address.teamKey}${address.leaf ?? ""}@monamienet.org`;
    byOrganization.set(address.organizationId, [...(byOrganization.get(address.organizationId) ?? []), group]);
  }
  return byOrganization;
}

/**
 * Schedules the deletion of `email`'s account: leaves every team, and the
 * root group of every organization they administer without owning it, now
 * (so they disappear from the maps), puts every organization they own in
 * `deleting` (nobody uses it meanwhile), and records what to restore if
 * they cancel within 30 days. An owner must confirm by typing the id of
 * each organization they own (`confirmIds`).
 *
 * @param {object} deps - `{groups: GroupsApi, directGroups: (email) =>
 *   Promise<string[]>}`
 * @returns {Promise<{deleteAt: Date, ownedOrganizationIds: string[],
 *   ownedOrganizationNames: Object<string, string>}>}
 */
async function requestAccountDeletion(db, deps, { email, uid, confirmIds = [] }, now = new Date()) {
  email = email.toLowerCase();
  const owned = await db
    .collection(ORGANIZATIONS)
    .where("ownerEmail", "==", email)
    .where("status", "==", "active")
    .get();
  const ownedOrganizationIds = owned.docs.map((d) => d.id).sort();
  // Shown on *Em exclusão* after the person signs out. Entries made before
  // in-app creation have no name; the app then shows the id.
  const ownedOrganizationNames = Object.fromEntries(
    owned.docs.filter((d) => typeof d.get("name") === "string").map((d) => [d.id, d.get("name")])
  );
  for (const id of ownedOrganizationIds) {
    if (!confirmIds.includes(id)) {
      throw new DeletionError("confirm", `Para confirmar, digite ${id}.`);
    }
  }
  const leaves = leavesByOrganization(await deps.directGroups(email), ownedOrganizationIds);
  const memberships = [];
  for (const [organizationId, groups] of leaves) {
    for (const leaf of groups) {
      const name = await deps.groups.lookup(leaf);
      if (name) await deps.groups.removeMember(name, email);
    }
    memberships.push({ organizationId, groups });
  }
  for (const id of ownedOrganizationIds) {
    await transitionOrganizationStatus(db, id, "deleting", {
      now,
      fields: { deletionRequestedBy: email },
    });
  }
  const deleteAt = new Date(now.getTime() + ACCOUNT_GRACE_MS);
  await db.doc(`${ACCOUNT_DELETIONS}/${email}`).set({
    email,
    uid,
    requestedAt: now,
    deleteAt,
    memberships,
    ownedOrganizationIds,
    ownedOrganizationNames,
    status: "pending",
  });
  return { deleteAt, ownedOrganizationIds, ownedOrganizationNames };
}

/** The pending deletion of `email`, or null. */
async function pendingDeletion(db, email) {
  const doc = await db.doc(`${ACCOUNT_DELETIONS}/${email.toLowerCase()}`).get();
  if (!doc.exists || doc.get("status") !== "pending") return null;
  return {
    requestedAt: doc.get("requestedAt")?.toDate?.() ?? doc.get("requestedAt"),
    deleteAt: doc.get("deleteAt")?.toDate?.() ?? doc.get("deleteAt"),
    ownedOrganizationIds: doc.get("ownedOrganizationIds") ?? [],
    ownedOrganizationNames: doc.get("ownedOrganizationNames") ?? {},
  };
}

/**
 * Cancels a pending deletion within its 30 days: rejoins the recorded
 * groups (teams and administered root groups) and brings the owned
 * organizations back to `active`.
 */
async function cancelAccountDeletion(db, deps, email, now = new Date()) {
  email = email.toLowerCase();
  const ref = db.doc(`${ACCOUNT_DELETIONS}/${email}`);
  const doc = await ref.get();
  if (!doc.exists || doc.get("status") !== "pending") {
    throw new DeletionError("none", "Não há exclusão para cancelar.");
  }
  const deleteAt = doc.get("deleteAt")?.toDate?.() ?? doc.get("deleteAt");
  if (deleteAt && deleteAt.getTime() <= now.getTime()) {
    throw new DeletionError("late", "O prazo para cancelar já terminou.");
  }
  for (const { groups } of doc.get("memberships") ?? []) {
    for (const leaf of groups) {
      const name = await deps.groups.lookup(leaf);
      if (name) await deps.groups.addMember(name, email);
    }
  }
  for (const id of doc.get("ownedOrganizationIds") ?? []) {
    try {
      await transitionOrganizationStatus(db, id, "active", { now });
    } catch (error) {
      if (!(error instanceof OrganizationStatusError)) throw error;
    }
  }
  await ref.delete();
}

/**
 * Erases the accounts whose 30 days are over. In each organization they belonged
 * to: `organizations/{id}/positions/{email}` with its trail and day
 * summaries, and their sign-in in that project.
 * Then their central sign-in, and the record itself, so nothing of them is
 * left. An organization already retired (its data gone with it) is skipped. Owned
 * organizations are erased by `expireOrganizations` when their own `deleting`
 * period ends.
 *
 * @param {object} deps - `{organization: (organizationId) => Promise<{db: Firestore,
 *   auth: Auth}|null>, deleteAuthUser: (uid) => Promise<void>}`
 * @returns {Promise<string[]>} The e-mails erased
 */
async function eraseDueAccounts(db, deps, now = new Date()) {
  // One range filter only, so no composite index is needed.
  const due = await db.collection(ACCOUNT_DELETIONS).where("deleteAt", "<=", now).get();
  const erased = [];
  for (const doc of due.docs) {
    if (doc.get("status") !== "pending") continue;
    const email = doc.get("email");
    const uid = doc.get("uid");
    for (const { organizationId } of doc.get("memberships") ?? []) {
      const organization = await deps.organization(organizationId);
      if (!organization) continue;
      const root = organization.db.doc(organizationPath(organizationId));
      await organization.db.recursiveDelete(root.collection(POSITIONS).doc(email));
      await deleteUserByEmail(organization.auth, email);
    }
    if (uid) await ignoreNotFound(deps.deleteAuthUser(uid));
    await doc.ref.delete();
    erased.push(email);
  }
  return erased;
}

async function deleteUserByEmail(auth, email) {
  try {
    const user = await auth.getUserByEmail(email);
    await auth.deleteUser(user.uid);
  } catch (error) {
    if (error?.code !== "auth/user-not-found") throw error;
  }
}

async function ignoreNotFound(promise) {
  try {
    await promise;
  } catch (error) {
    if (error?.code !== "auth/user-not-found") throw error;
  }
}

module.exports = {
  ACCOUNT_GRACE_MS,
  DeletionError,
  cancelAccountDeletion,
  eraseDueAccounts,
  leavesByOrganization,
  pendingDeletion,
  requestAccountDeletion,
};
