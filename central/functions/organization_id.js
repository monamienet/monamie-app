// Ids that can never be an organization: `app` is the central project and
// `community` the shared Community project. Twin of `reservedOrganizationIds`
// in tool/src/organizations.dart and the app.
const RESERVED_ORGANIZATION_IDS = new Set(["app", "community"]);

const MIN_ORGANIZATION_ID_LENGTH = 3;

/**
 * Whether `id` can be an organization id: lowercase letters only, at least
 * three, and not reserved. The id names the organization's project
 * (`monamienet-<id>` on the Standard plan).
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

module.exports = { RESERVED_ORGANIZATION_IDS, isValidOrganizationId };
