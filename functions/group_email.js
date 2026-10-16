/**
 * Normalizes a group email to its canonical form (trimmed, lowercase).
 *
 * Google Workspace returns subgroup emails from `/members` capitalized like
 * the group's display name (e.g. "AquariusTur01@..."), while `/groups`
 * returns the lowercase canonical form. Firestore Rules compare map keys
 * case-sensitively, so claims must always use the normalized form.
 *
 * @param {string} email - Group email
 * @returns {string} Normalized email
 * @throws {TypeError} If `email` is not a string
 */
function normalizeGroupEmail(email) {
  if (typeof email !== "string") {
    throw new TypeError("Group email must be a string.");
  }
  return email.trim().toLowerCase();
}

module.exports = { normalizeGroupEmail };
