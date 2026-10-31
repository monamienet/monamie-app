const { organizationMembership } = require("./membership_store");

/**
 * Administrators are the people whose membership of the organization,
 * `organizations/{id}/organizationMemberships/{personKey}` in its project,
 * has `role: "admin"` (written only by the central functions and
 * `tool/organization.dart add-admin`). The owner, `ownerEmail` in the
 * registry, is always one: creation makes them `admin`, and no function
 * demotes or removes them.
 *
 * @param {(organizationId: unknown) => Promise<{db: FirebaseFirestore.Firestore,
 *   registry: object}|null>} openOrganization - See `organizationOpener`
 * @param {unknown} organizationId
 * @param {string} email - The caller's e-mail
 * @returns {Promise<FirebaseFirestore.Firestore|null>} The organization's
 *   Firestore when `email` administers it and it is `active`, else null
 */
async function administeredOrganization(openOrganization, organizationId, email) {
  if (!email) return null;
  const organization = await openOrganization(organizationId);
  if (!organization || organization.registry?.status !== "active") return null;
  const membership = await organizationMembership(organization.db, organizationId, email);
  return membership?.role === "admin" ? organization.db : null;
}

module.exports = { administeredOrganization };
