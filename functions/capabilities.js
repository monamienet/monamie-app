const { parseGroupAddress } = require("./group_address");

/**
 * What a person may do in the partners hosted by this project, from their
 * **direct** groups (the gateway's `/groups?email=`):
 *
 * - `<id>NNw` gives `share` in team `<id>NN` (they share their location);
 * - `<id>NNr` gives `watch` in team `<id>NN` (they see the team's map);
 * - `<id>00` makes them the owner of `<id>`, who watches every team.
 *
 * A direct member of a team group `<id>NN` (someone added by hand in the
 * Admin console) gets nothing: configuration errors are ignored, not
 * trusted, and returned in `ignored` for the log.
 *
 * The result is the custom claims: three short lists, so the rules can test
 * them with `hasAny` and they stay well under the 1000-byte limit.
 *
 * @param {Array<{email?: unknown}>} groups - The person's direct groups
 * @param {(partnerId: string) => boolean} isHostedHere - Whether a partner's
 *   data lives in this project; other partners' groups are left out
 * @returns {{share: string[], watch: string[], owns: string[],
 *   partners: string[], ignored: string[]}} Sorted, without duplicates.
 *   `partners` lists every partner where the person has any capability, so
 *   the rules can tell members of one partner from another's in a project
 *   that hosts several (Community).
 */
function capabilitiesFromGroups(groups, isHostedHere) {
  const share = new Set();
  const watch = new Set();
  const owns = new Set();
  const partners = new Set();
  const ignored = new Set();
  for (const group of groups ?? []) {
    const address = parseGroupAddress(group?.email);
    if (!address || !isHostedHere(address.partnerId)) continue;
    if (address.level === 1) {
      ignored.add(String(group.email).trim().toLowerCase());
      continue;
    }
    if (address.level === 0) owns.add(address.partnerId);
    else if (address.leaf === "w") share.add(address.teamKey);
    else watch.add(address.teamKey);
    partners.add(address.partnerId);
  }
  const sorted = (set) => [...set].sort();
  return {
    share: sorted(share),
    watch: sorted(watch),
    owns: sorted(owns),
    partners: sorted(partners),
    ignored: sorted(ignored),
  };
}

/**
 * Whether the capabilities give no access at all: the person was removed
 * from every group of the partner (or never had one).
 *
 * @param {{share: string[], watch: string[], owns: string[]}} caps
 * @returns {boolean}
 */
function hasNoAccess(caps) {
  return caps.share.length + caps.watch.length + caps.owns.length === 0;
}

module.exports = { capabilitiesFromGroups, hasNoAccess };
