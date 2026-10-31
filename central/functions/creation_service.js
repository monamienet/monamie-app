const {
  COMMUNITY_MIN_INTERVAL_MINUTES,
  CreationError,
  organizationIdFormatProblem,
  validateCreation,
} = require("./organization_creation");
const { OrganizationStatusError, transitionOrganizationStatus } = require("./organization_status");
const {
  BRANDING,
  CONFIG,
  ORGANIZATIONS,
  PLAN,
  organizationMembershipPath,
  organizationPath,
  retiredOrganizationPath,
} = require("./firestore_paths");
const { addToAccount } = require("./membership_store");
const { personKey } = require("./person_key");

/** Statuses of an organization still being created, for its owner. */
const CREATING = ["reserved", "awaiting_billing", "provisioning", "failed"];

/**
 * Whether `id` can be used for a new organization: format, never retired
 * (a deleted project id can never be reused), not taken. Checked at the
 * name step, so nobody finds out days later.
 *
 * @returns {Promise<{available: boolean, problem: string|null}>}
 */
async function checkOrganizationId(db, id) {
  const problem = organizationIdFormatProblem(id);
  if (problem) return { available: false, problem };
  const [registry, retired] = await Promise.all([
    db.doc(organizationPath(id)).get(),
    db.doc(retiredOrganizationPath(id)).get(),
  ]);
  if (retired.exists || registry.exists) {
    return { available: false, problem: "Esse identificador já está em uso." };
  }
  return { available: true, problem: null };
}

/**
 * Creates an organization for `owner`: reserves the id in the registry
 * (`null → reserved`, a transaction that also refuses retired ids), then
 * provisions it by plan.
 *
 * - Community: `provisioning`, then, in the shared Community project,
 *   `organizations/{id}/config/branding`, `config/plan` and the owner's
 *   `organizationMemberships/{personKey}` with `role: "admin"`, then the
 *   organization in the owner's `accounts` entry (central); `active` when
 *   done.
 * - Standard: `deps.createStandardProject` creates `monamienet-<id>` and
 *   grants the owner billing.projectManager, then `awaiting_billing`. The
 *   owner's membership is written when the project is ready (today by hand,
 *   `tool/organization.dart add-admin`).
 *
 * A failing step leaves the organization `failed` with
 * `failure: {step, message}` (MonAmieNet is alerted through the log); the
 * id stays reserved.
 *
 * @param {object} deps - `{communityDb, createStandardProject}`
 * @returns {Promise<{id: string, status: string}>}
 */
async function createOrganization(db, deps, request, activeThemeIds, now = new Date()) {
  const { id, name, themeId, plan } = validateCreation(request, activeThemeIds);
  const ownerEmail = String(request.ownerEmail).toLowerCase();
  try {
    await transitionOrganizationStatus(db, id, "reserved", {
      now,
      fields: { name, themeId, plan, ownerEmail, createdAt: now },
    });
  } catch (error) {
    if (error instanceof OrganizationStatusError) {
      throw new CreationError("id", "Esse identificador já está em uso.");
    }
    throw error;
  }

  if (plan === "standard") {
    try {
      await deps.createStandardProject(id, ownerEmail);
      await transitionOrganizationStatus(db, id, "awaiting_billing", { now });
      return { id, status: "awaiting_billing" };
    } catch (error) {
      await transitionOrganizationStatus(db, id, "provisioning", { now });
      return fail(db, id, "project", error, now);
    }
  }

  await transitionOrganizationStatus(db, id, "provisioning", { now });
  let step = "data";
  try {
    const organization = deps.communityDb.doc(organizationPath(id));
    await organization.collection(CONFIG).doc(BRANDING).set({ name, themeId, updatedAt: now });
    await organization
      .collection(CONFIG)
      .doc(PLAN)
      .set({ minIntervalMinutes: COMMUNITY_MIN_INTERVAL_MINUTES });
    step = "membership";
    await deps.communityDb
      .doc(organizationMembershipPath(id, personKey(ownerEmail)))
      .set({ email: ownerEmail, role: "admin", addedAt: now });
    await addToAccount(db, ownerEmail, id);
    await transitionOrganizationStatus(db, id, "active", { now });
    return { id, status: "active" };
  } catch (error) {
    return fail(db, id, step, error, now);
  }
}

async function fail(db, id, step, error, now) {
  console.error(`[createOrganization] ${id} failed at ${step}: ${error.message}`);
  await transitionOrganizationStatus(db, id, "failed", {
    now,
    fields: { failure: { step, message: String(error.message).slice(0, 300) } },
  });
  return { id, status: "failed" };
}

/**
 * The organizations `email` is creating (status before `active`), for the
 * app to show *Ativar faturamento*, the progress or *Falha na criação*.
 */
async function myCreations(db, email) {
  const snapshot = await db
    .collection(ORGANIZATIONS)
    .where("ownerEmail", "==", email.toLowerCase())
    .where("status", "in", CREATING)
    .get();
  return snapshot.docs.map((doc) => ({
    id: doc.id,
    name: doc.get("name") ?? doc.id,
    plan: doc.get("plan") ?? "standard",
    status: doc.get("status"),
    failureStep: doc.get("failure")?.step ?? null,
  }));
}

module.exports = { CREATING, checkOrganizationId, createOrganization, myCreations };
