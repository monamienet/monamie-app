const { parseGroupAddress } = require("./group_address");

const MAX_TEAMS = 99;
const MIN_NAME = 2;
const MAX_NAME = 40;

/**
 * Error the team functions return as `invalid-argument` (or
 * `failed-precondition` for `full`), with a message for the administrator.
 */
class TeamError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * The comparison form of a team name: no accents, lower case, single
 * spaces, trimmed. "Equipe  Leste" and "equipe léste" are the same team.
 *
 * @param {string} name
 * @returns {string}
 */
function normalizeTeamName(name) {
  return String(name)
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Validates a new (or renamed) team name against the partner's other teams.
 *
 * @param {unknown} name - Requested name
 * @param {string[]} existingNames - Display names of the other teams
 * @returns {string} The name to store: trimmed, inner spaces collapsed
 * @throws {TeamError} code `name` (too short or long, or not text) or
 *   `duplicate` (same name ignoring case, accents and spaces)
 */
function validateTeamName(name, existingNames) {
  if (typeof name !== "string") {
    throw new TeamError("name", "Dê um nome para a equipe.");
  }
  const clean = name.replace(/\s+/g, " ").trim();
  const letters = clean.replace(/[^\p{L}]/gu, "");
  if (letters.length < MIN_NAME) {
    throw new TeamError("name", "Use pelo menos 2 letras.");
  }
  if (clean.length > MAX_NAME) {
    throw new TeamError("name", `Use no máximo ${MAX_NAME} caracteres.`);
  }
  const wanted = normalizeTeamName(clean);
  const clash = existingNames.find((other) => normalizeTeamName(other) === wanted);
  if (clash !== undefined) {
    throw new TeamError("duplicate", `Já existe a equipe ${clash}.`);
  }
  return clean;
}

/**
 * The lowest free team number, "01" to "99".
 *
 * @param {string[]} usedNumbers - Two-digit numbers already taken
 * @returns {string} The next number
 * @throws {TeamError} code `full` when all 99 are taken
 */
function nextTeamNumber(usedNumbers) {
  const used = new Set(usedNumbers);
  for (let n = 1; n <= MAX_TEAMS; n++) {
    const team = String(n).padStart(2, "0");
    if (!used.has(team)) return team;
  }
  throw new TeamError("full", `A organização já tem ${MAX_TEAMS} equipes, o máximo.`);
}

/**
 * The three groups of a team: the team itself and its two leaves.
 *
 * @param {string} partnerId
 * @param {string} team - Two-digit number
 * @returns {{team: string, watch: string, share: string}} Group e-mails
 */
function teamGroupEmails(partnerId, team) {
  const key = `${partnerId}${team}`;
  return {
    team: `${key}@monamienet.org`,
    watch: `${key}r@monamienet.org`,
    share: `${key}w@monamienet.org`,
  };
}

/**
 * The roles a person should have, validated: one or both of "share"
 * (*Em campo*) and "watch" (*Vê o mapa*), never none.
 *
 * @param {unknown} roles
 * @returns {Array<"share"|"watch">} Sorted, without duplicates
 * @throws {TeamError} code `roles`
 */
function validateRoles(roles) {
  if (!Array.isArray(roles)) {
    throw new TeamError("roles", "Escolha pelo menos um papel.");
  }
  const set = new Set(roles);
  for (const role of set) {
    if (role !== "share" && role !== "watch") {
      throw new TeamError("roles", `Papel desconhecido: ${role}.`);
    }
  }
  if (set.size === 0) {
    throw new TeamError("roles", "Escolha pelo menos um papel.");
  }
  return [...set].sort();
}

/**
 * The membership changes that give a person exactly `wanted` roles in a
 * team, starting from `current`.
 *
 * @param {string[]} current - Roles now ("share", "watch")
 * @param {string[]} wanted - Validated roles
 * @returns {{add: string[], remove: string[]}} Roles to add and remove
 */
function roleChanges(current, wanted) {
  const now = new Set(current);
  const next = new Set(wanted);
  return {
    add: [...next].filter((r) => !now.has(r)).sort(),
    remove: [...now].filter((r) => !next.has(r)).sort(),
  };
}

/**
 * Who loses access to the partner if `teamKey` is deleted: the people of
 * that team who are in no other team of the partner and do not administer it.
 *
 * @param {string} teamKey - e.g. "rotasul01"
 * @param {Map<string, string[]>} groupsByPerson - Each person's leaf (and
 *   root) group e-mails in the partner
 * @returns {{loses: string[], stays: string[]}} Sorted e-mails
 */
function whoLosesAccess(teamKey, groupsByPerson) {
  const loses = [];
  const stays = [];
  for (const [email, groups] of groupsByPerson) {
    const addresses = groups.map(parseGroupAddress).filter(Boolean);
    if (!addresses.some((a) => a.teamKey === teamKey && a.level === 2)) continue;
    const elsewhere = addresses.some(
      (a) => a.level === 0 || (a.level === 2 && a.teamKey !== teamKey)
    );
    (elsewhere ? stays : loses).push(email);
  }
  return { loses: loses.sort(), stays: stays.sort() };
}

module.exports = {
  MAX_TEAMS,
  TeamError,
  nextTeamNumber,
  normalizeTeamName,
  roleChanges,
  teamGroupEmails,
  validateRoles,
  validateTeamName,
  whoLosesAccess,
};
