const MIN_NAME = 2;
const MAX_NAME = 40;

/** Public REST URL of the central theme catalog. */
const THEMES_URL =
  "https://firestore.googleapis.com/v1/projects/monamienet-app/databases/(default)/documents/themes?pageSize=100";

/**
 * Error with a code the callable function returns as `invalid-argument`.
 */
class BrandingError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * Validates and normalizes a branding change from the owner.
 *
 * - `name` (optional): trimmed, inner spaces collapsed, 2 to 40 characters,
 *   never starting with "MonAmie " (it would read as MonAmie's own brand).
 * - `themeId` (optional): one of `activeThemeIds`. Organizations pick a theme
 *   from the central catalog, never free colors.
 * - `logo` (optional): "set" after uploading `organizations/{id}/logo.png`,
 *   "removed" after deleting it.
 * At least one of them must be present.
 *
 * @param {object} input - `{name?, themeId?, logo?}`
 * @param {Set<string>} activeThemeIds - Ids of the active themes
 * @returns {{name?: string, themeId?: string, logo?: "set"|"removed"}}
 * @throws {BrandingError}
 */
function validateBranding(input, activeThemeIds) {
  const change = {};
  if (input?.name !== undefined) {
    if (typeof input.name !== "string") {
      throw new BrandingError("name", "O nome precisa ser um texto.");
    }
    const name = input.name.trim().replace(/\s+/g, " ");
    if (name.length < MIN_NAME || name.length > MAX_NAME) {
      throw new BrandingError(
        "name",
        `O nome precisa ter de ${MIN_NAME} a ${MAX_NAME} caracteres.`
      );
    }
    if (/^monamie\s/i.test(name)) {
      throw new BrandingError("name", 'O nome não pode começar com "MonAmie".');
    }
    change.name = name;
  }
  if (input?.themeId !== undefined) {
    if (typeof input.themeId !== "string" || !activeThemeIds.has(input.themeId)) {
      throw new BrandingError("themeId", "Esse tema não existe no catálogo.");
    }
    change.themeId = input.themeId;
  }
  if (input?.logo !== undefined) {
    if (input.logo !== "set" && input.logo !== "removed") {
      throw new BrandingError("logo", 'logo deve ser "set" ou "removed".');
    }
    change.logo = input.logo;
  }
  if (Object.keys(change).length === 0) {
    throw new BrandingError("empty", "Nada para alterar.");
  }
  return change;
}

/**
 * The ids of the active themes in a Firestore REST listing of `themes`.
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

module.exports = {
  BrandingError,
  THEMES_URL,
  activeThemeIdsFrom,
  validateBranding,
};
