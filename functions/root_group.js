const { isValidOrganizationId } = require("./group_address");

const PROJECT_PREFIX = "monamienet-";

/** The shared project of every Community organization. */
const COMMUNITY_PROJECT_ID = "monamienet-community";

/**
 * The organization whose own Firebase project is `projectId`.
 *
 * MonAmie convention: a Standard organization `<id>` lives in project
 * `monamienet-<id>`. Deriving it means the same function code serves every
 * organization without a per-project `.env` file.
 *
 * @param {string} projectId - Firebase project id, e.g. "monamienet-aquariustur"
 * @returns {string} Organization id, e.g. "aquariustur"
 * @throws {Error} If `projectId` does not follow the convention
 */
function organizationIdForProject(projectId) {
  if (typeof projectId !== "string" || !projectId.startsWith(PROJECT_PREFIX)) {
    throw new Error(
      `Project id "${projectId}" does not start with "${PROJECT_PREFIX}".`
    );
  }
  const id = projectId.slice(PROJECT_PREFIX.length);
  if (!isValidOrganizationId(id)) {
    throw new Error(`Project id "${projectId}" has an invalid organization id.`);
  }
  return id;
}

/**
 * Derives an organization's root group from its Firebase project id:
 * `monamienet-<id>` → `<id>00@monamienet.org`.
 *
 * @param {string} projectId - Firebase project id
 * @returns {string} Root group email, e.g. "aquariustur00@monamienet.org"
 * @throws {Error} If `projectId` does not follow the convention
 */
function rootGroupEmailFor(projectId) {
  return `${organizationIdForProject(projectId)}00@monamienet.org`;
}

module.exports = { COMMUNITY_PROJECT_ID, organizationIdForProject, rootGroupEmailFor };
