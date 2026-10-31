const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { GoogleAuth } = require("google-auth-library");
const { organizationIdsFromGroups } = require("./organization_groups");
const {
  COMMUNITY_PROJECT_ID,
  OrganizationOptionsReader,
  projectIdFor,
} = require("./organization_options");
const { TtlCache } = require("./ttl_cache");
const { GROUPS_SCOPES, GroupsApi } = require("./groups_api");
const { TeamError } = require("./teams");
const { isOrganizationAdmin } = require("./organization_admin");
const { teamNames } = require("./team_names");
const { InviteError } = require("./invites");
const { GmailMailer } = require("./mailer");
const {
  acceptInvite,
  cancelInvite,
  cancelTeamInvites,
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
const { ORGANIZATIONS, organizationPath } = require("./firestore_paths");
const {
  BINDABLE,
  VISIBLE,
  dueOrganizationIds,
  retireOrganization,
} = require("./organization_status");
const { isValidOrganizationId } = require("./group_address");

admin.initializeApp();

// Host of the workspace-groups-gateway, shared with the organization projects.
const GATEWAY_HOST = defineString("GROUPS_GATEWAY_HOST");

const PLATFORMS = new Set(["android", "web"]);
const GATEWAY_TIMEOUT_MS = 10000;

const auth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/firebase.readonly"],
});
const options = new OrganizationOptionsReader(async (url) => {
  const client = await auth.getClient();
  const response = await client.request({ url });
  return response.data;
});
// Absorbs retry storms (a user tapping sign-in again) without spending the
// Directory API quota shared by all organizations. Kept short (#78): a removal
// must not keep routing someone to an organization for long. Each instance has
// its own cache, so a removed user may still be listed for up to a minute;
// the organization's syncClaims then grants nothing and the app shows
// *Sem organização*.
const groupsByEmail = new TtlCache(60 * 1000);

/**
 * Finds the organizations the signed-in user belongs to.
 *
 * The user signed in to this central project with Google. Their organizations
 * are derived from the names of their groups (`<id>00@`, `<id>NNr@`,
 * `<id>NNw@`; see group_address.js),
 * kept when their registry entry `organizations/{id}` has a status the app shows
 * (every status but `reserved`), and returned with that status. Organizations
 * the app binds (`active`, `migrating`, `deleting`) also carry the
 * FirebaseOptions of their project for the caller's platform. `owner` says
 * whether the caller is the organization's owner (`ownerEmail`, who created it),
 * which only matters for deleting their account; the organization's own
 * syncClaims decides what the user may access there.
 *
 * Request: `{platform: "android" | "web"}`.
 * Response: `{organizations: [{id, status, owner, options?}]}`, sorted by id.
 */
exports.resolveOrganizations = onCall({ invoker: "public" }, async (request) => {
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
  const entries = await visibleOrganizations(organizationIdsFromGroups(groups));

  const organizations = [];
  for (const { id, status, plan, ownerEmail } of entries) {
    const owner = ownerEmail === key;
    if (!BINDABLE.includes(status)) {
      organizations.push({ id, status, owner });
      continue;
    }
    try {
      organizations.push({
        id,
        status,
        owner,
        options: await options.get(id, platform, plan),
      });
    } catch (error) {
      // One misconfigured organization must not block the user's other organizations.
      logger.error(`[resolveOrganizations] Skipping ${id}: ${error.message}`);
    }
  }
  return { organizations };
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
    logger.error(`[groups] Gateway answered ${response.status}.`);
    throw new HttpsError("unavailable", "Could not read your groups.");
  }
  const body = await response.json();
  return Array.isArray(body?.groups) ? body.groups : [];
}

async function visibleOrganizations(ids) {
  if (ids.length === 0) return [];
  const db = admin.firestore();
  const docs = await db.getAll(...ids.map((id) => db.doc(organizationPath(id))));
  return docs
    .filter((doc) => VISIBLE.includes(doc.get("status")))
    .map((doc) => ({
      id: doc.id,
      status: doc.get("status"),
      plan: doc.get("plan"),
      ownerEmail: String(doc.get("ownerEmail") ?? "").toLowerCase(),
    }));
}

// Runs as its own service account: it is the only identity allowed to
// delete organization projects (roles/resourcemanager.projectDeleter on each).
// It keeps its first name: it is an existing IAM account, and renaming one
// means creating a new account and moving its roles by hand.
const EXPIRER_SERVICE_ACCOUNT =
  "partner-expirer@monamienet-app.iam.gserviceaccount.com";

const cloudPlatform = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

/**
 * Retires organizations whose timed exit is due: 7 days in `awaiting_billing`
 * (billing never linked) or 30 days in `deleting` (the grace period ended).
 * Each one loses its project and its registry entry, and its id is retired.
 */
exports.expireOrganizations = onSchedule(
  {
    schedule: "every day 03:00",
    timeZone: "America/Sao_Paulo",
    serviceAccount: EXPIRER_SERVICE_ACCOUNT,
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const snapshot = await db
      .collection(ORGANIZATIONS)
      .where("deleteAt", "<=", now)
      .get();
    const docs = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    for (const id of dueOrganizationIds(docs, now)) {
      try {
        await retireOrganization(db, id, eraseOrganizationData, { now });
        logger.info(`[expireOrganizations] Retired ${id}.`);
      } catch (error) {
        // The next run retries; one organization must not block the others.
        logger.error(`[expireOrganizations] Could not retire ${id}: ${error.message}`);
      }
    }
  }
);

/**
 * Erases organization `id`'s data: its whole project on the Standard plan, or
 * its subtree `organizations/{id}/**` in the shared Community project.
 */
async function eraseOrganizationData(id, registry) {
  if (registry?.plan === "community") {
    const community = communityFirestore();
    await community.recursiveDelete(community.doc(organizationPath(id)));
    return;
  }
  await deleteOrganizationProject(id);
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
 * Deletes organization `id`'s Google Cloud project. Google keeps it restorable
 * for up to 30 days, then erases it with all its data; its id can never be
 * used again. A project already waiting for deletion counts as deleted.
 */
async function deleteOrganizationProject(id) {
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
// admin role. Every call checks that the caller administers the organization
// (a direct member of its root group `<id>00@`, not `ownerEmail`) and only
// touches that organization's groups.
const GROUPS_ADMIN_SERVICE_ACCOUNT =
  "groups-admin@monamienet-app.iam.gserviceaccount.com";

const groupsAuth = new GoogleAuth({ scopes: GROUPS_SCOPES });
const groupsApi = new GroupsApi(async (options) => {
  const client = await groupsAuth.getClient();
  return (await client.request(options)).data;
});

/**
 * The organization id of a team call, once the caller is known to administer it.
 *
 * @throws {HttpsError} unauthenticated / permission-denied
 */
async function administeredOrganizationId(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const organizationId = request.data?.organizationId;
  const email = String(request.auth.token.email ?? "").toLowerCase();
  if (typeof organizationId !== "string" || !email) {
    throw new HttpsError("invalid-argument", "organizationId is required.");
  }
  if (!(await isOrganizationAdmin(admin.firestore(), groupsApi, organizationId, email))) {
    throw new HttpsError("permission-denied", "Só um administrador gerencia equipes.");
  }
  return organizationId;
}

/** Wraps a team operation: administrator check, then TeamError →
 * invalid-argument. */
function teamCall(operation) {
  return onCall(
    { invoker: "public", serviceAccount: GROUPS_ADMIN_SERVICE_ACCOUNT },
    async (request) => {
      const organizationId = await administeredOrganizationId(request);
      try {
        return await operation(organizationId, request.data ?? {}, request);
      } catch (error) {
        if (error instanceof TeamError || error instanceof InviteError) {
          throw new HttpsError(
            error.code === "full" ? "failed-precondition" : "invalid-argument",
            error.message,
            { field: error.code }
          );
        }
        logger.error(`[teams] ${organizationId}: ${error.message}`);
        throw new HttpsError("unavailable", "Não foi possível falar com os grupos agora.");
      }
    }
  );
}

exports.listTeams = teamCall(async (organizationId) => ({
  teams: await listTeams(groupsApi, organizationId),
}));

/**
 * The display names of the teams the caller sees in an organization, for the
 * team menu: every team for an administrator, otherwise the teams of the
 * caller's leaves. Open to everyone in the organization, not only its
 * administrators: the caller's direct groups (one gateway call, cached like
 * resolveOrganizations) decide which teams are named.
 *
 * Request: `{organizationId}`.
 * Response: `{names: {<teamKey>: displayName}}`; a team without a display
 * name is left out.
 */
exports.teamNames = onCall(
  { invoker: "public", serviceAccount: GROUPS_ADMIN_SERVICE_ACCOUNT },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    const { email, email_verified: emailVerified } = request.auth.token;
    if (!email || emailVerified !== true) {
      throw new HttpsError("failed-precondition", "A verified email is required.");
    }
    const organizationId = request.data?.organizationId;
    if (!isValidOrganizationId(organizationId)) {
      throw new HttpsError("invalid-argument", "organizationId is required.");
    }
    const groups = await groupsByEmail.getOrCompute(email.toLowerCase(), () =>
      fetchUserGroups(bearerToken(request), email)
    );
    const [entry] = await visibleOrganizations([organizationId]);
    if (!entry || !BINDABLE.includes(entry.status)) return { names: {} };
    try {
      return { names: await teamNames(groupsApi, organizationId, groups) };
    } catch (error) {
      logger.error(`[teamNames] ${organizationId}: ${error.message}`);
      throw new HttpsError("unavailable", "Não foi possível falar com os grupos agora.");
    }
  }
);

exports.createTeam = teamCall((organizationId, data) =>
  createTeam(groupsApi, organizationId, data.name)
);

exports.renameTeam = teamCall((organizationId, data) =>
  renameTeam(groupsApi, organizationId, String(data.team ?? ""), data.name)
);

exports.teamDeletionImpact = teamCall((organizationId, data) =>
  deletionImpact(groupsApi, organizationId, String(data.team ?? ""))
);

// Groups first: if that fails, nothing changed. Invites left pending by a
// failure after it cannot be accepted (`acceptInvite` checks the team's age).
exports.deleteTeam = teamCall(async (organizationId, data) => {
  const team = String(data.team ?? "");
  await deleteTeam(groupsApi, organizationId, team);
  await cancelTeamInvites(admin.firestore(), organizationId, team);
  return { deleted: true };
});

exports.setMemberRoles = teamCall((organizationId, data) =>
  setRoles(groupsApi, organizationId, String(data.team ?? ""), String(data.email ?? ""), data.roles)
);

exports.removeMember = teamCall(async (organizationId, data) => {
  await removePerson(groupsApi, organizationId, String(data.team ?? ""), String(data.email ?? ""));
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

exports.sendInvites = teamCall((organizationId, data, request) =>
  sendInvites(admin.firestore(), groupsApi, mailer(), {
    organizationId,
    organizationName: String(data.organizationName ?? organizationId).slice(0, 60),
    inviter: {
      email: String(request.auth.token.email).toLowerCase(),
      name: request.auth.token.name,
    },
    team: data.team ? String(data.team) : undefined,
    firstTeamName: data.firstTeamName,
    invites: data.invites,
  })
);

exports.listInvites = teamCall(async (organizationId, data) => ({
  invites: await listInvites(admin.firestore(), organizationId, data.team ? String(data.team) : null),
}));

exports.resendInvite = teamCall((organizationId, data) =>
  resendInvite(admin.firestore(), mailer(), String(data.inviteId ?? ""), organizationId)
);

exports.cancelInvite = teamCall(async (organizationId, data) => {
  await cancelInvite(admin.firestore(), String(data.inviteId ?? ""), organizationId);
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
  checkOrganizationId,
  createOrganization,
  myCreations,
} = require("./creation_service");
const { CreationError } = require("./organization_creation");

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
exports.checkOrganizationId = onCall({ invoker: "public" }, async (request) => {
  signedInEmail(request);
  return checkOrganizationId(admin.firestore(), String(request.data?.id ?? ""));
});

/** Creates the caller's organization (they become its owner and first
 * administrator). */
exports.createOrganization = onCall(
  { invoker: "public", serviceAccount: GROUPS_ADMIN_SERVICE_ACCOUNT, timeoutSeconds: 120 },
  async (request) => {
    const ownerEmail = signedInEmail(request);
    try {
      const response = await fetch(THEMES_URL);
      const themes = activeThemeIdsFrom(await response.json());
      return await createOrganization(
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
      logger.error(`[createOrganization] ${error.message}`);
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
// roles/datastore.user and roles/firebaseauth.admin on each organization project
// (and on the Community project) and roles/firebaseauth.admin here.
const {
  DeletionError,
  cancelAccountDeletion,
  eraseDueAccounts,
  pendingDeletion,
  requestAccountDeletion,
} = require("./account_deletion");
const { OrganizationStatusError } = require("./organization_status");

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
        if (error instanceof OrganizationStatusError) {
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
 * Response: `{deleteAt: ISO string, ownedOrganizationIds: [id], ownedOrganizationNames: {id: name}}`.
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
    ownedOrganizationIds: result.ownedOrganizationIds,
    ownedOrganizationNames: result.ownedOrganizationNames,
  };
});

/** Cancels the caller's pending deletion within its 30 days. */
exports.cancelAccountDeletion = deletionCall(async (email) => {
  await cancelAccountDeletion(admin.firestore(), { groups: groupsApi }, email);
  groupsByEmail.delete(email);
  return { cancelled: true };
});

/** The caller's pending deletion: `{deletion: {deleteAt, ownedOrganizationIds}|null}`. */
exports.myAccountDeletion = onCall({ invoker: "public" }, async (request) => {
  const deletion = await pendingDeletion(admin.firestore(), signedInEmail(request));
  return {
    deletion: deletion && {
      deleteAt: new Date(deletion.deleteAt).toISOString(),
      ownedOrganizationIds: deletion.ownedOrganizationIds,
      ownedOrganizationNames: deletion.ownedOrganizationNames,
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
      organization: async (organizationId) => {
        const registry = await db.doc(organizationPath(organizationId)).get();
        if (!registry.exists) return null;
        const projectId = projectIdFor(organizationId, registry.get("plan"));
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
