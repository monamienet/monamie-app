const DAY_MS = 24 * 60 * 60 * 1000;

/** Invites expire after 14 days; "Reenviar" starts a new 14-day period. */
const INVITE_TTL_MS = 14 * DAY_MS;

/** At most this many people per "Convidar pessoas" send. */
const MAX_INVITES_PER_SEND = 50;

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

class InviteError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * Validates the people of one send: e-mails (normalized to lower case and
 * trimmed, no duplicates) and roles (one or both of share/watch, never
 * none).
 *
 * @param {unknown} invites - `[{email, roles}]`
 * @returns {Array<{email: string, roles: string[]}>}
 * @throws {InviteError} code `empty`, `too_many`, `email`, `duplicate` or
 *   `roles` (messages for the administrator)
 */
function validateInvites(invites) {
  if (!Array.isArray(invites) || invites.length === 0) {
    throw new InviteError("empty", "Adicione pelo menos uma pessoa.");
  }
  if (invites.length > MAX_INVITES_PER_SEND) {
    throw new InviteError(
      "too_many",
      `Envie no máximo ${MAX_INVITES_PER_SEND} convites por vez.`
    );
  }
  const seen = new Set();
  return invites.map((invite) => {
    const email = String(invite?.email ?? "").trim().toLowerCase();
    if (!EMAIL.test(email)) {
      throw new InviteError("email", `E-mail inválido: ${invite?.email ?? ""}`);
    }
    if (seen.has(email)) {
      throw new InviteError("duplicate", `${email} aparece duas vezes.`);
    }
    seen.add(email);
    const roles = [...new Set(Array.isArray(invite.roles) ? invite.roles : [])];
    if (roles.length === 0 || roles.some((r) => r !== "share" && r !== "watch")) {
      throw new InviteError("roles", `Marque pelo menos uma opção para ${email}.`);
    }
    return { email, roles: roles.sort() };
  });
}

/**
 * When an invite sent (or resent) at `now` expires.
 *
 * @param {Date} now
 * @returns {Date}
 */
function inviteExpiry(now) {
  return new Date(now.getTime() + INVITE_TTL_MS);
}

/** A Date, ISO text or Firestore Timestamp as a valid Date, else null. */
function toDate(raw) {
  const at =
    raw instanceof Date
      ? raw
      : typeof raw === "string"
        ? new Date(raw)
        : raw?.toDate?.() ?? null;
  return at && !Number.isNaN(at.getTime()) ? at : null;
}

/**
 * Whether `invite` can still be accepted at `now`: pending and not expired.
 *
 * @param {{status?: string, expiresAt?: Date|string|{toDate(): Date}}} invite
 * @param {Date} now
 * @returns {"ok"|"expired"|"cancelled"|"accepted"}
 */
function inviteState(invite, now) {
  if (invite?.status === "cancelled") return "cancelled";
  if (invite?.status === "accepted") return "accepted";
  const at = toDate(invite?.expiresAt);
  if (!at || at.getTime() <= now.getTime()) return "expired";
  return "ok";
}

/**
 * Whether `invite` was sent before its team's group was created, that is,
 * to an earlier team that was deleted and whose number was then reused
 * (`nextTeamNumber` hands out the lowest free one). An unreadable time
 * counts as older, so such an invite is refused.
 *
 * @param {{createdAt?: Date|string|{toDate(): Date}}} invite
 * @param {string|Date|undefined} teamCreateTime - The team group's
 *   `createTime` (Cloud Identity)
 * @returns {boolean}
 */
function predatesTeam(invite, teamCreateTime) {
  const sent = toDate(invite?.createdAt);
  const created = toDate(teamCreateTime);
  return !sent || !created || sent.getTime() < created.getTime();
}

module.exports = {
  INVITE_TTL_MS,
  InviteError,
  MAX_INVITES_PER_SEND,
  inviteExpiry,
  inviteState,
  predatesTeam,
  validateInvites,
};
