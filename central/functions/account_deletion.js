const { parseGroupAddress } = require("./group_address");
const { PartnerStatusError, transitionPartnerStatus } = require("./partner_status");

const DAY_MS = 24 * 60 * 60 * 1000;

/** A deleted account (and an owner's organization) can be restored for 30
 * days; then everything is erased. */
const ACCOUNT_GRACE_MS = 30 * DAY_MS;

const DELETIONS = "accountDeletions";

class DeletionError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * Which of a person's direct groups they leave at once, grouped by
 * partner: every leaf (`<id>NNr` / `<id>NNw`) and the root group `<id>00`
 * of a partner they administer without owning it. The root group of a
 * partner they own is kept: the organization itself goes to `deleting`.
 *
 * @param {string[]} groupEmails - The person's direct groups
 * @param {string[]} [ownedPartners] - The partners they own
 * @returns {Map<string, string[]>} partnerId → group e-mails
 */
function leavesByPartner(groupEmails, ownedPartners = []) {
  const byPartner = new Map();
  for (const email of groupEmails) {
    const address = parseGroupAddress(email);
    if (!address || address.level === 1) continue;
    if (address.level === 0 && ownedPartners.includes(address.partnerId)) continue;
    const group = `${address.teamKey}${address.leaf ?? ""}@monamienet.org`;
    byPartner.set(address.partnerId, [...(byPartner.get(address.partnerId) ?? []), group]);
  }
  return byPartner;
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
 * @returns {Promise<{deleteAt: Date, ownedPartners: string[],
 *   ownedNames: Object<string, string>}>}
 */
async function requestAccountDeletion(db, deps, { email, uid, confirmIds = [] }, now = new Date()) {
  email = email.toLowerCase();
  const owned = await db
    .collection("partners")
    .where("ownerEmail", "==", email)
    .where("status", "==", "active")
    .get();
  const ownedPartners = owned.docs.map((d) => d.id).sort();
  // Shown on *Em exclusão* after the person signs out. Entries made before
  // in-app creation have no name; the app then shows the id.
  const ownedNames = Object.fromEntries(
    owned.docs.filter((d) => typeof d.get("name") === "string").map((d) => [d.id, d.get("name")])
  );
  for (const id of ownedPartners) {
    if (!confirmIds.includes(id)) {
      throw new DeletionError("confirm", `Para confirmar, digite ${id}.`);
    }
  }
  const leaves = leavesByPartner(await deps.directGroups(email), ownedPartners);
  const memberships = [];
  for (const [partnerId, groups] of leaves) {
    for (const leaf of groups) {
      const name = await deps.groups.lookup(leaf);
      if (name) await deps.groups.removeMember(name, email);
    }
    memberships.push({ partnerId, groups });
  }
  for (const id of ownedPartners) {
    await transitionPartnerStatus(db, id, "deleting", {
      now,
      fields: { deletionRequestedBy: email },
    });
  }
  const deleteAt = new Date(now.getTime() + ACCOUNT_GRACE_MS);
  await db.doc(`${DELETIONS}/${email}`).set({
    email,
    uid,
    requestedAt: now,
    deleteAt,
    memberships,
    ownedPartners,
    ownedNames,
    status: "pending",
  });
  return { deleteAt, ownedPartners, ownedNames };
}

/** The pending deletion of `email`, or null. */
async function pendingDeletion(db, email) {
  const doc = await db.doc(`${DELETIONS}/${email.toLowerCase()}`).get();
  if (!doc.exists || doc.get("status") !== "pending") return null;
  return {
    requestedAt: doc.get("requestedAt")?.toDate?.() ?? doc.get("requestedAt"),
    deleteAt: doc.get("deleteAt")?.toDate?.() ?? doc.get("deleteAt"),
    ownedPartners: doc.get("ownedPartners") ?? [],
    ownedNames: doc.get("ownedNames") ?? {},
  };
}

/**
 * Cancels a pending deletion within its 30 days: rejoins the recorded
 * groups (teams and administered root groups) and brings the owned
 * organizations back to `active`.
 */
async function cancelAccountDeletion(db, deps, email, now = new Date()) {
  email = email.toLowerCase();
  const ref = db.doc(`${DELETIONS}/${email}`);
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
  for (const id of doc.get("ownedPartners") ?? []) {
    try {
      await transitionPartnerStatus(db, id, "active", { now });
    } catch (error) {
      if (!(error instanceof PartnerStatusError)) throw error;
    }
  }
  await ref.delete();
}

/**
 * Erases the accounts whose 30 days are over. In each partner they belonged
 * to: `partners/{id}/usuarios/{email}` with its trail and day summaries,
 * their `partners/{id}/users/*` profile and their sign-in in that project.
 * Then their central sign-in, and the record itself, so nothing of them is
 * left. A partner already retired (its data gone with it) is skipped. Owned
 * organizations are erased by `expirePartners` when their own `deleting`
 * period ends.
 *
 * @param {object} deps - `{partner: (partnerId) => Promise<{db: Firestore,
 *   auth: Auth}|null>, deleteAuthUser: (uid) => Promise<void>}`
 * @returns {Promise<string[]>} The e-mails erased
 */
async function eraseDueAccounts(db, deps, now = new Date()) {
  // One range filter only, so no composite index is needed.
  const due = await db.collection(DELETIONS).where("deleteAt", "<=", now).get();
  const erased = [];
  for (const doc of due.docs) {
    if (doc.get("status") !== "pending") continue;
    const email = doc.get("email");
    const uid = doc.get("uid");
    for (const { partnerId } of doc.get("memberships") ?? []) {
      const partner = await deps.partner(partnerId);
      if (!partner) continue;
      const root = partner.db.doc(`partners/${partnerId}`);
      await partner.db.recursiveDelete(root.collection("usuarios").doc(email));
      const profiles = await root.collection("users").where("email", "==", email).get();
      for (const profile of profiles.docs) await profile.ref.delete();
      await deleteUserByEmail(partner.auth, email);
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
  leavesByPartner,
  pendingDeletion,
  requestAccountDeletion,
};
