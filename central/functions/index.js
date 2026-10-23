const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { GoogleAuth } = require("google-auth-library");
const { partnerIdsFromGroups } = require("./partner_groups");
const { PartnerOptionsReader } = require("./partner_options");
const { TtlCache } = require("./ttl_cache");

admin.initializeApp();

// Host of the workspace-groups-gateway, shared with the partner projects.
const GATEWAY_HOST = defineString("GROUPS_GATEWAY_HOST");

const PLATFORMS = new Set(["android", "web"]);
const GATEWAY_TIMEOUT_MS = 10000;

const auth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/firebase.readonly"],
});
const options = new PartnerOptionsReader(async (url) => {
  const client = await auth.getClient();
  const response = await client.request({ url });
  return response.data;
});
// A user who signs in twice in a row reuses their groups: every gateway
// call spends the Directory API quota shared by all partners.
const groupsByEmail = new TtlCache(10 * 60 * 1000);

/**
 * Finds the partners the signed-in user belongs to.
 *
 * The user signed in to this central project with Google. Their partners
 * are derived from the names of their groups (`<id>NN@monamienet.org`),
 * kept only when active in the registry (`partners/{id}.active`), and
 * returned with the FirebaseOptions of each partner project for the
 * caller's platform. The partner's own syncClaims still decides what the
 * user may access there.
 *
 * Request: `{platform: "android" | "web"}`.
 * Response: `{partners: [{id, options}]}`, sorted by id.
 */
exports.resolvePartners = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const { email, email_verified: emailVerified } = request.auth.token;
  if (!email || emailVerified !== true) {
    throw new HttpsError("failed-precondition", "A verified email is required.");
  }
  const platform = request.data?.platform;
  if (!PLATFORMS.has(platform)) {
    throw new HttpsError("invalid-argument", "platform must be android or web.");
  }

  const groups = await groupsByEmail.getOrCompute(email.toLowerCase(), () =>
    fetchUserGroups(bearerToken(request), email)
  );
  const ids = await activePartnerIds(partnerIdsFromGroups(groups));

  const partners = [];
  for (const id of ids) {
    try {
      partners.push({ id, options: await options.get(id, platform) });
    } catch (error) {
      // One misconfigured partner must not block the user's other partners.
      logger.error(`[resolvePartners] Skipping ${id}: ${error.message}`);
    }
  }
  return { partners };
});

/**
 * The raw Firebase ID token of the caller, forwarded to the gateway like
 * syncClaims does.
 */
function bearerToken(request) {
  const header = request.rawRequest?.headers?.authorization ?? "";
  const match = /^Bearer (.+)$/.exec(header);
  if (!match) throw new HttpsError("unauthenticated", "Missing ID token.");
  return match[1];
}

async function fetchUserGroups(idToken, email) {
  const url = `https://${GATEWAY_HOST.value()}/groups?email=${encodeURIComponent(
    email
  )}`;
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
    signal: AbortSignal.timeout(GATEWAY_TIMEOUT_MS),
  });
  if (!response.ok) {
    logger.error(`[resolvePartners] Gateway answered ${response.status}.`);
    throw new HttpsError("unavailable", "Could not read your groups.");
  }
  const body = await response.json();
  return Array.isArray(body?.groups) ? body.groups : [];
}

async function activePartnerIds(ids) {
  if (ids.length === 0) return [];
  const db = admin.firestore();
  const docs = await db.getAll(...ids.map((id) => db.doc(`partners/${id}`)));
  return docs.filter((doc) => doc.get("active") === true).map((doc) => doc.id);
}
