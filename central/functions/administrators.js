const { addToAccount } = require("./membership_store");
const { personKey } = require("./person_key");
const {
  ORGANIZATION_MEMBERSHIPS,
  organizationMembershipPath,
  organizationPath,
} = require("./firestore_paths");

/**
 * The owner's *Administradores* screen: who administers the organization,
 * appointing an existing member as administrator and turning an
 * administrator back into a member. Only the owner (`ownerEmail` in the
 * central registry, who created the organization) does this, and the owner
 * is always an administrator: never a target.
 *
 * Changing a role keeps the person in the organization. A demoted
 * administrator in no group stays as a member in no group (they see no
 * map until someone invites them to a group): nobody is removed from the
 * organization without being told.
 */

/** Error the administrators functions return, with a message for the owner. */
class AdministratorError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/** Whether `email` is the owner recorded in `registry` (case ignored). */
function isOwner(registry, email) {
  const owner = String(registry?.ownerEmail ?? "").trim().toLowerCase();
  return owner !== "" && owner === String(email ?? "").trim().toLowerCase();
}

/**
 * The organization's Firestore and owner when `email` owns it and it is
 * `active`, else null.
 *
 * @param {(organizationId: unknown) => Promise<{db: FirebaseFirestore.Firestore,
 *   registry: object}|null>} openOrganization - See `organizationOpener`
 * @returns {Promise<{db: FirebaseFirestore.Firestore, ownerEmail: string}|null>}
 */
async function ownedOrganization(openOrganization, organizationId, email) {
  if (!email) return null;
  const organization = await openOrganization(organizationId);
  if (!organization || organization.registry?.status !== "active") return null;
  if (!isOwner(organization.registry, email)) return null;
  return { db: organization.db, ownerEmail: String(email).trim().toLowerCase() };
}

/**
 * Splits organization memberships into administrators (the owner first,
 * flagged, then by e-mail) and members (by e-mail).
 *
 * @param {Array<{email: unknown, role: unknown}>} memberships
 * @param {string} ownerEmail
 * @returns {{administrators: Array<{email: string, owner: boolean}>,
 *   members: Array<{email: string}>}}
 */
function splitByRole(memberships, ownerEmail) {
  const administrators = [];
  const members = [];
  for (const { email, role } of memberships) {
    if (typeof email !== "string" || !email) continue;
    const owner = email === ownerEmail;
    if (role === "admin" || owner) administrators.push({ email, owner });
    else if (role === "member") members.push({ email });
  }
  administrators.sort((a, b) => Number(b.owner) - Number(a.owner) || a.email.localeCompare(b.email));
  members.sort((a, b) => a.email.localeCompare(b.email));
  return { administrators, members };
}

/** The organization's administrators and members, see `splitByRole`. */
async function listAdministrators(db, organizationId, ownerEmail) {
  const snapshot = await db
    .collection(`${organizationPath(organizationId)}/${ORGANIZATION_MEMBERSHIPS}`)
    .get();
  return splitByRole(
    snapshot.docs.map((d) => ({ email: d.get("email"), role: d.get("role") })),
    ownerEmail
  );
}

/**
 * Makes member `email` an administrator (`admin: true`) or an
 * administrator a member again (`admin: false`). Their `accounts` entry is
 * made sure to list the organization (they stay in it either way).
 *
 * @param {FirebaseFirestore.Firestore} db - The organization's Firestore
 * @param {FirebaseFirestore.Firestore} centralDb
 * @returns {Promise<{email: string, role: "admin"|"member"}>}
 * @throws {AdministratorError} `email`, `owner` (the owner is always an
 *   administrator) or `member` (not in the organization: people join through
 *   an invite)
 */
async function setAdministrator(db, centralDb, organizationId, ownerEmail, email, admin) {
  if (typeof admin !== "boolean") {
    throw new AdministratorError("admin", "Diga se a pessoa administra ou não.");
  }
  email = typeof email === "string" ? email.trim().toLowerCase() : "";
  if (!email) throw new AdministratorError("email", "Escolha uma pessoa.");
  if (email === ownerEmail) {
    throw new AdministratorError("owner", "A pessoa titular é sempre administradora.");
  }
  const ref = db.doc(organizationMembershipPath(organizationId, personKey(email)));
  const membership = await ref.get();
  if (!membership.exists) {
    throw new AdministratorError("member", "Essa pessoa não faz parte da organização.");
  }
  const role = admin ? "admin" : "member";
  if (membership.get("role") !== role) await ref.update({ role });
  await addToAccount(centralDb, email, organizationId);
  return { email, role };
}

module.exports = {
  AdministratorError,
  isOwner,
  listAdministrators,
  ownedOrganization,
  setAdministrator,
  splitByRole,
};
