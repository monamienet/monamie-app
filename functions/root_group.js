const { isValidPartnerId } = require("./group_address");

const PROJECT_PREFIX = "monamienet-";

/**
 * The partner whose own Firebase project is `projectId`.
 *
 * MonAmie convention: a Standard partner `<id>` lives in project
 * `monamienet-<id>`. Deriving it means the same function code serves every
 * partner without a per-project `.env` file.
 *
 * @param {string} projectId - Firebase project id, e.g. "monamienet-aquariustur"
 * @returns {string} Partner id, e.g. "aquariustur"
 * @throws {Error} If `projectId` does not follow the convention
 */
function partnerIdForProject(projectId) {
  if (typeof projectId !== "string" || !projectId.startsWith(PROJECT_PREFIX)) {
    throw new Error(
      `Project id "${projectId}" does not start with "${PROJECT_PREFIX}".`
    );
  }
  const id = projectId.slice(PROJECT_PREFIX.length);
  if (!isValidPartnerId(id)) {
    throw new Error(`Project id "${projectId}" has an invalid partner id.`);
  }
  return id;
}

/**
 * Derives a partner's root group from its Firebase project id:
 * `monamienet-<id>` → `<id>00@monamienet.org`.
 *
 * @param {string} projectId - Firebase project id
 * @returns {string} Root group email, e.g. "aquariustur00@monamienet.org"
 * @throws {Error} If `projectId` does not follow the convention
 */
function rootGroupEmailFor(projectId) {
  return `${partnerIdForProject(projectId)}00@monamienet.org`;
}

module.exports = { partnerIdForProject, rootGroupEmailFor };
