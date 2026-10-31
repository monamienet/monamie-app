const PLAY_URL = "https://play.google.com/store/apps/details?id=org.monamienet.app";
const GMAIL_SEND_SCOPE = "https://www.googleapis.com/auth/gmail.send";

const MONTHS = [
  "janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho",
  "agosto", "setembro", "outubro", "novembro", "dezembro",
];

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * The invite e-mail of the canvas (*E-mail de convite*), in pt-BR. It uses
 * the organization's name; MonAmie appears only as the app to install (#89).
 *
 * @param {{organizationName: string, teamName: string, invitedByName: string,
 *   invitedByEmail: string, email: string, roles: string[],
 *   expiresAt: Date}} invite
 * @returns {{subject: string, text: string, html: string}}
 */
function inviteEmail(invite) {
  const shares = invite.roles.includes("share");
  const lines = [
    ...(shares ? ["Compartilhar sua localização com a equipe"] : []),
    ...(invite.roles.includes("watch") ? ["Ver no mapa quem está em campo"] : []),
  ];
  const until = `${invite.expiresAt.getUTCDate()} de ${MONTHS[invite.expiresAt.getUTCMonth()]}`;
  const privacy = shares
    ? "Sua localização só é compartilhada depois que você ativar no app, e você pode desligar quando quiser. "
    : "";
  const subject = `${invite.invitedByName} convidou você para a ${invite.organizationName}`;
  const text = [
    `${invite.invitedByName} chamou você para a ${invite.teamName} da ${invite.organizationName}.`,
    "",
    "No app, você vai:",
    ...lines.map((l) => `- ${l}`),
    "",
    `1. Instale o app MonAmie: ${PLAY_URL}`,
    `2. Entre com ${invite.email}, a conta que recebeu este convite, e toque em "Aceitar e entrar".`,
    "",
    `${privacy}O convite vale até ${until}.`,
    "",
    `Você recebeu este e-mail porque ${invite.invitedByEmail} convidou ${invite.email}. Se não reconhece o convite, é só ignorar.`,
  ].join("\n");
  const html = `<div style="font-family:system-ui,sans-serif;color:#1B1838;max-width:520px">
<h2>${escapeHtml(invite.organizationName)}</h2>
<p><strong>${escapeHtml(invite.invitedByName)}</strong> chamou você para a <strong>${escapeHtml(invite.teamName)}</strong> da ${escapeHtml(invite.organizationName)}.</p>
<p><strong>No app, você vai</strong></p><ul>${lines.map((l) => `<li>${escapeHtml(l)}</li>`).join("")}</ul>
<p><a href="${PLAY_URL}" style="display:inline-block;padding:14px 22px;border-radius:14px;background:#0B7F7B;color:#fff;text-decoration:none;font-weight:800">Aceitar convite</a></p>
<ol><li>Instale o app MonAmie (o botão leva até a loja, se precisar).</li><li>Entre com <strong>${escapeHtml(invite.email)}</strong>, a conta que recebeu este convite.</li></ol>
<p style="color:#4A4858">${escapeHtml(privacy)}O convite vale até ${until}.</p>
<p style="color:#4A4858;font-size:12px">Você recebeu este e-mail porque ${escapeHtml(invite.invitedByEmail)} convidou ${escapeHtml(invite.email)}. Se não reconhece o convite, é só ignorar.</p>
</div>`;
  return { subject, text, html };
}

/** RFC 2047 encoding of a header with non-ASCII text. */
function encodeHeader(text) {
  return /^[\x20-\x7e]*$/.test(text)
    ? text
    : `=?UTF-8?B?${Buffer.from(text, "utf8").toString("base64")}?=`;
}

/**
 * The raw (base64url) MIME message the Gmail API sends.
 *
 * @param {{from: string, fromName: string, to: string, subject: string,
 *   text: string, html: string}} message
 * @returns {string}
 */
function rawMessage(message) {
  const boundary = "monamie-boundary";
  const mime = [
    `From: ${encodeHeader(message.fromName)} <${message.from}>`,
    `To: ${message.to}`,
    `Subject: ${encodeHeader(message.subject)}`,
    "MIME-Version: 1.0",
    `Content-Type: multipart/alternative; boundary="${boundary}"`,
    "",
    `--${boundary}`,
    'Content-Type: text/plain; charset="UTF-8"',
    "Content-Transfer-Encoding: base64",
    "",
    Buffer.from(message.text, "utf8").toString("base64"),
    `--${boundary}`,
    'Content-Type: text/html; charset="UTF-8"',
    "Content-Transfer-Encoding: base64",
    "",
    Buffer.from(message.html, "utf8").toString("base64"),
    `--${boundary}--`,
  ].join("\r\n");
  return Buffer.from(mime, "utf8").toString("base64url");
}

/**
 * Sends e-mail through the Workspace Gmail API as `subject` (a mailbox
 * whose send-as alias is `from`), by domain-wide delegation of
 * gmail.send to `senderServiceAccount`. Keyless: the delegation JWT is
 * signed with the IAM Credentials API by the function's own identity
 * (roles/iam.serviceAccountTokenCreator on the sender account).
 *
 * Delegation is domain-wide in Workspace; this code only ever uses the one
 * configured `subject`.
 */
class GmailMailer {
  /**
   * @param {{request: (options: object) => Promise<any>,
   *   senderServiceAccount: string, subject: string, from: string,
   *   fromName: string}} options - `request` is an authorized request of
   *   the function's identity, resolving to the response body
   */
  constructor({ request, senderServiceAccount, subject, from, fromName }) {
    this._request = request;
    this._sa = senderServiceAccount;
    this._subject = subject;
    this._from = from;
    this._fromName = fromName;
  }

  async _accessToken() {
    const now = Math.floor(Date.now() / 1000);
    const { signedJwt } = await this._request({
      url: `https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${this._sa}:signJwt`,
      method: "POST",
      data: {
        payload: JSON.stringify({
          iss: this._sa,
          sub: this._subject,
          scope: GMAIL_SEND_SCOPE,
          aud: "https://oauth2.googleapis.com/token",
          iat: now,
          exp: now + 600,
        }),
      },
    });
    const response = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: signedJwt,
      }),
    });
    if (!response.ok) {
      throw new Error(`Gmail delegation refused (${response.status}).`);
    }
    return (await response.json()).access_token;
  }

  /** Sends `{to, subject, text, html}`. */
  async send({ to, subject, text, html }) {
    const token = await this._accessToken();
    const response = await fetch(
      "https://gmail.googleapis.com/gmail/v1/users/me/messages/send",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          raw: rawMessage({
            from: this._from,
            fromName: this._fromName,
            to,
            subject,
            text,
            html,
          }),
        }),
      }
    );
    if (!response.ok) throw new Error(`Gmail answered ${response.status}.`);
  }
}

module.exports = { GmailMailer, PLAY_URL, inviteEmail, rawMessage };
