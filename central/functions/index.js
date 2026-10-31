const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { GoogleAuth } = require("google-auth-library");
const {
  COMMUNITY_PROJECT_ID,
  OrganizationOptionsReader,
  projectIdFor,
} = require("./organization_options");
const { administeredOrganization } = require("./organization_admin");
const { InviteError } = require("./invites");
const { GmailMailer } = require("./mailer");
const {
  acceptInvite,
  cancelGroupInvites,
  cancelInvite,
  listInvites,
  myInvites,
  resendInvite,
  sendInvites,
} = require("./invite_service");
const {
  GroupError,
  createGroup,
  deleteGroup,
  groupDeletionImpact,
  listGroups,
  removeMember,
  renameGroup,
  setMemberRoles,
} = require("./group_service");
const {
  accountOrganizationIds,
  organizationOpener,
  removeOrganizationFromAccounts,
} = require("./membership_store");
const { ORGANIZATIONS, organizationPath } = require("./firestore_paths");
const {
  BINDABLE,
  VISIBLE,
  dueOrganizationIds,
  retireOrganization,
} = require("./organization_status");
const { isValidOrganizationId } = require("./organization_id");

admin.initializeApp();

const PLATFORMS = new Set(["android", "web"]);

const auth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/firebase.readonly"],
});
const options = new OrganizationOptionsReader(async (url) => {
  const client = await auth.getClient();
  const response = await client.request({ url });
  return response.data;
});

/**
 * The Admin app of another project (an organization's own project, or the
 * shared Community project), created once per instance. It runs with the
 * function's service account, which needs roles/datastore.user there (and
 * roles/firebaseauth.admin for the erase).
 */
function projectApp(projectId) {
  const name = `project-${projectId}`;
  return (
    admin.apps.find((a) => a?.name === name) ?? admin.initializeApp({ projectId }, name)
  );
}

/** Firestore of an organization project. */
function projectFirestore(projectId) {
  return projectApp(projectId).firestore();
}

/** Firestore of the shared Community project. */
function communityFirestore() {
  return projectFirestore(COMMUNITY_PROJECT_ID);
}

/** Opens an organization's Firestore from its registry entry. */
const openOrganization = organizationOpener(admin.firestore(), projectFirestore);

/** The caller's lowercased, verified e-mail. */
function signedInEmail(request) {
  const email = request.auth?.token?.email;
  if (!email || request.auth.token.email_verified !== true) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  return email.toLowerCase();
}

/**
 * Finds the organizations the signed-in user belongs to.
 *
 * Their organizations come from their entry in this project,
 * `accounts/{personKey}.organizationIds`, written by the central functions
 * after each membership change in the organization project. They are kept
 * when their registry entry `organizations/{id}` has a status the app shows
 * (every status but `reserved`), and returned with that status.
 * Organizations the app binds (`active`, `migrating`, `deleting`) also carry
 * the FirebaseOptions of their project for the caller's platform. `owner`
 * says whether the caller is the organization's owner (`ownerEmail`, who
 * created it), which only matters for deleting their account. The
 * organization's own memberships decide what the user may access there; an
 * id left in `accounts` after a removal is dropped by the app when it finds
 * no membership.
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

  const key = email.toLowerCase();
  const ids = await accountOrganizationIds(admin.firestore(), key);
  const entries = await visibleOrganizations(ids.filter(isValidOrganizationId));

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
    }))
    .sort((a, b) => a.id.localeCompare(b.id));
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
 * Each one loses its project (or Community subtree), its id in every
 * `accounts` entry and its registry entry, and its id is retired.
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
        await retireOrganization(
          db,
          id,
          async (organizationId, registry) => {
            await eraseOrganizationData(organizationId, registry);
            await removeOrganizationFromAccounts(db, organizationId);
          },
          { now }
        );
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

// ── Groups ─────────────────────────────────────────────────────────────────
// Every call that writes memberships runs as groups-admin@ (it keeps its
// first name; replacing it with a dedicated account is a follow-up), which
// needs roles/datastore.user on the central project, on the Community
// project and on each Standard organization project. Organization-scoped
// calls check that the caller administers the organization: their
// `organizationMemberships/{personKey}` there has `role: "admin"`.
const MEMBERSHIP_SERVICE_ACCOUNT =
  "groups-admin@monamienet-app.iam.gserviceaccount.com";

/**
 * The organization of an administrator's call: `{organizationId, db}`.
 *
 * @throws {HttpsError} unauthenticated / invalid-argument / permission-denied
 */
async function administered(request) {
  const email = signedInEmail(request);
  const organizationId = request.data?.organizationId;
  if (!isValidOrganizationId(organizationId)) {
    throw new HttpsError("invalid-argument", "organizationId is required.", {
      field: "organizationId",
    });
  }
  const db = await administeredOrganization(openOrganization, organizationId, email);
  if (!db) {
    throw new HttpsError("permission-denied", "Só um administrador gerencia grupos.");
  }
  return { organizationId, db, email };
}

/** Wraps an administrator's call: the check, then GroupError / InviteError →
 * invalid-argument (`full` → failed-precondition) with `{field}`. */
function adminCall(operation) {
  return onCall(
    { invoker: "public", serviceAccount: MEMBERSHIP_SERVICE_ACCOUNT },
    async (request) => {
      const context = await administered(request);
      try {
        return await operation(context, request.data ?? {}, request);
      } catch (error) {
        if (error instanceof GroupError || error instanceof InviteError) {
          throw new HttpsError(
            error.code === "full" ? "failed-precondition" : "invalid-argument",
            error.message,
            { field: error.code }
          );
        }
        logger.error(`[groups] ${context.organizationId}: ${error.message}`);
        throw new HttpsError("unavailable", "Não foi possível falar com o servidor agora.");
      }
    }
  );
}

/** Response: `{groups: [{id, name, createdAt, people: [{email, roles}]}]}`. */
exports.listGroups = adminCall(async ({ db, organizationId }) => ({
  groups: await listGroups(db, organizationId),
}));

/** Request: `{organizationId, name}`. Response: `{id, name}`. */
exports.createGroup = adminCall(({ db, organizationId }, data) =>
  createGroup(db, organizationId, data.name)
);

/** Request: `{organizationId, groupId, name}`. Response: `{id, name}`. */
exports.renameGroup = adminCall(({ db, organizationId }, data) =>
  renameGroup(db, organizationId, String(data.groupId ?? ""), data.name)
);

/** Request: `{organizationId, groupId}`. Response: `{loses, stays}`. */
exports.groupDeletionImpact = adminCall(({ db, organizationId }, data) =>
  groupDeletionImpact(db, organizationId, String(data.groupId ?? ""))
);

/** Request: `{organizationId, groupId}`. Response: `{deleted: true}`. */
exports.deleteGroup = adminCall(async ({ db, organizationId }, data) => {
  const groupId = String(data.groupId ?? "");
  const centralDb = admin.firestore();
  await deleteGroup(db, centralDb, organizationId, groupId, () =>
    cancelGroupInvites(centralDb, organizationId, groupId)
  );
  return { deleted: true };
});

/** Request: `{organizationId, groupId, email, roles}`. Response: `{roles}`. */
exports.setMemberRoles = adminCall(({ db, organizationId }, data) =>
  setMemberRoles(db, organizationId, String(data.groupId ?? ""), data.email, data.roles)
);

/** Request: `{organizationId, groupId, email}`. Response: `{removed: true,
 * leftOrganization}`. */
exports.removeMember = adminCall(async ({ db, organizationId }, data) => {
  const { leftOrganization } = await removeMember(
    db,
    admin.firestore(),
    organizationId,
    String(data.groupId ?? ""),
    data.email
  );
  return { removed: true, leftOrganization };
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

/**
 * Request: `{organizationId, organizationName, groupId?, firstGroupName?,
 * invites: [{email, roles}]}`. Response: `{groupId, groupName, sent, skipped}`.
 */
exports.sendInvites = adminCall(({ db, organizationId, email }, data, request) =>
  sendInvites(admin.firestore(), db, mailer(), {
    organizationId,
    organizationName: String(data.organizationName ?? organizationId).slice(0, 60),
    inviter: { email, name: request.auth.token.name },
    groupId: data.groupId ? String(data.groupId) : undefined,
    firstGroupName: data.firstGroupName,
    invites: data.invites,
  })
);

/** Request: `{organizationId, groupId?}`. Response: `{invites}`. */
exports.listInvites = adminCall(async ({ organizationId }, data) => ({
  invites: await listInvites(
    admin.firestore(),
    organizationId,
    data.groupId ? String(data.groupId) : null
  ),
}));

exports.resendInvite = adminCall(({ organizationId }, data) =>
  resendInvite(admin.firestore(), mailer(), String(data.inviteId ?? ""), organizationId)
);

exports.cancelInvite = adminCall(async ({ organizationId }, data) => {
  await cancelInvite(admin.firestore(), String(data.inviteId ?? ""), organizationId);
  return { cancelled: true };
});

/** The signed-in person's pending invites (they may belong to nothing yet). */
exports.myInvites = onCall({ invoker: "public" }, async (request) => ({
  invites: await myInvites(admin.firestore(), signedInEmail(request)),
}));

/**
 * Accepts an invite addressed to the signed-in account. Response:
 * `{organizationId, groupId, organizationName, groupName, roles, inviterName}`.
 */
exports.acceptInvite = onCall(
  { invoker: "public", serviceAccount: MEMBERSHIP_SERVICE_ACCOUNT },
  async (request) => {
    const email = signedInEmail(request);
    try {
      return await acceptInvite(
        admin.firestore(),
        openOrganization,
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
// Runs as groups-admin@: it writes the registry and, for Community, the
// shared project's Firestore (the owner's admin membership included) and the
// owner's `accounts` entry.
const {
  checkOrganizationId,
  createOrganization,
  myCreations,
} = require("./creation_service");
const { CreationError } = require("./organization_creation");

/** "Disponível" at the name step: format, never retired, not taken. */
exports.checkOrganizationId = onCall({ invoker: "public" }, async (request) => {
  signedInEmail(request);
  return checkOrganizationId(admin.firestore(), String(request.data?.id ?? ""));
});

/** Creates the caller's organization (they become its owner and first
 * administrator). */
exports.createOrganization = onCall(
  { invoker: "public", serviceAccount: MEMBERSHIP_SERVICE_ACCOUNT, timeoutSeconds: 120 },
  async (request) => {
    const ownerEmail = signedInEmail(request);
    try {
      const response = await fetch(THEMES_URL);
      const themes = activeThemeIdsFrom(await response.json());
      return await createOrganization(
        admin.firestore(),
        {
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
// Runs as groups-admin@: it removes (and on cancel writes back) the person's
// memberships. The erase runs as partner-expirer@, which needs
// roles/datastore.user and roles/firebaseauth.admin on each organization
// project (and on the Community project) and roles/firebaseauth.admin here.
const {
  DeletionError,
  cancelAccountDeletion,
  eraseDueAccounts,
  pendingDeletion,
  requestAccountDeletion,
} = require("./account_deletion");
const { OrganizationStatusError } = require("./organization_status");

/** Opens an organization's Firestore for the deletion service. */
const deletionDeps = {
  organizationDb: async (organizationId) => (await openOrganization(organizationId))?.db ?? null,
};

function deletionCall(operation) {
  return onCall(
    { invoker: "public", serviceAccount: MEMBERSHIP_SERVICE_ACCOUNT },
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
  const result = await requestAccountDeletion(admin.firestore(), deletionDeps, {
    email,
    uid: request.auth.uid,
    confirmIds,
  });
  return {
    deleteAt: result.deleteAt.toISOString(),
    ownedOrganizationIds: result.ownedOrganizationIds,
    ownedOrganizationNames: result.ownedOrganizationNames,
  };
});

/** Cancels the caller's pending deletion within its 30 days. */
exports.cancelAccountDeletion = deletionCall(async (email) => {
  await cancelAccountDeletion(admin.firestore(), deletionDeps, email);
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
        const app = projectApp(projectIdFor(organizationId, registry.get("plan")));
        return { db: app.firestore(), auth: app.auth() };
      },
      deleteAuthUser: (uid) => admin.auth().deleteUser(uid),
    });
    if (erased.length) logger.info(`[eraseAccounts] Erased ${erased.length} account(s).`);
  }
);
