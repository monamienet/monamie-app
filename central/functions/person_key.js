const crypto = require("node:crypto");

/**
 * The key of a person's documents (`organizationMemberships/{key}`,
 * `groupMemberships/{key}`, `positions/{key}`, `accounts/{key}`,
 * `accountDeletions/{key}`): the lowercase-hex SHA-256 of the trimmed,
 * lowercased e-mail, so no e-mail appears in a document name. The rules
 * compute the same with `hashing.sha256(...)`, and the app and tool/ with
 * `personKey()` in Dart.
 *
 * @param {string} email
 * @returns {string} 64 hex characters
 */
function personKey(email) {
  return crypto
    .createHash("sha256")
    .update(String(email).trim().toLowerCase(), "utf8")
    .digest("hex");
}

module.exports = { personKey };
