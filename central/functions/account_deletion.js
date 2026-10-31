const { OrganizationStatusError, transitionOrganizationStatus } = require("./organization_status");
const {
  ACCOUNT_DELETIONS,
  ORGANIZATIONS,
  accountDeletionPath,
  accountPath,
  groupMembershipPath,
  organizationMembershipPath,
} = require("./firestore_paths");
const {
  accountOrganizationIds,
  addToAccount,
  erasePerson,
  groupExists,
  leaveGroup,
  leaveOrganization,
  organizationMembership,
  personGroupMemberships,
} = require("./membership_store");
const { personKey } = require("./person_key");

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
 * Takes the person out of one organization when they ask to delete their
 * account: every group membership (positions marked `removedAt`, so they
 * disappear from the maps) and, unless they own it, their organization
 * membership and its `accounts` entry. An owner stays an administrator of
 * the organization, which goes to `deleting` instead.
 *
 * @returns {Promise<{organizationId: string, role: string|null,
 *   groups: Array<{groupId: string, roles: string[]}>}>} What was removed,
 *   for `cancelAccountDeletion`; `role` null when the organization
 *   membership was kept (or missing)
 */
async function leaveForDeletion(db, centralDb, organizationId, email, { owner, now }) {
  const groups = await personGroupMemberships(db, organizationId, email);
  for (const { groupId } of groups) {
    await leaveGroup(db, organizationId, groupId, email, now);
  }
  let role = null;
  if (!owner) {
    role = (await organizationMembership(db, organizationId, email))?.role ?? null;
    await leaveOrganization(db, centralDb, organizationId, email);
  }
  return { organizationId, role, groups };
}

/**
 * Schedules the deletion of `email`'s account: leaves every group of every
 * organization in their `accounts` entry now (so they disappear from the
 * maps), and every organization they do not own; puts every `active`
 * organization they own in `deleting` (nobody uses it meanwhile), and
 * records what to restore if they cancel within 30 days. An owner must
 * confirm by typing the id of each organization they own (`confirmIds`).
 *
 * @param {FirebaseFirestore.Firestore} db - Central Firestore
 * @param {{organizationDb: (organizationId: string) =>
 *   Promise<FirebaseFirestore.Firestore|null>}} deps
 * @returns {Promise<{deleteAt: Date, ownedOrganizationIds: string[],
 *   ownedOrganizationNames: Object<string, string>}>}
 */
async function requestAccountDeletion(db, deps, { email, uid, confirmIds = [] }, now = new Date()) {
  email = email.toLowerCase();
  const owned = await db.collection(ORGANIZATIONS).where("ownerEmail", "==", email).get();
  const ownedIds = new Set(owned.docs.map((d) => d.id));
  const ownedActive = owned.docs.filter((d) => d.get("status") === "active");
  const ownedOrganizationIds = ownedActive.map((d) => d.id).sort();
  // Shown on *Em exclusão* after the person signs out. Entries made before
  // in-app creation have no name; the app then shows the id.
  const ownedOrganizationNames = Object.fromEntries(
    ownedActive.filter((d) => typeof d.get("name") === "string").map((d) => [d.id, d.get("name")])
  );
  for (const id of ownedOrganizationIds) {
    if (!confirmIds.includes(id)) {
      throw new DeletionError("confirm", `Para confirmar, digite ${id}.`);
    }
  }
  const memberships = [];
  for (const organizationId of await accountOrganizationIds(db, email)) {
    const organizationDb = await deps.organizationDb(organizationId);
    if (!organizationDb) continue;
    memberships.push(
      await leaveForDeletion(organizationDb, db, organizationId, email, {
        owner: ownedIds.has(organizationId),
        now,
      })
    );
  }
  for (const id of ownedOrganizationIds) {
    await transitionOrganizationStatus(db, id, "deleting", {
      now,
      fields: { deletionRequestedBy: email },
    });
  }
  const deleteAt = new Date(now.getTime() + ACCOUNT_GRACE_MS);
  await db.doc(accountDeletionPath(personKey(email))).set({
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
  const doc = await db.doc(accountDeletionPath(personKey(email))).get();
  if (!doc.exists || doc.get("status") !== "pending") return null;
  return {
    requestedAt: doc.get("requestedAt")?.toDate?.() ?? doc.get("requestedAt"),
    deleteAt: doc.get("deleteAt")?.toDate?.() ?? doc.get("deleteAt"),
    ownedOrganizationIds: doc.get("ownedOrganizationIds") ?? [],
    ownedOrganizationNames: doc.get("ownedOrganizationNames") ?? {},
  };
}

/**
 * Cancels a pending deletion within its 30 days: writes back the recorded
 * memberships (the organization ones with their role and `accounts`
 * entry, and those of groups that still exist) and brings the owned
 * organizations back to `active`.
 */
async function cancelAccountDeletion(db, deps, email, now = new Date()) {
  email = email.toLowerCase();
  const ref = db.doc(accountDeletionPath(personKey(email)));
  const doc = await ref.get();
  if (!doc.exists || doc.get("status") !== "pending") {
    throw new DeletionError("none", "Não há exclusão para cancelar.");
  }
  const deleteAt = doc.get("deleteAt")?.toDate?.() ?? doc.get("deleteAt");
  if (deleteAt && deleteAt.getTime() <= now.getTime()) {
    throw new DeletionError("late", "O prazo para cancelar já terminou.");
  }
  const key = personKey(email);
  for (const { organizationId, role, groups } of doc.get("memberships") ?? []) {
    const organizationDb = await deps.organizationDb(organizationId);
    if (!organizationDb) continue;
    if (role) {
      await organizationDb
        .doc(organizationMembershipPath(organizationId, key))
        .set({ email, role, addedAt: now });
      await addToAccount(db, email, organizationId);
    }
    for (const { groupId, roles } of groups ?? []) {
      if (!(await groupExists(organizationDb, organizationId, groupId))) continue;
      await organizationDb
        .doc(groupMembershipPath(organizationId, groupId, key))
        .set({ email, organizationId, roles, addedAt: now });
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
 * Erases the accounts whose 30 days are over. In each organization they
 * belonged to when they asked (and any still in their `accounts` entry):
 * their memberships, their positions in every group with trails and day
 * summaries, and their sign-in in that project. Then their `accounts`
 * entry, their central sign-in, and the record itself, so nothing of them
 * is left. An organization already retired (its data gone with it) is
 * skipped. Owned organizations are erased by `expireOrganizations` when
 * their own `deleting` period ends.
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
    const organizationIds = new Set([
      ...(doc.get("memberships") ?? []).map((m) => m.organizationId),
      ...(await accountOrganizationIds(db, email)),
    ]);
    for (const organizationId of [...organizationIds].sort()) {
      const organization = await deps.organization(organizationId);
      if (!organization) continue;
      await erasePerson(organization.db, organizationId, email);
      await deleteUserByEmail(organization.auth, email);
    }
    if (uid) await ignoreNotFound(deps.deleteAuthUser(uid));
    await db.doc(accountPath(personKey(email))).delete();
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
  pendingDeletion,
  requestAccountDeletion,
};
