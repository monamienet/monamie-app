const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { defineString, projectID } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { capabilitiesFromGroups } = require("./capabilities");
const { parseGroupAddress } = require("./group_address");
const { COMMUNITY_PROJECT_ID, partnerIdForProject } = require("./root_group");
admin.initializeApp();

// Host of the workspace-groups-gateway, shared by every partner (functions/.env).
const BACKEND_HOST = defineString("GROUPS_GATEWAY_HOST");

const GATEWAY_TIMEOUT_MS = 10000;

/**
 * Sets the caller's custom claims from their Google Groups membership.
 *
 * What a person may do comes from *which* groups they are in (everyone is
 * a plain MEMBER): `<id>NNw` shares in team `<id>NN`, `<id>NNr` watches it,
 * and `<id>00` (the owner) watches every team. Only the person's direct
 * groups are needed: one gateway call, no walk of the group tree.
 *
 * Claims: `{share: [teamKey], watch: [teamKey], owns: [partnerId],
 * partners: [partnerId]}`, where a team key is the team group's local part
 * (`rotasul01`) and `partners` lists the partners where the person has any
 * capability. Only the partners hosted by this project are kept: the one
 * named by a Standard project's id, or, in the shared Community project,
 * every partner whose `partners/{id}/config/branding` exists here.
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
  const hosted = await hostedPartners(projectID.value(), groups);
  const { ignored, ...claims } = capabilitiesFromGroups(groups, (partnerId) =>
    hosted.has(partnerId)
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
 * The partners of `groups` whose data lives in this project.
 *
 * @param {string} projectId - This Firebase project
 * @param {Array<{email?: unknown}>} groups - The person's groups
 * @returns {Promise<Set<string>>}
 */
async function hostedPartners(projectId, groups) {
  if (projectId !== COMMUNITY_PROJECT_ID) {
    return new Set([partnerIdForProject(projectId)]);
  }
  const ids = new Set();
  for (const group of groups) {
    const address = parseGroupAddress(group?.email);
    if (address) ids.add(address.partnerId);
  }
  const db = admin.firestore();
  const refs = [...ids].map((id) => db.doc(`partners/${id}/config/branding`));
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
