const { GROUP_DOMAIN, isValidPartnerId } = require("./group_address");

/**
 * The partner's administrators are the direct members of its root group
 * `<id>00@` (Google Groups is the only source of administration powers).
 * Its owner, `ownerEmail` in the registry, is who created it: that alone
 * grants nothing here.
 *
 * @param {FirebaseFirestore.Firestore} db - The central Firestore
 * @param {{lookup: (email: string) => Promise<string|null>,
 *   isMember: (name: string, email: string) => Promise<boolean>}} groups
 * @param {unknown} partnerId
 * @param {string} email - The caller's e-mail
 * @returns {Promise<boolean>} Whether `email` administers `partnerId`
 */
async function isPartnerAdmin(db, groups, partnerId, email) {
  if (!isValidPartnerId(partnerId) || !email) return false;
  const registry = await db.doc(`partners/${partnerId}`).get();
  if (!registry.exists || registry.get("status") !== "active") return false;
  const root = await groups.lookup(`${partnerId}00@${GROUP_DOMAIN}`);
  return root !== null && (await groups.isMember(root, email.toLowerCase()));
}

module.exports = { isPartnerAdmin };
