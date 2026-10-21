const PROJECT_PREFIX = "monamienet-";

// Ids that can never be a partner; `app` is the central MonAmie project.
// Kept in sync with `_reservedPartnerIds` in partner_config.dart.
const RESERVED_PARTNER_IDS = new Set(["app"]);

/**
 * Derives a partner's root group from its Firebase project id.
 *
 * MonAmie convention: partner `<id>` lives in project `monamienet-<id>` and
 * its root group is `<id>00@monamienet.org`. Deriving it means the same
 * function code serves every partner without a per-project `.env` file.
 *
 * @param {string} projectId - Firebase project id, e.g. "monamienet-aquariustur"
 * @returns {string} Root group email, e.g. "aquariustur00@monamienet.org"
 * @throws {Error} If `projectId` does not follow the convention
 */
function rootGroupEmailFor(projectId) {
  if (typeof projectId !== "string" || !projectId.startsWith(PROJECT_PREFIX)) {
    throw new Error(
      `Project id "${projectId}" does not start with "${PROJECT_PREFIX}".`
    );
  }
  const id = projectId.slice(PROJECT_PREFIX.length);
  if (!/^[a-z][a-z0-9]*$/.test(id) || RESERVED_PARTNER_IDS.has(id)) {
    throw new Error(`Project id "${projectId}" has an invalid partner id.`);
  }
  return `${id}00@monamienet.org`;
}

module.exports = { rootGroupEmailFor };
