const { parseGroupAddress } = require("./group_address");

/**
 * The organization a MonAmie group points to, or null.
 *
 * Any level counts: the root `<id>00`, a team `<id>NN` and its leaves
 * `<id>NNr` / `<id>NNw`. The group name only says where to go; it grants
 * nothing. What the person may do there is decided by the organization's
 * syncClaims, which ignores direct members of a team group. Counting team
 * groups here keeps organizations made before the three-level model (people
 * directly in `<id>NN`) reachable until they are migrated.
 *
 * @param {unknown} email - Group email
 * @returns {string|null} Organization id
 */
function organizationIdFromGroupEmail(email) {
  return parseGroupAddress(email)?.organizationId ?? null;
}

/**
 * The distinct organization ids of a user's groups, sorted.
 *
 * @param {Array<{email?: unknown}>} groups - Groups from the gateway
 * @returns {string[]} Organization ids
 */
function organizationIdsFromGroups(groups) {
  const ids = new Set();
  for (const group of groups ?? []) {
    const id = organizationIdFromGroupEmail(group?.email);
    if (id) ids.add(id);
  }
  return [...ids].sort();
}

module.exports = { organizationIdFromGroupEmail, organizationIdsFromGroups };
