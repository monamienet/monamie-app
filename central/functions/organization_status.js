const { FieldValue } = require("firebase-admin/firestore");
const { organizationPath, retiredOrganizationPath } = require("./firestore_paths");

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Every status an organization can have in the central registry `organizations/{id}`.
 * The end of the lifecycle is not a status: the document is deleted and the
 * id is written to `retiredOrganizationIds/{id}` (see `retireOrganization`).
 */
const STATUSES = Object.freeze([
  "reserved",
  "awaiting_billing",
  "provisioning",
  "active",
  "migrating",
  "failed",
  "deleting",
]);

/**
 * The lifecycle drawn in issue #96. `null` is "no document yet": only
 * creation (#93) starts there. Any pair not listed is rejected.
 */
const TRANSITIONS = Object.freeze({
  null: ["reserved"],
  reserved: ["awaiting_billing", "provisioning"],
  awaiting_billing: ["provisioning"],
  provisioning: ["active", "failed"],
  failed: ["provisioning"],
  active: ["migrating", "deleting"],
  migrating: ["active"],
  deleting: ["active"],
});

/** Statuses `resolveOrganizations` returns: all but `reserved` (seconds long). */
const VISIBLE = Object.freeze(STATUSES.filter((s) => s !== "reserved"));

/** Statuses whose organization the app binds, so they need Firebase options. */
const BINDABLE = Object.freeze(["active", "migrating", "deleting"]);

/**
 * How long an organization may stay in a status before it is retired. Entering one
 * of these statuses sets `deleteAt`; leaving it removes the field.
 */
const TIMED_EXITS = Object.freeze({
  awaiting_billing: 7 * DAY_MS,
  deleting: 30 * DAY_MS,
});

/**
 * Whether the lifecycle allows going from `from` to `to`.
 *
 * @param {string|null} from - Current status, or null when no document exists
 * @param {string} to - Requested status
 * @returns {boolean}
 */
function canTransition(from, to) {
  return (TRANSITIONS[from] ?? []).includes(to);
}

/**
 * The registry fields to write when an organization enters `to` at `now`.
 *
 * @param {string} to - New status
 * @param {Date} now - Time of the transition
 * @returns {{status: string, updatedAt: Date, deleteAt: Date|null}}
 *   `deleteAt` null means the field must be removed.
 */
function statusFields(to, now) {
  const ttl = TIMED_EXITS[to];
  return {
    status: to,
    updatedAt: now,
    deleteAt: ttl === undefined ? null : new Date(now.getTime() + ttl),
  };
}

/**
 * The ids of registry documents whose timed exit is due at `now`.
 *
 * @param {Array<{id: string, status?: unknown, deleteAt?: unknown}>} docs
 *   Registry entries; `deleteAt` is a Date (or a Firestore Timestamp)
 * @param {Date} now - Current time
 * @returns {string[]} Ids to retire
 */
function dueOrganizationIds(docs, now) {
  return docs
    .filter((doc) => Object.hasOwn(TIMED_EXITS, doc.status))
    .filter((doc) => {
      const at = toDate(doc.deleteAt);
      return at !== null && at.getTime() <= now.getTime();
    })
    .map((doc) => doc.id);
}

function toDate(value) {
  if (value instanceof Date) return value;
  if (value && typeof value.toDate === "function") return value.toDate();
  return null;
}

/**
 * Error thrown when a requested transition is not in the lifecycle, or the
 * id is retired. Callable functions turn it into `failed-precondition`.
 */
class OrganizationStatusError extends Error {}

/**
 * The single writer of `organizations/{id}.status`: moves organization `id` to `to` in
 * a transaction, or throws a `OrganizationStatusError`.
 *
 * Creation (`null` → `reserved`) is refused for a retired id: a deleted
 * Google Cloud project id can never be reused, and the groups of a retired
 * Community organization belonged to real people.
 *
 * @param {FirebaseFirestore.Firestore} db - Central Firestore
 * @param {string} id - Organization id
 * @param {string} to - New status
 * @param {{now?: Date, fields?: object}} [options] - `fields` are written
 *   with the status (e.g. the creator's e-mail on reservation)
 * @returns {Promise<void>}
 */
async function transitionOrganizationStatus(db, id, to, { now = new Date(), fields = {} } = {}) {
  const ref = db.doc(organizationPath(id));
  const retired = db.doc(retiredOrganizationPath(id));
  await db.runTransaction(async (tx) => {
    const [doc, tomb] = await Promise.all([tx.get(ref), tx.get(retired)]);
    const from = doc.exists ? doc.get("status") ?? null : null;
    if (from === null && tomb.exists) {
      throw new OrganizationStatusError(`Organization id '${id}' is retired.`);
    }
    if (!canTransition(from, to)) {
      throw new OrganizationStatusError(
        `Organization '${id}' cannot go from ${from ?? "nothing"} to ${to}.`
      );
    }
    const { deleteAt, ...rest } = statusFields(to, now);
    const data = { ...fields, ...rest };
    if (doc.exists) {
      tx.update(ref, { ...data, deleteAt: deleteAt ?? FieldValue.delete() });
    } else {
      tx.create(ref, deleteAt ? { ...data, deleteAt } : data);
    }
  });
}

/**
 * Whether `id` was retired and can never be used again.
 *
 * @param {FirebaseFirestore.Firestore} db - Central Firestore
 * @param {string} id - Organization id
 * @returns {Promise<boolean>}
 */
async function isRetiredOrganizationId(db, id) {
  return (await db.doc(retiredOrganizationPath(id)).get()).exists;
}

/**
 * Ends organization `id`'s lifecycle: erases its data, then deletes its registry
 * entry and writes `retiredOrganizationIds/{id}` holding only `retiredAt`.
 *
 * The data goes first: when erasing fails, the registry stays as it is and
 * the next run retries, so nothing is left without an entry pointing to it.
 *
 * @param {FirebaseFirestore.Firestore} db - Central Firestore
 * @param {string} id - Organization id
 * @param {(id: string, registry: object) => Promise<void>} eraseData -
 *   Deletes the organization's data (its project, or its Community subtree)
 * @param {{now?: Date}} [options]
 * @returns {Promise<void>}
 */
async function retireOrganization(db, id, eraseData, { now = new Date() } = {}) {
  const ref = db.doc(organizationPath(id));
  const doc = await ref.get();
  if (!doc.exists) return;
  await eraseData(id, doc.data());
  const batch = db.batch();
  batch.delete(ref);
  batch.set(db.doc(retiredOrganizationPath(id)), { retiredAt: now });
  await batch.commit();
}

module.exports = {
  BINDABLE,
  OrganizationStatusError,
  STATUSES,
  TIMED_EXITS,
  TRANSITIONS,
  VISIBLE,
  canTransition,
  dueOrganizationIds,
  isRetiredOrganizationId,
  retireOrganization,
  statusFields,
  transitionOrganizationStatus,
};
