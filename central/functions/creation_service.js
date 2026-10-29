const {
  COMMUNITY_MIN_INTERVAL_MINUTES,
  CreationError,
  partnerIdFormatProblem,
  validateCreation,
} = require("./partner_creation");
const { PartnerStatusError, transitionPartnerStatus } = require("./partner_status");

/** Statuses of an organization still being created, for its owner. */
const CREATING = ["reserved", "awaiting_billing", "provisioning", "failed"];

/**
 * Whether `id` can be used for a new organization: format, never retired
 * (a deleted project id can never be reused), not taken. Checked at the
 * name step, so nobody finds out days later.
 *
 * @returns {Promise<{available: boolean, problem: string|null}>}
 */
async function checkPartnerId(db, id) {
  const problem = partnerIdFormatProblem(id);
  if (problem) return { available: false, problem };
  const [registry, retired] = await Promise.all([
    db.doc(`partners/${id}`).get(),
    db.doc(`retiredPartnerIds/${id}`).get(),
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
 * - Community: `provisioning`, then the root group `<id>00@` with the owner
 *   as its only member, and `partners/{id}/config/branding` and
 *   `config/plan` in the shared Community project; `active` when done.
 * - Standard: `deps.createStandardProject` creates `monamienet-<id>` and
 *   grants the owner billing.projectManager, then `awaiting_billing`.
 *
 * A failing step leaves the organization `failed` with
 * `failure: {step, message}` (MonAmieNet is alerted through the log); the
 * id stays reserved.
 *
 * @param {object} deps - `{groups, communityDb, customer, createStandardProject}`
 * @returns {Promise<{id: string, status: string}>}
 */
async function createPartner(db, deps, request, activeThemeIds, now = new Date()) {
  const { id, name, themeId, plan } = validateCreation(request, activeThemeIds);
  const ownerEmail = String(request.ownerEmail).toLowerCase();
  try {
    await transitionPartnerStatus(db, id, "reserved", {
      now,
      fields: { name, themeId, plan, ownerEmail, createdAt: now },
    });
  } catch (error) {
    if (error instanceof PartnerStatusError) {
      throw new CreationError("id", "Esse identificador já está em uso.");
    }
    throw error;
  }

  if (plan === "standard") {
    try {
      await deps.createStandardProject(id, ownerEmail);
      await transitionPartnerStatus(db, id, "awaiting_billing", { now });
      return { id, status: "awaiting_billing" };
    } catch (error) {
      await transitionPartnerStatus(db, id, "provisioning", { now });
      return fail(db, id, "project", error, now);
    }
  }

  await transitionPartnerStatus(db, id, "provisioning", { now });
  let step = "group";
  try {
    await provisionRootGroup(deps.groups, deps.customer, id, name, ownerEmail);
    step = "data";
    const partner = deps.communityDb.doc(`partners/${id}`);
    await partner.collection("config").doc("branding").set({ name, themeId, updatedAt: now });
    await partner
      .collection("config")
      .doc("plan")
      .set({ minIntervalMinutes: COMMUNITY_MIN_INTERVAL_MINUTES });
    await transitionPartnerStatus(db, id, "active", { now });
    return { id, status: "active" };
  } catch (error) {
    return fail(db, id, step, error, now);
  }
}

async function fail(db, id, step, error, now) {
  console.error(`[createPartner] ${id} failed at ${step}: ${error.message}`);
  await transitionPartnerStatus(db, id, "failed", {
    now,
    fields: { failure: { step, message: String(error.message).slice(0, 300) } },
  });
  return { id, status: "failed" };
}

/** The root group `<id>00@` with `ownerEmail` as its first administrator (a
 * plain member); idempotent. */
async function provisionRootGroup(groups, customer, id, name, ownerEmail) {
  const email = `${id}00@monamienet.org`;
  let root = await groups.lookup(email);
  if (!root) {
    root = await groups.create(email, name, customer);
    await groups.setMonAmieSettings(email);
  }
  await groups.addMember(root, ownerEmail);
}

/**
 * The organizations `email` is creating (status before `active`), for the
 * app to show *Ativar faturamento*, the progress or *Falha na criação*.
 */
async function myCreations(db, email) {
  const snapshot = await db
    .collection("partners")
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

module.exports = { CREATING, checkPartnerId, createPartner, myCreations };
