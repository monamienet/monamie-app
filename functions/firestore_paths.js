/**
 * The Firestore collection and document names the organization functions
 * use, in one place, so a rename cannot miss one. The app (`FirestorePaths`
 * in lib/app/data/firebase/firestore_paths.dart), the central functions
 * (central/functions/firestore_paths.js) and the rules use the same names.
 */

/** Root of every organization's data in its project. */
const ORGANIZATIONS = "organizations";

/** `organizations/{id}/config/branding`: the organization's name and look. */
function brandingPath(organizationId) {
  return `${ORGANIZATIONS}/${organizationId}/config/branding`;
}

module.exports = { ORGANIZATIONS, brandingPath };
