const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { GoogleAuth } = require("google-auth-library");
const { partnerIdsFromGroups } = require("./partner_groups");
const {
  COMMUNITY_PROJECT_ID,
  PartnerOptionsReader,
} = require("./partner_options");
const { TtlCache } = require("./ttl_cache");
const { GROUPS_SCOPES, GroupsApi } = require("./groups_api");
const { TeamError } = require("./teams");
const {
  createTeam,
  deleteTeam,
  deletionImpact,
  listTeams,
  removePerson,
  renameTeam,
  setRoles,
} = require("./team_service");
const {
  BINDABLE,
  VISIBLE,
  duePartnerIds,
  retirePartner,
} = require("./partner_status");

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
// Absorbs retry storms (a user tapping sign-in again) without spending the
// Directory API quota shared by all partners. Kept short (#78): a removal
// must not keep routing someone to a partner for long. Each instance has
// its own cache, so a removed user may still be listed for up to a minute;
// the partner's syncClaims then grants nothing and the app shows
// *Sem organização*.
const groupsByEmail = new TtlCache(60 * 1000);

/**
 * Finds the partners the signed-in user belongs to.
 *
 * The user signed in to this central project with Google. Their partners
 * are derived from the names of their groups (`<id>00@`, `<id>NNr@`,
 * `<id>NNw@`; see group_address.js),
 * kept when their registry entry `partners/{id}` has a status the app shows
 * (every status but `reserved`), and returned with that status. Partners
 * the app binds (`active`, `migrating`, `deleting`) also carry the
 * FirebaseOptions of their project for the caller's platform. The partner's
 * own syncClaims still decides what the user may access there.
 *
 * Request: `{platform: "android" | "web"}`.
 * Response: `{partners: [{id, status, options?}]}`, sorted by id.
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
  const entries = await visiblePartners(partnerIdsFromGroups(groups));

  const partners = [];
  for (const { id, status, plan } of entries) {
    if (!BINDABLE.includes(status)) {
      partners.push({ id, status });
      continue;
    }
    try {
      partners.push({
        id,
        status,
        options: await options.get(id, platform, plan),
      });
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

async function visiblePartners(ids) {
  if (ids.length === 0) return [];
  const db = admin.firestore();
  const docs = await db.getAll(...ids.map((id) => db.doc(`partners/${id}`)));
  return docs
    .filter((doc) => VISIBLE.includes(doc.get("status")))
    .map((doc) => ({
      id: doc.id,
      status: doc.get("status"),
      plan: doc.get("plan"),
    }));
}

// Runs as its own service account: it is the only identity allowed to
// delete partner projects (roles/resourcemanager.projectDeleter on each).
const EXPIRER_SERVICE_ACCOUNT =
  "partner-expirer@monamienet-app.iam.gserviceaccount.com";

const cloudPlatform = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

/**
 * Retires partners whose timed exit is due: 7 days in `awaiting_billing`
 * (billing never linked) or 30 days in `deleting` (the grace period ended).
 * Each one loses its project and its registry entry, and its id is retired.
 */
exports.expirePartners = onSchedule(
  {
    schedule: "every day 03:00",
    timeZone: "America/Sao_Paulo",
    serviceAccount: EXPIRER_SERVICE_ACCOUNT,
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const snapshot = await db
      .collection("partners")
      .where("deleteAt", "<=", now)
      .get();
    const docs = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    for (const id of duePartnerIds(docs, now)) {
      try {
        await retirePartner(db, id, erasePartnerData, { now });
        logger.info(`[expirePartners] Retired ${id}.`);
      } catch (error) {
        // The next run retries; one partner must not block the others.
        logger.error(`[expirePartners] Could not retire ${id}: ${error.message}`);
      }
    }
  }
);

/**
 * Erases partner `id`'s data: its whole project on the Standard plan, or
 * its subtree `partners/{id}/**` in the shared Community project.
 */
async function erasePartnerData(id, registry) {
  if (registry?.plan === "community") {
    const community = communityFirestore();
    await community.recursiveDelete(community.doc(`partners/${id}`));
    return;
  }
  await deletePartnerProject(id);
}

/**
 * Firestore of the shared Community project, through a second Admin app.
 * The function's service account needs roles/datastore.user there.
 */
function communityFirestore() {
  const name = "community";
  const app =
    admin.apps.find((a) => a?.name === name) ??
    admin.initializeApp({ projectId: COMMUNITY_PROJECT_ID }, name);
  return app.firestore();
}

/**
 * Deletes partner `id`'s Google Cloud project. Google keeps it restorable
 * for up to 30 days, then erases it with all its data; its id can never be
 * used again. A project already waiting for deletion counts as deleted.
 */
async function deletePartnerProject(id) {
  const url = `https://cloudresourcemanager.googleapis.com/v3/projects/monamienet-${id}`;
  const client = await cloudPlatform.getClient();
  try {
    await client.request({ url, method: "DELETE" });
  } catch (error) {
    const project = await client
      .request({ url })
      .then((response) => response.data)
      .catch(() => null);
    if (project?.state !== "DELETE_REQUESTED") throw error;
  }
}

// ── Teams (#98) ────────────────────────────────────────────────────────────
// Run as groups-admin@, which holds the Workspace "Groups Administrator"
// admin role. Every call checks that the caller is the partner's owner
// (`ownerEmail` in partners/{id}) and only touches that partner's groups.
const GROUPS_ADMIN_SERVICE_ACCOUNT =
  "groups-admin@monamienet-app.iam.gserviceaccount.com";

const groupsAuth = new GoogleAuth({ scopes: GROUPS_SCOPES });
const groupsApi = new GroupsApi(async (options) => {
  const client = await groupsAuth.getClient();
  return (await client.request(options)).data;
});

/**
 * The partner id of a team call, once the caller is known to own it.
 *
 * @throws {HttpsError} unauthenticated / permission-denied
 */
async function ownedPartnerId(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const partnerId = request.data?.partnerId;
  const email = String(request.auth.token.email ?? "").toLowerCase();
  if (typeof partnerId !== "string" || !email) {
    throw new HttpsError("invalid-argument", "partnerId is required.");
  }
  const registry = await admin.firestore().doc(`partners/${partnerId}`).get();
  const owner = String(registry.get("ownerEmail") ?? "").toLowerCase();
  if (!registry.exists || registry.get("status") !== "active" || owner !== email) {
    throw new HttpsError("permission-denied", "Só o responsável gerencia equipes.");
  }
  return partnerId;
}

/** Wraps a team operation: owner check, then TeamError → invalid-argument. */
function teamCall(operation) {
  return onCall(
    { invoker: "public", serviceAccount: GROUPS_ADMIN_SERVICE_ACCOUNT },
    async (request) => {
      const partnerId = await ownedPartnerId(request);
      try {
        return await operation(partnerId, request.data ?? {});
      } catch (error) {
        if (error instanceof TeamError) {
          throw new HttpsError(
            error.code === "full" ? "failed-precondition" : "invalid-argument",
            error.message,
            { field: error.code }
          );
        }
        logger.error(`[teams] ${partnerId}: ${error.message}`);
        throw new HttpsError("unavailable", "Não foi possível falar com os grupos agora.");
      }
    }
  );
}

exports.listTeams = teamCall(async (partnerId) => ({
  teams: await listTeams(groupsApi, partnerId),
}));

exports.createTeam = teamCall((partnerId, data) =>
  createTeam(groupsApi, partnerId, data.name)
);

exports.renameTeam = teamCall((partnerId, data) =>
  renameTeam(groupsApi, partnerId, String(data.team ?? ""), data.name)
);

exports.teamDeletionImpact = teamCall((partnerId, data) =>
  deletionImpact(groupsApi, partnerId, String(data.team ?? ""))
);

exports.deleteTeam = teamCall(async (partnerId, data) => {
  await deleteTeam(groupsApi, partnerId, String(data.team ?? ""));
  return { deleted: true };
});

exports.setMemberRoles = teamCall((partnerId, data) =>
  setRoles(groupsApi, partnerId, String(data.team ?? ""), String(data.email ?? ""), data.roles)
);

exports.removeMember = teamCall(async (partnerId, data) => {
  await removePerson(groupsApi, partnerId, String(data.team ?? ""), String(data.email ?? ""));
  return { removed: true };
});

