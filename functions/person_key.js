const crypto = require("node:crypto");

/**
 * The key of a person's documents (`organizationMemberships/{key}`,
 * `groupMemberships/{key}`, `positions/{key}`): the lowercase-hex SHA-256
 * of the trimmed, lowercased e-mail. Twin of central/functions/person_key.js;
 * the rules compute the same with `hashing.sha256(...)`.
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
