const { organizationMembership, personGroupMemberships } = require("./membership_store");
const { GroupError } = require("./group_service");

/**
 * Who may manage a group through the central functions: an administrator of
 * the organization manages every group; a group's maintainer (*gestor do
 * grupo*, the `maintainer` role in its `groupMemberships`) manages only
 * that group, and only its people, invites and name. Creating or deleting
 * groups, granting `maintainer` and the organization's settings stay with
 * the administrators.
 */

/**
 * The caller's management access from their memberships.
 *
 * @param {{role?: string}|null} membership - Their organization membership
 * @param {Array<{groupId: string, roles: string[]}>} groupMemberships - Theirs
 * @returns {{admin: boolean, maintainedGroupIds: string[]}|null} null when
 *   they belong to nothing or manage no group
 */
function accessFrom(membership, groupMemberships) {
  if (!membership) return null;
  if (membership.role === "admin") return { admin: true, maintainedGroupIds: [] };
  const maintainedGroupIds = groupMemberships
    .filter((m) => m.roles.includes("maintainer"))
    .map((m) => m.groupId)
    .sort();
  return maintainedGroupIds.length > 0 ? { admin: false, maintainedGroupIds } : null;
}

/** Whether `access` covers group `groupId`. */
function canManageGroup(access, groupId) {
  if (!access) return false;
  return access.admin === true || access.maintainedGroupIds.includes(groupId);
}

/**
 * @throws {GroupError} code `forbidden` (permission-denied) when `access`
 *   does not cover `groupId`
 */
function requireManagesGroup(access, groupId) {
  if (!canManageGroup(access, groupId)) {
    throw new GroupError("forbidden", "Só um administrador ou o gestor do grupo faz isso.");
  }
}

/** The groups `access` sees in `listGroups`: all of them, or the maintained. */
function visibleGroups(access, groups) {
  return groups.filter((g) => canManageGroup(access, g.id));
}

/**
 * Checks a "Convidar pessoas" request against `access`: a maintainer
 * invites only to a group they maintain and never creates the first group.
 *
 * @throws {GroupError} code `forbidden`
 */
function requireMayInvite(access, { groupId, firstGroupName }) {
  if (access?.admin === true) return;
  if (firstGroupName) {
    throw new GroupError("forbidden", "Só um administrador cria grupos.");
  }
  requireManagesGroup(access, groupId);
}

/**
 * The caller's management access in an active organization.
 *
 * @param {(organizationId: unknown) => Promise<{db: FirebaseFirestore.Firestore,
 *   registry: object}|null>} openOrganization - See `organizationOpener`
 * @returns {Promise<{db: FirebaseFirestore.Firestore, admin: boolean,
 *   maintainedGroupIds: string[]}|null>} null when the organization is not
 *   active or the caller manages nothing there
 */
async function managerAccess(openOrganization, organizationId, email) {
  if (!email) return null;
  const organization = await openOrganization(organizationId);
  if (!organization || organization.registry?.status !== "active") return null;
  const { db } = organization;
  const membership = await organizationMembership(db, organizationId, email);
  const memberships =
    membership && membership.role !== "admin"
      ? await personGroupMemberships(db, organizationId, email)
      : [];
  const access = accessFrom(membership, memberships);
  return access && { db, ...access };
}

module.exports = {
  accessFrom,
  canManageGroup,
  managerAccess,
  requireManagesGroup,
  requireMayInvite,
  visibleGroups,
};
