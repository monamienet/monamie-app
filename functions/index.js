const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { FieldValue } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {
  BrandingError,
  THEMES_URL,
  activeThemeIdsFrom,
  isOrganizationId,
  validateBranding,
} = require("./branding");
const { personKey } = require("./person_key");
const { brandingPath, organizationMembershipPath } = require("./firestore_paths");
admin.initializeApp();

const THEMES_TIMEOUT_MS = 10000;

/**
 * Changes the bound organization's name, theme or logo flag. Administrators
 * only: the caller's `organizations/{id}/organizationMemberships/{personKey}`
 * in this project has `role: "admin"`.
 *
 * The organization project's rules cannot read the central theme catalog, so
 * the theme is checked here, against the active themes (public REST read).
 * The logo itself is uploaded by an administrator's app to
 * `organizations/{id}/logo.png` (storage.rules); `logo: "set"` then bumps
 * `logoVersion` so every device fetches the new file, and `"removed"`
 * drops it.
 *
 * Request: `{organizationId, name?, themeId?, logo?: "set" | "removed"}`.
 * Response: the fields written.
 */
exports.setBranding = onCall({ invoker: "public", region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Autenticação necessária.");
  }
  const organizationId = request.data?.organizationId;
  if (!(await isAdmin(organizationId, request.auth.token))) {
    throw new HttpsError("permission-denied", "Só um administrador muda a aparência.");
  }
  let change;
  try {
    const needsThemes = request.data?.themeId !== undefined;
    const themes = needsThemes ? await fetchActiveThemeIds() : new Set();
    change = validateBranding(request.data, themes);
  } catch (error) {
    if (error instanceof BrandingError) {
      throw new HttpsError("invalid-argument", error.message, { field: error.code });
    }
    throw error;
  }
  const { logo, ...fields } = change;
  const data = { ...fields, updatedAt: new Date() };
  if (logo === "set") data.logoVersion = Date.now();
  if (logo === "removed") data.logoVersion = FieldValue.delete();
  await admin
    .firestore()
    .doc(brandingPath(organizationId))
    .set(data, { merge: true });
  return { ...fields, ...(logo ? { logo } : {}) };
});

/**
 * Whether the caller (a verified e-mail) administers `organizationId` here.
 *
 * @param {unknown} organizationId
 * @param {{email?: string, email_verified?: boolean}} token
 * @returns {Promise<boolean>}
 */
async function isAdmin(organizationId, token) {
  if (!isOrganizationId(organizationId) || !token.email || token.email_verified !== true) {
    return false;
  }
  const membership = await admin
    .firestore()
    .doc(organizationMembershipPath(organizationId, personKey(token.email)))
    .get();
  return membership.get("role") === "admin";
}

async function fetchActiveThemeIds() {
  const response = await fetch(THEMES_URL, { signal: AbortSignal.timeout(THEMES_TIMEOUT_MS) });
  if (!response.ok) {
    logger.error(`[setBranding] Theme catalog answered ${response.status}.`);
    throw new HttpsError("unavailable", "Não foi possível ler os temas.");
  }
  return activeThemeIdsFrom(await response.json());
}
