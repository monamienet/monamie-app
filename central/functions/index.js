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
  projectIdFor,
} = require("./partner_options");
const { TtlCache } = require("./ttl_cache");
const { GROUPS_SCOPES, GroupsApi } = require("./groups_api");
const { TeamError } = require("./teams");
const { InviteError } = require("./invites");
const { GmailMailer } = require("./mailer");
const {
  acceptInvite,
  cancelInvite,
  listInvites,
  myInvites,
  resendInvite,
  sendInvites,
} = require("./invite_service");
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

  // `fresh` skips the cache right after accepting an invite, when the new
  // membership must show at once.
  const key = email.toLowerCase();
  if (request.data?.fresh === true) groupsByEmail.delete(key);
  const groups = await groupsByEmail.getOrCompute(key, () =>
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
        return await operation(partnerId, request.data ?? {}, request);
      } catch (error) {
        if (error instanceof TeamError || error instanceof InviteError) {
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

// ── Invites (#99) ──────────────────────────────────────────────────────────
// The sender mailbox, its send-as alias and the name shown are
// configuration (functions/.env or params), never hard-coded in the flow.
const MAIL_SENDER_SUBJECT = defineString("MAIL_SENDER_SUBJECT", {
  default: "jvlgoncalves@monamienet.org",
});
const MAIL_FROM = defineString("MAIL_FROM", { default: "contact@monamienet.org" });
const MAIL_FROM_NAME = defineString("MAIL_FROM_NAME", { default: "MonAmie" });
const MAIL_SENDER_SERVICE_ACCOUNT = "mail-sender@monamienet-app.iam.gserviceaccount.com";

const iamAuth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

function mailer() {
  return new GmailMailer({
    request: async (options) => {
      const client = await iamAuth.getClient();
      return (await client.request(options)).data;
    },
    senderServiceAccount: MAIL_SENDER_SERVICE_ACCOUNT,
    subject: MAIL_SENDER_SUBJECT.value(),
    from: MAIL_FROM.value(),
    fromName: MAIL_FROM_NAME.value(),
  });
}

exports.sendInvites = teamCall((partnerId, data, request) =>
  sendInvites(admin.firestore(), groupsApi, mailer(), {
    partnerId,
    partnerName: String(data.partnerName ?? partnerId).slice(0, 60),
    owner: {
      email: String(request.auth.token.email).toLowerCase(),
      name: request.auth.token.name,
    },
    team: data.team ? String(data.team) : undefined,
    firstTeamName: data.firstTeamName,
    invites: data.invites,
  })
);

exports.listInvites = teamCall(async (partnerId, data) => ({
  invites: await listInvites(admin.firestore(), partnerId, data.team ? String(data.team) : null),
}));

exports.resendInvite = teamCall((partnerId, data) =>
  resendInvite(admin.firestore(), mailer(), String(data.inviteId ?? ""), partnerId)
);

exports.cancelInvite = teamCall(async (partnerId, data) => {
  await cancelInvite(admin.firestore(), String(data.inviteId ?? ""), partnerId);
  return { cancelled: true };
});

/** The signed-in person's pending invites (they may belong to nothing yet). */
exports.myInvites = onCall({ invoker: "public" }, async (request) => {
  const email = request.auth?.token?.email;
  if (!email || request.auth.token.email_verified !== true) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  return { invites: await myInvites(admin.firestore(), email) };
});

/** Accepts an invite addressed to the signed-in account. */
exports.acceptInvite = onCall(
  { invoker: "public", serviceAccount: GROUPS_ADMIN_SERVICE_ACCOUNT },
  async (request) => {
    const email = request.auth?.token?.email;
    if (!email || request.auth.token.email_verified !== true) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }
    try {
      return await acceptInvite(
        admin.firestore(),
        groupsApi,
        String(request.data?.inviteId ?? ""),
        email
      );
    } catch (error) {
      if (error instanceof InviteError) {
        throw new HttpsError("failed-precondition", error.message, { field: error.code });
      }
      logger.error(`[acceptInvite] ${error.message}`);
      throw new HttpsError("unavailable", "Não foi possível aceitar agora.");
    }
  }
);

const { THEMES_URL, activeThemeIdsFrom } = require("./branding_catalog");

// ── Creating an organization (#93) ─────────────────────────────────────────
// Runs as groups-admin@: it creates the root group and writes the registry
// (and, for Community, the shared project's Firestore, where the account
// needs roles/datastore.user).
const {
  checkPartnerId,
  createPartner,
  myCreations,
} = require("./creation_service");
const { CreationError } = require("./partner_creation");

function signedInEmail(request) {
  const email = request.auth?.token?.email;
  if (!email || request.auth.token.email_verified !== true) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  return email.toLowerCase();
}

/** The Workspace customer (`customers/…`) new groups belong to, read from
 * an existing group of the domain. */
async function workspaceCustomer() {
  const known = await groupsApi.lookup(MAIL_FROM.value());
  return known ? (await groupsApi.get(known)).parent : null;
}

/** "Disponível" at the name step: format, never retired, not taken. */
exports.checkPartnerId = onCall({ invoker: "public" }, async (request) => {
  signedInEmail(request);
  return checkPartnerId(admin.firestore(), String(request.data?.id ?? ""));
});

/** Creates the caller's organization (they become its owner). */
exports.createPartner = onCall(
  { invoker: "public", serviceAccount: GROUPS_ADMIN_SERVICE_ACCOUNT, timeoutSeconds: 120 },
  async (request) => {
    const ownerEmail = signedInEmail(request);
    try {
      const response = await fetch(THEMES_URL);
      const themes = activeThemeIdsFrom(await response.json());
      return await createPartner(
        admin.firestore(),
        {
          groups: groupsApi,
          customer: await workspaceCustomer(),
          communityDb: communityFirestore(),
          // Standard needs a provisioning identity that can create projects
          // in the organization, and the billing wait (Cloud Workflows).
          // Until MonAmieNet sets them up, a Standard creation stops as
          // `failed` with this reason and MonAmieNet finishes it by hand.
          createStandardProject: async () => {
            throw new Error("Standard provisioning is not set up yet.");
          },
        },
        { ...request.data, ownerEmail },
        themes
      );
    } catch (error) {
      if (error instanceof CreationError) {
        throw new HttpsError("invalid-argument", error.message, { field: error.code });
      }
      logger.error(`[createPartner] ${error.message}`);
      throw new HttpsError("unavailable", "Não foi possível criar agora.");
    }
  }
);

/** The caller's organizations still being created. */
exports.myCreations = onCall({ invoker: "public" }, async (request) => ({
  creations: await myCreations(admin.firestore(), signedInEmail(request)),
}));

// ── Deleting an account (#82) ──────────────────────────────────────────────
// Runs as groups-admin@: it leaves (and on cancel rejoins) the person's
// teams. The erase runs as partner-expirer@, which needs
// roles/datastore.user and roles/firebaseauth.admin on each partner project
// (and on the Community project) and roles/firebaseauth.admin here.
const {
  DeletionError,
  cancelAccountDeletion,
  eraseDueAccounts,
  pendingDeletion,
  requestAccountDeletion,
} = require("./account_deletion");
const { PartnerStatusError } = require("./partner_status");

function deletionCall(operation) {
  return onCall(
    { invoker: "public", serviceAccount: GROUPS_ADMIN_SERVICE_ACCOUNT },
    async (request) => {
      const email = signedInEmail(request);
      try {
        return await operation(email, request);
      } catch (error) {
        if (error instanceof DeletionError) {
          throw new HttpsError("failed-precondition", error.message, { field: error.code });
        }
        if (error instanceof PartnerStatusError) {
          throw new HttpsError("failed-precondition", error.message);
        }
        logger.error(`[accountDeletion] ${error.message}`);
        throw new HttpsError("unavailable", "Não foi possível agora. Tente de novo.");
      }
    }
  );
}

/**
 * Schedules the deletion of the caller's account (and of the organizations
 * they own, confirmed by typing each id in `confirmIds`).
 * Response: `{deleteAt: ISO string, ownedPartners: [id], ownedNames: {id: name}}`.
 */
exports.requestAccountDeletion = deletionCall(async (email, request) => {
  const confirmIds = Array.isArray(request.data?.confirmIds)
    ? request.data.confirmIds.map(String)
    : [];
  const result = await requestAccountDeletion(
    admin.firestore(),
    {
      groups: groupsApi,
      directGroups: (address) => fetchUserGroups(bearerToken(request), address),
    },
    { email, uid: request.auth.uid, confirmIds }
  );
  groupsByEmail.delete(email);
  return {
    deleteAt: result.deleteAt.toISOString(),
    ownedPartners: result.ownedPartners,
    ownedNames: result.ownedNames,
  };
});

/** Cancels the caller's pending deletion within its 30 days. */
exports.cancelAccountDeletion = deletionCall(async (email) => {
  await cancelAccountDeletion(admin.firestore(), { groups: groupsApi }, email);
  groupsByEmail.delete(email);
  return { cancelled: true };
});

/** The caller's pending deletion: `{deletion: {deleteAt, ownedPartners}|null}`. */
exports.myAccountDeletion = onCall({ invoker: "public" }, async (request) => {
  const deletion = await pendingDeletion(admin.firestore(), signedInEmail(request));
  return {
    deletion: deletion && {
      deleteAt: new Date(deletion.deleteAt).toISOString(),
      ownedPartners: deletion.ownedPartners,
      ownedNames: deletion.ownedNames,
    },
  };
});

/** Erases the accounts whose 30 days are over. */
exports.eraseAccounts = onSchedule(
  {
    schedule: "every day 03:30",
    timeZone: "America/Sao_Paulo",
    serviceAccount: EXPIRER_SERVICE_ACCOUNT,
  },
  async () => {
    const db = admin.firestore();
    const erased = await eraseDueAccounts(db, {
      partner: async (partnerId) => {
        const registry = await db.doc(`partners/${partnerId}`).get();
        if (!registry.exists) return null;
        const projectId = projectIdFor(partnerId, registry.get("plan"));
        const name = `erase-${projectId}`;
        const app =
          admin.apps.find((a) => a?.name === name) ??
          admin.initializeApp({ projectId }, name);
        return { db: app.firestore(), auth: app.auth() };
      },
      deleteAuthUser: (uid) => admin.auth().deleteUser(uid),
    });
    if (erased.length) logger.info(`[eraseAccounts] Erased ${erased.length} account(s).`);
  }
);
