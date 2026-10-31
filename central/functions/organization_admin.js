const { GROUP_DOMAIN, isValidOrganizationId } = require("./group_address");
const { organizationPath } = require("./firestore_paths");

/**
 * The organization's administrators are the direct members of its root group
 * `<id>00@` (Google Groups is the only source of administration powers).
 * Its owner, `ownerEmail` in the registry, is who created it: that alone
 * grants nothing here.
 *
 * @param {FirebaseFirestore.Firestore} db - The central Firestore
 * @param {{lookup: (email: string) => Promise<string|null>,
 *   isMember: (name: string, email: string) => Promise<boolean>}} groups
 * @param {unknown} organizationId
 * @param {string} email - The caller's e-mail
 * @returns {Promise<boolean>} Whether `email` administers `organizationId`
 */
async function isOrganizationAdmin(db, groups, organizationId, email) {
  if (!isValidOrganizationId(organizationId) || !email) return false;
  const registry = await db.doc(organizationPath(organizationId)).get();
  if (!registry.exists || registry.get("status") !== "active") return false;
  const root = await groups.lookup(`${organizationId}00@${GROUP_DOMAIN}`);
  return root !== null && (await groups.isMember(root, email.toLowerCase()));
}

module.exports = { isOrganizationAdmin };
