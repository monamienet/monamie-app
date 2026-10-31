const { parseGroupAddress } = require("./group_address");

/**
 * What a person may do in the organizations hosted by this project, from their
 * **direct** groups (the gateway's `/groups?email=`):
 *
 * - `<id>NNw` gives `share` in team `<id>NN` (they share their location);
 * - `<id>NNr` gives `watch` in team `<id>NN` (they see the team's map);
 * - `<id>00` makes them an administrator of `<id>`, who watches every team
 *   and manages the organization (a root group may have several).
 *
 * A direct member of a team group `<id>NN` (someone added by hand in the
 * Admin console) gets nothing: configuration errors are ignored, not
 * trusted, and returned in `ignored` for the log.
 *
 * The result is the custom claims: three short lists, so the rules can test
 * them with `hasAny` and they stay well under the 1000-byte limit.
 *
 * @param {Array<{email?: unknown}>} groups - The person's direct groups
 * @param {(organizationId: string) => boolean} isHostedHere - Whether an organization's
 *   data lives in this project; other organizations' groups are left out
 * @returns {{share: string[], watch: string[], admin: string[],
 *   organizations: string[], ignored: string[]}} Sorted, without duplicates.
 *   `organizations` lists every organization where the person has any capability, so
 *   the rules can tell members of one organization from another's in a project
 *   that hosts several (Community).
 */
function capabilitiesFromGroups(groups, isHostedHere) {
  const share = new Set();
  const watch = new Set();
  const admin = new Set();
  const organizations = new Set();
  const ignored = new Set();
  for (const group of groups ?? []) {
    const address = parseGroupAddress(group?.email);
    if (!address || !isHostedHere(address.organizationId)) continue;
    if (address.level === 1) {
      ignored.add(String(group.email).trim().toLowerCase());
      continue;
    }
    if (address.level === 0) admin.add(address.organizationId);
    else if (address.leaf === "w") share.add(address.teamKey);
    else watch.add(address.teamKey);
    organizations.add(address.organizationId);
  }
  const sorted = (set) => [...set].sort();
  return {
    share: sorted(share),
    watch: sorted(watch),
    admin: sorted(admin),
    organizations: sorted(organizations),
    ignored: sorted(ignored),
  };
}

/**
 * Whether the capabilities give no access at all: the person was removed
 * from every group of the organization (or never had one).
 *
 * @param {{share: string[], watch: string[], admin: string[]}} caps
 * @returns {boolean}
 */
function hasNoAccess(caps) {
  return caps.share.length + caps.watch.length + caps.admin.length === 0;
}

module.exports = { capabilitiesFromGroups, hasNoAccess };
