const { parseGroupAddress } = require("./group_address");

/**
 * The partner a MonAmie group points to, or null.
 *
 * Any level counts: the root `<id>00`, a team `<id>NN` and its leaves
 * `<id>NNr` / `<id>NNw`. The group name only says where to go; it grants
 * nothing. What the person may do there is decided by the partner's
 * syncClaims, which ignores direct members of a team group. Counting team
 * groups here keeps partners made before the three-level model (people
 * directly in `<id>NN`) reachable until they are migrated.
 *
 * @param {unknown} email - Group email
 * @returns {string|null} Partner id
 */
function partnerIdFromGroupEmail(email) {
  return parseGroupAddress(email)?.partnerId ?? null;
}

/**
 * The distinct partner ids of a user's groups, sorted.
 *
 * @param {Array<{email?: unknown}>} groups - Groups from the gateway
 * @returns {string[]} Partner ids
 */
function partnerIdsFromGroups(groups) {
  const ids = new Set();
  for (const group of groups ?? []) {
    const id = partnerIdFromGroupEmail(group?.email);
    if (id) ids.add(id);
  }
  return [...ids].sort();
}

module.exports = { partnerIdFromGroupEmail, partnerIdsFromGroups };
