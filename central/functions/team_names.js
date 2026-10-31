const { GROUP_DOMAIN, parseGroupAddress } = require("./group_address");

/**
 * The teams of `organizationId` whose names the caller may read, from their
 * **direct** groups (the gateway's `/groups?email=`), by the same rule as
 * the organization's syncClaims: a root-group member (`<id>00`) sees every team
 * (`all`), anyone else the teams of their leaves `<id>NNr` / `<id>NNw`.
 * A direct member of a team group `<id>NN` gets nothing.
 *
 * @param {string} organizationId
 * @param {Array<{email?: unknown}>} groups - The caller's direct groups
 * @returns {{all: boolean, keys: string[]}} Team keys, sorted, distinct
 */
function visibleTeams(organizationId, groups) {
  let all = false;
  const keys = new Set();
  for (const group of groups ?? []) {
    const address = parseGroupAddress(group?.email);
    if (!address || address.organizationId !== organizationId) continue;
    if (address.level === 0) all = true;
    else if (address.level === 2) keys.add(address.teamKey);
  }
  return { all, keys: [...keys].sort() };
}

/**
 * The display names of the teams the caller may see, read from each team
 * group `<id>NN@` in Cloud Identity (the leaves' names go stale after a
 * rename, and the gateway's member resources carry no name). A team whose
 * group is missing or has no display name is left out; the app then shows
 * "Equipe NN".
 *
 * @param {import("./groups_api").GroupsApi} api
 * @param {string} organizationId
 * @param {Array<{email?: unknown}>} groups - The caller's direct groups
 * @returns {Promise<Object<string, string>>} Display name by team key
 */
async function teamNames(api, organizationId, groups) {
  const { all, keys } = visibleTeams(organizationId, groups);
  const teamKeys = new Set(keys);
  if (all) {
    const root = await api.lookup(`${organizationId}00@${GROUP_DOMAIN}`);
    for (const member of root ? await api.members(root) : []) {
      const address = parseGroupAddress(member.email);
      if (member.type !== "GROUP" || !address) continue;
      if (address.organizationId === organizationId && address.level === 1) {
        teamKeys.add(address.teamKey);
      }
    }
  }
  const names = {};
  for (const key of [...teamKeys].sort()) {
    const name = await api.lookup(`${key}@${GROUP_DOMAIN}`);
    const group = name ? await api.get(name) : null;
    const displayName =
      typeof group?.displayName === "string" ? group.displayName.trim() : "";
    if (displayName) names[key] = displayName;
  }
  return names;
}

module.exports = { teamNames, visibleTeams };
