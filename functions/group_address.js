const GROUP_DOMAIN = "monamienet.org";

// <organization id><two-digit team><optional leaf>: rotasul00, rotasul01, rotasul01r, rotasul01w.
const LOCAL_PART = /^([a-z]+)(\d{2})([rw])?$/;

// Ids that can never be an organization: `app` is the central project and
// `community` the shared Community project. Twin of `reservedOrganizationIds` in
// tool/src/organizations.dart and lib/app/config/organization/organization_config.dart.
const RESERVED_ORGANIZATION_IDS = new Set(["app", "community"]);

const MIN_ORGANIZATION_ID_LENGTH = 3;

/**
 * Whether `id` can be an organization id: lowercase letters only, at least three,
 * and not reserved. Letters only is what lets the team number be parsed
 * from a group address.
 *
 * @param {unknown} id
 * @returns {boolean}
 */
function isValidOrganizationId(id) {
  return (
    typeof id === "string" &&
    /^[a-z]+$/.test(id) &&
    id.length >= MIN_ORGANIZATION_ID_LENGTH &&
    !RESERVED_ORGANIZATION_IDS.has(id)
  );
}

/**
 * Parses a MonAmie group address into its three levels:
 *
 * - `<id>00@` — the root group, its administrators: `{level: 0}`;
 * - `<id>NN@` (01–99) — a team, no direct members: `{level: 1}`;
 * - `<id>NNr@` / `<id>NNw@` — the team's watch / share leaf: `{level: 2}`.
 *
 * Returns null for anything else, including `<id>00r`, `<id>00w` and other
 * domains. Twin of `parseGroupAddress` in central/functions/group_address.js
 * and lib/app/config/organization/group_address.dart.
 *
 * @param {unknown} email - Group e-mail
 * @returns {{organizationId: string, team: string, teamKey: string,
 *   leaf: "r"|"w"|null, level: 0|1|2}|null}
 */
function parseGroupAddress(email) {
  if (typeof email !== "string") return null;
  const normalized = email.trim().toLowerCase();
  const at = normalized.lastIndexOf("@");
  if (at < 0 || normalized.slice(at + 1) !== GROUP_DOMAIN) return null;
  const match = LOCAL_PART.exec(normalized.slice(0, at));
  if (!match) return null;
  const [, organizationId, team, leaf = null] = match;
  if (!isValidOrganizationId(organizationId)) return null;
  const level = team === "00" ? 0 : leaf ? 2 : 1;
  if (team === "00" && leaf) return null;
  return { organizationId, team, teamKey: `${organizationId}${team}`, leaf, level };
}

module.exports = {
  GROUP_DOMAIN,
  RESERVED_ORGANIZATION_IDS,
  isValidOrganizationId,
  parseGroupAddress,
};
