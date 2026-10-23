const GROUP_DOMAIN = "monamienet.org";
const PARTNER_ID = /^[a-z][a-z0-9]*$/;
const SUFFIX = /^[0-9]{2}$/;

/**
 * The partner a MonAmie group belongs to, or null when `email` does not
 * follow the convention.
 *
 * Every group of partner `<id>` is `<id>NN@monamienet.org`, where `NN` is
 * always two digits (`00` is the root group), so the id is the part before
 * the `@` without its last two characters. `app` is reserved for the central
 * project. Twin of `partnerIdFromGroupEmail` in
 * `lib/app/config/partner/partner_config.dart`.
 *
 * @param {unknown} email - Group email
 * @returns {string|null} Partner id
 */
function partnerIdFromGroupEmail(email) {
  if (typeof email !== "string") return null;
  const normalized = email.trim().toLowerCase();
  const at = normalized.lastIndexOf("@");
  if (at < 0 || normalized.slice(at + 1) !== GROUP_DOMAIN) return null;
  const local = normalized.slice(0, at);
  if (local.length < 3 || !SUFFIX.test(local.slice(-2))) return null;
  const id = local.slice(0, -2);
  return PARTNER_ID.test(id) && id !== "app" ? id : null;
}

/**
 * The distinct partner ids of a user's groups, sorted.
 *
 * @param {Array<{email?: unknown}>} groups - Groups from the gateway
 * @returns {string[]} Partner ids
 */
function partnerIdsFromGroups(groups) {
  const ids = new Set();
  for (const group of groups ?? []) {
    const id = partnerIdFromGroupEmail(group?.email);
    if (id) ids.add(id);
  }
  return [...ids].sort();
}

module.exports = { partnerIdFromGroupEmail, partnerIdsFromGroups };
