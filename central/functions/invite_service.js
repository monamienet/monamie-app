const { InviteError, inviteExpiry, inviteState, validateInvites } = require("./invites");
const { inviteEmail } = require("./mailer");
const { createTeam, listTeams } = require("./team_service");
const { teamGroupEmails } = require("./teams");

/**
 * Pending invites live in the central project (`invites/{id}`), because an
 * invited person has no group yet and cannot read any partner project.
 * Membership starts on acceptance: until then nobody is added to a group.
 */
const INVITES = "invites";

function plain(doc) {
  const data = doc.data();
  return {
    id: doc.id,
    partnerId: data.partnerId,
    partnerName: data.partnerName,
    team: data.team,
    teamName: data.teamName,
    email: data.email,
    roles: data.roles,
    invitedByName: data.invitedByName,
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
 * Sends invites for `team` (or creates the first team, `firstTeamName`,
 * in the same operation; if the team cannot be created, nothing is sent).
 * People already in the team with those roles are skipped; a pending
 * invite for the same person and team is updated and its 14 days restart.
 *
 * @returns {Promise<{team: string, teamName: string,
 *   sent: Array<{email: string, roles: string[], emailed: boolean}>,
 *   skipped: Array<{email: string, reason: string}>}>}
 */
async function sendInvites(db, api, mailer, request) {
  const { partnerId, partnerName, owner, now = new Date() } = request;
  const people = validateInvites(request.invites);
  let team = request.team;
  if (request.firstTeamName) {
    team = (await createTeam(api, partnerId, request.firstTeamName)).team;
  }
  const teams = await listTeams(api, partnerId);
  const target = teams.find((t) => t.team === team);
  if (!target) throw new InviteError("team", "Escolha uma equipe.");

  const sent = [];
  const skipped = [];
  for (const person of people) {
    const member = target.people.find((p) => p.email === person.email);
    if (member && person.roles.every((r) => member.roles.includes(r))) {
      skipped.push({ email: person.email, reason: "Já está na equipe." });
      continue;
    }
    const existing = await db
      .collection(INVITES)
      .where("partnerId", "==", partnerId)
      .where("team", "==", team)
      .where("email", "==", person.email)
      .where("status", "==", "pending")
      .get();
    const invite = {
      partnerId,
      partnerName,
      team,
      teamName: target.name,
      email: person.email,
      roles: person.roles,
      invitedBy: owner.email,
      invitedByName: owner.name || owner.email,
      invitedByEmail: owner.email,
      createdAt: now,
      expiresAt: inviteExpiry(now),
      status: "pending",
    };
    if (existing.empty) await db.collection(INVITES).add(invite);
    else await existing.docs[0].ref.update(invite);
    sent.push({ ...person, emailed: await emailInvite(mailer, invite) });
  }
  return { team, teamName: target.name, sent, skipped };
}

/** The partner's pending and expired invites (of `team`, when given). */
async function listInvites(db, partnerId, team, now = new Date()) {
  let query = db
    .collection(INVITES)
    .where("partnerId", "==", partnerId)
    .where("status", "==", "pending");
  if (team) query = query.where("team", "==", team);
  const snapshot = await query.get();
  return snapshot.docs.map((doc) => {
    const invite = plain(doc);
    return { ...invite, expired: inviteState(invite, now) === "expired" };
  });
}

async function ownedInvite(db, inviteId, partnerId) {
  const ref = db.doc(`${INVITES}/${inviteId}`);
  const doc = await ref.get();
  if (!doc.exists || doc.get("partnerId") !== partnerId) {
    throw new InviteError("invite", "Convite não encontrado.");
  }
  return { ref, doc };
}

/** "Reenviar": a new 14-day period, and the e-mail again. */
async function resendInvite(db, mailer, inviteId, partnerId, now = new Date()) {
  const { ref, doc } = await ownedInvite(db, inviteId, partnerId);
  if (doc.get("status") !== "pending") {
    throw new InviteError("invite", "Esse convite já foi usado ou cancelado.");
  }
  const expiresAt = inviteExpiry(now);
  await ref.update({ expiresAt, createdAt: now });
  const emailed = await emailInvite(mailer, { ...doc.data(), expiresAt });
  return { expiresAt, emailed };
}

/** Cancels the invite: its link and *Aceitar* stop working. */
async function cancelInvite(db, inviteId, partnerId) {
  const { ref } = await ownedInvite(db, inviteId, partnerId);
  await ref.update({ status: "cancelled" });
}

/** The pending, unexpired invites addressed to `email`. */
async function myInvites(db, email, now = new Date()) {
  const snapshot = await db
    .collection(INVITES)
    .where("email", "==", email.toLowerCase())
    .where("status", "==", "pending")
    .get();
  return snapshot.docs
    .map(plain)
    .filter((invite) => inviteState(invite, now) === "ok");
}

/**
 * Accepts invite `inviteId` as `email` (the signed-in account must be the
 * invited one): adds the person to the team's leaves for their roles and
 * marks the invite accepted. Expired, cancelled or used invites are
 * refused with the message the owner also sees.
 */
async function acceptInvite(db, api, inviteId, email, now = new Date()) {
  const ref = db.doc(`${INVITES}/${inviteId}`);
  const doc = await ref.get();
  if (!doc.exists || doc.get("email") !== email.toLowerCase()) {
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
  const emails = teamGroupEmails(invite.partnerId, invite.team);
  for (const role of invite.roles) {
    const leaf = await api.lookup(role === "watch" ? emails.watch : emails.share);
    if (!leaf) throw new InviteError("team", "A equipe deste convite não existe mais.");
    await api.addMember(leaf, invite.email);
  }
  await ref.update({ status: "accepted", acceptedAt: now });
  return {
    partnerId: invite.partnerId,
    partnerName: invite.partnerName,
    teamName: invite.teamName,
    roles: invite.roles,
    invitedByName: invite.invitedByName,
  };
}

module.exports = {
  acceptInvite,
  cancelInvite,
  listInvites,
  myInvites,
  resendInvite,
  sendInvites,
};
