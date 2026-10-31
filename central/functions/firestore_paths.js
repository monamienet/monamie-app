/**
 * The Firestore collection and document names the central functions use, in
 * one place, so a rename cannot miss one. The app (`FirestorePaths` in
 * lib/app/data/firebase/firestore_paths.dart), the organization functions
 * (functions/firestore_paths.js) and the rules use the same names.
 */

/** The central registry, and each organization's data in its project. */
const ORGANIZATIONS = "organizations";
/** Ids that can never be used again (central project). */
const RETIRED_ORGANIZATION_IDS = "retiredOrganizationIds";
/** Pending invites (central project). */
const INVITES = "invites";
/** Scheduled account deletions, keyed by e-mail (central project). */
const ACCOUNT_DELETIONS = "accountDeletions";
/** An organization's `config/branding`, `config/plan`, `config/tracking`. */
const CONFIG = "config";
const BRANDING = "branding";
const PLAN = "plan";
/** A person's last position in an organization, keyed by e-mail. */
const POSITIONS = "positions";

/** `organizations/{id}`: a registry entry, or an organization's data root. */
function organizationPath(id) {
  return `${ORGANIZATIONS}/${id}`;
}

/** `retiredOrganizationIds/{id}`. */
function retiredOrganizationPath(id) {
  return `${RETIRED_ORGANIZATION_IDS}/${id}`;
}

module.exports = {
  ACCOUNT_DELETIONS,
  BRANDING,
  CONFIG,
  INVITES,
  ORGANIZATIONS,
  PLAN,
  POSITIONS,
  RETIRED_ORGANIZATION_IDS,
  organizationPath,
  retiredOrganizationPath,
};
