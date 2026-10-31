const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue } = require("firebase-admin/firestore");
const { defineString, projectID } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {
  BrandingError,
  THEMES_URL,
  activeThemeIdsFrom,
  validateBranding,
} = require("./branding");
const { capabilitiesFromGroups } = require("./capabilities");
const { parseGroupAddress } = require("./group_address");
const { COMMUNITY_PROJECT_ID, organizationIdForProject } = require("./root_group");
const { brandingPath } = require("./firestore_paths");
admin.initializeApp();

// Host of the workspace-groups-gateway, shared by every organization (functions/.env).
const BACKEND_HOST = defineString("GROUPS_GATEWAY_HOST");

const GATEWAY_TIMEOUT_MS = 10000;

/**
 * Sets the caller's custom claims from their Google Groups membership.
 *
 * What a person may do comes from *which* groups they are in (everyone is
 * a plain MEMBER): `<id>NNw` shares in team `<id>NN`, `<id>NNr` watches it,
 * and `<id>00` (an administrator) watches every team and manages the organization. Only the person's direct
 * groups are needed: one gateway call, no walk of the group tree.
 *
 * Claims: `{share: [teamKey], watch: [teamKey], admin: [organizationId],
 * organizations: [organizationId]}`, where a team key is the team group's local part
 * (`rotasul01`) and `organizations` lists the organizations where the person has any
 * capability. Only the organizations hosted by this project are kept: the one
 * named by a Standard project's id, or, in the shared Community project,
 * every organization whose `organizations/{id}/config/branding` exists here.
 *
 * Request: `{idToken}` (forwarded to the gateway).
 * Response: the claims set.
 */
// The region is explicit so deploys never have to guess it, and must match the
// app's FirebaseFunctions instance (default region, us-central1).
exports.syncClaims = onCall({ invoker: "public", region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Autenticação necessária.");
  }
  const { uid } = request.auth;
  const email = request.auth.token.email;
  if (!email) {
    throw new HttpsError("failed-precondition", "Email não disponível no token.");
  }
  // The raw ID token goes to the gateway, which expects a Bearer token.
  const idToken = request.data?.idToken;
  if (!idToken) {
    throw new HttpsError("invalid-argument", "idToken é obrigatório.");
  }

  const groups = await fetchUserGroups(idToken, email);
  const hosted = await hostedOrganizations(projectID.value(), groups);
  const { ignored, ...claims } = capabilitiesFromGroups(groups, (organizationId) =>
    hosted.has(organizationId)
  );
  if (ignored.length > 0) {
    logger.warn(
      `[syncClaims] ${email} is a direct member of team groups, which grant ` +
        `nothing: ${ignored.join(", ")}`
    );
  }
  await getAuth().setCustomUserClaims(uid, claims);
  return claims;
});

/**
 * The organizations of `groups` whose data lives in this project.
 *
 * @param {string} projectId - This Firebase project
 * @param {Array<{email?: unknown}>} groups - The person's groups
 * @returns {Promise<Set<string>>}
 */
async function hostedOrganizations(projectId, groups) {
  if (projectId !== COMMUNITY_PROJECT_ID) {
    return new Set([organizationIdForProject(projectId)]);
  }
  const ids = new Set();
  for (const group of groups) {
    const address = parseGroupAddress(group?.email);
    if (address) ids.add(address.organizationId);
  }
  const db = admin.firestore();
  const refs = [...ids].map((id) => db.doc(brandingPath(id)));
  if (refs.length === 0) return new Set();
  const docs = await db.getAll(...refs);
  return new Set(docs.filter((doc) => doc.exists).map((doc) => doc.ref.parent.parent.id));
}

/**
 * The person's direct groups from the gateway's `/groups?email=`.
 *
 * @param {string} idToken - Firebase ID token of the caller
 * @param {string} email - The caller's e-mail
 * @returns {Promise<Array<{email: string}>>}
 */
async function fetchUserGroups(idToken, email) {
  const url = `https://${BACKEND_HOST.value()}/groups?email=${encodeURIComponent(
    email
  )}`;
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
    signal: AbortSignal.timeout(GATEWAY_TIMEOUT_MS),
  });
  if (!response.ok) {
    logger.error(`[syncClaims] Gateway answered ${response.status}.`);
    throw new HttpsError("unavailable", "Não foi possível ler seus grupos.");
  }
  const body = await response.json();
  return Array.isArray(body?.groups) ? body.groups : [];
}

/**
 * Changes the bound organization's name, theme or logo flag. Owner only.
 *
 * The organization project's rules cannot read the central theme catalog, so
 * the theme is checked here, against the active themes (public REST read).
 * The logo itself is uploaded by the owner's app to
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
  const admins = request.auth.token.admin;
  if (typeof organizationId !== "string" || !Array.isArray(admins) || !admins.includes(organizationId)) {
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

async function fetchActiveThemeIds() {
  const response = await fetch(THEMES_URL, { signal: AbortSignal.timeout(GATEWAY_TIMEOUT_MS) });
  if (!response.ok) {
    logger.error(`[setBranding] Theme catalog answered ${response.status}.`);
    throw new HttpsError("unavailable", "Não foi possível ler os temas.");
  }
  return activeThemeIdsFrom(await response.json());
}
