/**
 * The Firestore collection and document names the central functions use, in
 * one place, so a rename cannot miss one. The app (`FirestorePaths` in
 * lib/app/data/firebase/firestore_paths.dart), the organization functions
 * (functions/firestore_paths.js) and the rules use the same names.
 *
 * A person's documents are keyed by `personKey(email)` (person_key.js).
 */

/** The central registry, and each organization's data in its project. */
const ORGANIZATIONS = "organizations";
/** Ids that can never be used again (central project). */
const RETIRED_ORGANIZATION_IDS = "retiredOrganizationIds";
/** Pending invites (central project). */
const INVITES = "invites";
/** Scheduled account deletions, keyed by personKey (central project). */
const ACCOUNT_DELETIONS = "accountDeletions";
/** Each person's organizations, keyed by personKey (central project). */
const ACCOUNTS = "accounts";
/** An organization's `config/branding`, `config/plan`, `config/tracking`. */
const CONFIG = "config";
const BRANDING = "branding";
const PLAN = "plan";
/** Who belongs to an organization, with their role (organization project). */
const ORGANIZATION_MEMBERSHIPS = "organizationMemberships";
/** An organization's groups (organization project). */
const GROUPS = "groups";
/** Who belongs to a group, with their roles (under a group). */
const GROUP_MEMBERSHIPS = "groupMemberships";
/** A person's last position in a group (under a group). */
const POSITIONS = "positions";

/** `organizations/{id}`: a registry entry, or an organization's data root. */
function organizationPath(id) {
  return `${ORGANIZATIONS}/${id}`;
}

/** `retiredOrganizationIds/{id}`. */
function retiredOrganizationPath(id) {
  return `${RETIRED_ORGANIZATION_IDS}/${id}`;
}

/** `accounts/{personKey}` (central project). */
function accountPath(key) {
  return `${ACCOUNTS}/${key}`;
}

/** `accountDeletions/{personKey}` (central project). */
function accountDeletionPath(key) {
  return `${ACCOUNT_DELETIONS}/${key}`;
}

/** `organizations/{id}/organizationMemberships/{personKey}`. */
function organizationMembershipPath(organizationId, key) {
  return `${organizationPath(organizationId)}/${ORGANIZATION_MEMBERSHIPS}/${key}`;
}

/** `organizations/{id}/groups/{groupId}`. */
function groupPath(organizationId, groupId) {
  return `${organizationPath(organizationId)}/${GROUPS}/${groupId}`;
}

/** `organizations/{id}/groups/{groupId}/groupMemberships/{personKey}`. */
function groupMembershipPath(organizationId, groupId, key) {
  return `${groupPath(organizationId, groupId)}/${GROUP_MEMBERSHIPS}/${key}`;
}

/** `organizations/{id}/groups/{groupId}/positions/{personKey}`. */
function groupPositionPath(organizationId, groupId, key) {
  return `${groupPath(organizationId, groupId)}/${POSITIONS}/${key}`;
}

module.exports = {
  ACCOUNTS,
  ACCOUNT_DELETIONS,
  BRANDING,
  CONFIG,
  GROUPS,
  GROUP_MEMBERSHIPS,
  INVITES,
  ORGANIZATIONS,
  ORGANIZATION_MEMBERSHIPS,
  PLAN,
  POSITIONS,
  RETIRED_ORGANIZATION_IDS,
  accountDeletionPath,
  accountPath,
  groupMembershipPath,
  groupPath,
  groupPositionPath,
  organizationMembershipPath,
  organizationPath,
  retiredOrganizationPath,
};
