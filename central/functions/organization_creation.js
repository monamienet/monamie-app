const { isValidOrganizationId } = require("./organization_id");

const MAX_ID_LENGTH = 20;
const PLANS = new Set(["community", "standard"]);

/** Community organizations may send a position at most every 15 minutes. */
const COMMUNITY_MIN_INTERVAL_MINUTES = 15;

class CreationError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * The identifier suggested for an organization name: its letters only,
 * without accents, lower case, at most 20 ("Rota Sul Turismo" →
 * "rotasulturismo"). The person may edit it before creating.
 *
 * @param {string} name
 * @returns {string}
 */
function suggestOrganizationId(name) {
  return String(name)
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z]/g, "")
    .slice(0, MAX_ID_LENGTH);
}

/**
 * Why `id` cannot be a new organization's identifier (format only), or
 * null. Availability (taken or retired) is checked against the registry.
 *
 * @param {unknown} id
 * @returns {string|null}
 */
function organizationIdFormatProblem(id) {
  if (typeof id !== "string" || !/^[a-z]+$/.test(id)) {
    return "Use só letras minúsculas, sem acentos nem espaços.";
  }
  if (id.length < 3) return "Use pelo menos 3 letras.";
  if (id.length > MAX_ID_LENGTH) return `Use no máximo ${MAX_ID_LENGTH} letras.`;
  if (!isValidOrganizationId(id)) return "Esse identificador é reservado.";
  return null;
}

/**
 * Validates a creation request: identifier format, name (2–40 characters,
 * never "MonAmie …"), theme among the active ones, plan.
 *
 * @param {object} input - `{id, name, themeId, plan}`
 * @param {Set<string>} activeThemeIds
 * @returns {{id: string, name: string, themeId: string, plan: string}}
 * @throws {CreationError} code `id`, `name`, `themeId` or `plan`
 */
function validateCreation(input, activeThemeIds) {
  const idProblem = organizationIdFormatProblem(input?.id);
  if (idProblem) throw new CreationError("id", idProblem);
  const name = String(input?.name ?? "").trim().replace(/\s+/g, " ");
  if (name.length < 2 || name.length > 40) {
    throw new CreationError("name", "O nome precisa ter de 2 a 40 caracteres.");
  }
  if (/^monamie\s/i.test(name)) {
    throw new CreationError("name", 'O nome não pode começar com "MonAmie".');
  }
  if (!activeThemeIds.has(input?.themeId)) {
    throw new CreationError("themeId", "Escolha um dos temas.");
  }
  if (!PLANS.has(input?.plan)) {
    throw new CreationError("plan", "Escolha o plano.");
  }
  return { id: input.id, name, themeId: input.themeId, plan: input.plan };
}

module.exports = {
  COMMUNITY_MIN_INTERVAL_MINUTES,
  CreationError,
  organizationIdFormatProblem,
  suggestOrganizationId,
  validateCreation,
};
