const { InviteError, inviteExpiry, inviteState, validateInvites } = require("./invites");
const { inviteEmail } = require("./mailer");
const { createGroup, readGroup } = require("./group_service");
const { addToAccount, groupExists, joinGroup } = require("./membership_store");
const { INVITES } = require("./firestore_paths");

/**
 * Pending invites live in the central project (`invites/{id}`), because an
 * invited person belongs to nothing yet and cannot read any organization
 * project. Membership starts on acceptance: until then nobody is added to a
 * group.
 */
function plain(doc) {
  const data = doc.data();
  return {
    id: doc.id,
    organizationId: data.organizationId,
    organizationName: data.organizationName,
    groupId: data.groupId,
    groupName: data.groupName,
    email: data.email,
    roles: data.roles,
    inviterName: data.inviterName,
    // ISO text: callable responses cannot carry a Date.
    expiresAt: (data.expiresAt?.toDate?.() ?? data.expiresAt)?.toISOString?.() ?? null,
    status: data.status,
  };
}

async function emailInvite(mailer, invite) {
  try {
    await mailer.send({ to: invite.email, ...inviteEmail(invite) });
    return true;
  } catch (error) {
    // The invite still works without the e-mail: the person sees it on
    // *Sem organização* when they sign in.
    console.error(`[invites] E-mail to ${invite.email} failed: ${error.message}`);
    return false;
  }
}

/**
 * Sends invites for group `groupId` of the organization (whose Firestore
 * is `db`), or creates the first group, `firstGroupName`, in the same
 * operation (if it cannot be created, nothing is sent). People already in
 * the group with those roles are skipped; a pending invite for the same
 * person and group is updated and its 14 days restart.
 *
 * @param {FirebaseFirestore.Firestore} centralDb
 * @param {FirebaseFirestore.Firestore} db - The organization's Firestore
 * @returns {Promise<{groupId: string, groupName: string,
 *   sent: Array<{email: string, roles: string[], emailed: boolean}>,
 *   skipped: Array<{email: string, reason: string}>}>}
 */
async function sendInvites(centralDb, db, mailer, request) {
  const { organizationId, organizationName, inviter } = request;
  const people = validateInvites(request.invites);
  const now = request.now ?? new Date();
  let groupId = request.groupId;
  if (request.firstGroupName) {
    groupId = (await createGroup(db, organizationId, request.firstGroupName, now)).id;
  }
  const target =
    typeof groupId === "string" && groupId ? await readGroup(db, organizationId, groupId) : null;
  if (!target) throw new InviteError("group", "Escolha um grupo.");

  const sent = [];
  const skipped = [];
  for (const person of people) {
    const member = target.people.find((p) => p.email === person.email);
    if (member && person.roles.every((r) => member.roles.includes(r))) {
      skipped.push({ email: person.email, reason: "Já está no grupo." });
      continue;
    }
    const existing = await centralDb
      .collection(INVITES)
      .where("organizationId", "==", organizationId)
      .where("groupId", "==", target.id)
      .where("email", "==", person.email)
      .where("status", "==", "pending")
      .get();
    const invite = {
      organizationId,
      organizationName,
      groupId: target.id,
      groupName: target.name,
      email: person.email,
      roles: person.roles,
      inviterEmail: inviter.email,
      inviterName: inviter.name || inviter.email,
      createdAt: now,
      expiresAt: inviteExpiry(now),
      status: "pending",
    };
    if (existing.empty) await centralDb.collection(INVITES).add(invite);
    else await existing.docs[0].ref.update(invite);
    sent.push({ ...person, emailed: await emailInvite(mailer, invite) });
  }
  return { groupId: target.id, groupName: target.name, sent, skipped };
}

/**
 * Cancels the pending invites of a deleted group.
 *
 * @returns {Promise<number>} How many were cancelled
 */
async function cancelGroupInvites(centralDb, organizationId, groupId) {
  const snapshot = await centralDb
    .collection(INVITES)
    .where("organizationId", "==", organizationId)
    .where("groupId", "==", groupId)
    .where("status", "==", "pending")
    .get();
  for (const doc of snapshot.docs) await doc.ref.update({ status: "cancelled" });
  return snapshot.docs.length;
}

/** The organization's pending and expired invites (of `groupId`, when given). */
async function listInvites(centralDb, organizationId, groupId, now = new Date()) {
  let query = centralDb
    .collection(INVITES)
    .where("organizationId", "==", organizationId)
    .where("status", "==", "pending");
  if (groupId) query = query.where("groupId", "==", groupId);
  const snapshot = await query.get();
  return snapshot.docs.map((doc) => {
    const invite = plain(doc);
    return { ...invite, expired: inviteState(invite, now) === "expired" };
  });
}

async function ownedInvite(centralDb, inviteId, organizationId) {
  const ref = centralDb.doc(`${INVITES}/${inviteId}`);
  const doc = await ref.get();
  if (!doc.exists || doc.get("organizationId") !== organizationId) {
    throw new InviteError("invite", "Convite não encontrado.");
  }
  return { ref, doc };
}

/**
 * The group of the organization's invite `inviteId`, so the caller's right
 * to manage it can be checked before resending or cancelling.
 *
 * @throws {InviteError} code `invite` when it is not the organization's
 */
async function inviteGroupId(centralDb, inviteId, organizationId) {
  const { doc } = await ownedInvite(centralDb, inviteId, organizationId);
  return String(doc.get("groupId") ?? "");
}

/** "Reenviar": a new 14-day period, and the e-mail again. */
async function resendInvite(centralDb, mailer, inviteId, organizationId, now = new Date()) {
  const { ref, doc } = await ownedInvite(centralDb, inviteId, organizationId);
  if (doc.get("status") !== "pending") {
    throw new InviteError("invite", "Esse convite já foi usado ou cancelado.");
  }
  const expiresAt = inviteExpiry(now);
  await ref.update({ expiresAt, createdAt: now });
  const emailed = await emailInvite(mailer, { ...doc.data(), expiresAt });
  return { expiresAt, emailed };
}

/** Cancels the invite: its link and *Aceitar* stop working. */
async function cancelInvite(centralDb, inviteId, organizationId) {
  const { ref } = await ownedInvite(centralDb, inviteId, organizationId);
  await ref.update({ status: "cancelled" });
}

/** The pending, unexpired invites addressed to `email`. */
async function myInvites(centralDb, email, now = new Date()) {
  const snapshot = await centralDb
    .collection(INVITES)
    .where("email", "==", email.toLowerCase())
    .where("status", "==", "pending")
    .get();
  return snapshot.docs.map(plain).filter((invite) => inviteState(invite, now) === "ok");
}

/**
 * Accepts invite `inviteId` as `email` (the signed-in account must be the
 * invited one): in one batch in the organization project, the person
 * becomes a member of the organization (if they were not) and of the group
 * with the invite's roles added to theirs; then the organization joins
 * their `accounts` entry and the invite is marked accepted. Valid at once:
 * the rules read the memberships. Expired, cancelled or used invites, and
 * invites to a deleted group, are refused.
 *
 * @param {(organizationId: string) => Promise<{db: FirebaseFirestore.Firestore}|null>}
 *   openOrganization - See `organizationOpener` (membership_store.js)
 */
async function acceptInvite(centralDb, openOrganization, inviteId, email, now = new Date()) {
  email = email.toLowerCase();
  const ref = centralDb.doc(`${INVITES}/${inviteId}`);
  const doc = await ref.get();
  if (!doc.exists || doc.get("email") !== email) {
    throw new InviteError("invite", "Convite não encontrado para esta conta.");
  }
  const invite = plain(doc);
  const state = inviteState(invite, now);
  if (state === "expired") {
    throw new InviteError("expired", "Este convite expirou. Peça um novo a quem convidou você.");
  }
  if (state !== "ok") {
    throw new InviteError("invite", "Este convite não vale mais.");
  }
  const organization = await openOrganization(invite.organizationId);
  if (
    !organization ||
    typeof invite.groupId !== "string" ||
    !invite.groupId ||
    !(await groupExists(organization.db, invite.organizationId, invite.groupId))
  ) {
    throw new InviteError("group", "O grupo deste convite não existe mais.");
  }
  await joinGroup(organization.db, invite.organizationId, invite.groupId, email, invite.roles, now);
  await addToAccount(centralDb, email, invite.organizationId);
  await ref.update({ status: "accepted", acceptedAt: now });
  return {
    organizationId: invite.organizationId,
    groupId: invite.groupId,
    organizationName: invite.organizationName,
    groupName: invite.groupName,
    roles: invite.roles,
    inviterName: invite.inviterName,
  };
}

module.exports = {
  acceptInvite,
  cancelGroupInvites,
  cancelInvite,
  inviteGroupId,
  listInvites,
  myInvites,
  resendInvite,
  sendInvites,
};
