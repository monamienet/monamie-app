/** Public REST URL of the theme catalog (this project's `themes`). */
const THEMES_URL =
  "https://firestore.googleapis.com/v1/projects/monamienet-app/databases/(default)/documents/themes?pageSize=100";

/**
 * The ids of the active themes in a Firestore REST listing of `themes`.
 * Twin of `activeThemeIdsFrom` in functions/branding.js.
 *
 * @param {object} listing - Response of a `themes` collection GET
 * @returns {Set<string>}
 */
function activeThemeIdsFrom(listing) {
  const ids = new Set();
  for (const doc of listing?.documents ?? []) {
    const id = String(doc.name ?? "").split("/").pop();
    const active = doc.fields?.active?.booleanValue;
    if (id && active !== false) ids.add(id);
  }
  return ids;
}

module.exports = { THEMES_URL, activeThemeIdsFrom };
