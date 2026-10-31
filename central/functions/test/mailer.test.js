const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { inviteEmail, rawMessage } = require("../mailer");

const SHARE_LINE = "Compartilhar sua localização com a equipe";
const WATCH_LINE = "Ver no mapa quem está em campo";
const PRIVACY = "Sua localização só é compartilhada";

/** Rita invites ana to Equipe Norte of Rota Sul, valid until Nov 9. */
function invite(overrides = {}) {
  return {
    organizationName: "Rota Sul",
    teamName: "Equipe Norte",
    invitedByName: "Rita Lima",
    invitedByEmail: "dono@x.com",
    email: "ana@x.com",
    roles: ["share"],
    expiresAt: new Date("2026-11-09T12:00:00Z"),
    ...overrides,
  };
}

/** The decoded header block of a raw message. */
function headersOf(raw) {
  const mime = Buffer.from(raw, "base64url").toString("utf8");
  return mime.split("\r\n\r\n")[0].split("\r\n");
}

describe("inviteEmail - Unit Test Suite", () => {
  test("Happy Path: the subject names who invited and the organization", () => {
    // 1. Arrange
    const data = invite();

    // 2. Act
    const { subject } = inviteEmail(data);

    // 3. Assert
    assert.equal(subject, "Rita Lima convidou você para a Rota Sul");
  });

  test("Happy Path: the text mentions the team", () => {
    // 1. Arrange
    const data = invite();

    // 2. Act
    const { text } = inviteEmail(data);

    // 3. Assert
    assert.match(text, /Equipe Norte/);
  });

  test("Happy Path: the text says until when the invite is valid", () => {
    // 1. Arrange
    const data = invite();

    // 2. Act
    const { text } = inviteEmail(data);

    // 3. Assert
    assert.ok(text.includes("O convite vale até 9 de novembro"), text);
  });

  const byRoles = [
    ["Happy Path", ["share"], { share: true, watch: false, privacy: true }],
    ["Edge Case", ["watch"], { share: false, watch: true, privacy: false }],
    ["Edge Case", ["share", "watch"], { share: true, watch: true, privacy: true }],
  ];
  for (const [kind, roles, expected] of byRoles) {
    test(`${kind}: with roles ${roles.join("+")} the text lists only what the person will do`, () => {
      // 1. Arrange
      const data = invite({ roles });

      // 2. Act
      const { text } = inviteEmail(data);

      // 3. Assert
      assert.deepEqual(
        {
          share: text.includes(SHARE_LINE),
          watch: text.includes(WATCH_LINE),
          privacy: text.includes(PRIVACY),
        },
        expected
      );
    });
  }

  test("Edge Case: an invite valid until Jan 1 says 1 de janeiro", () => {
    // 1. Arrange
    const data = invite({ expiresAt: new Date("2027-01-01T12:00:00Z") });

    // 2. Act
    const { text } = inviteEmail(data);

    // 3. Assert
    assert.ok(text.includes("O convite vale até 1 de janeiro"), text);
  });

  test("Sad Path: the HTML escapes <, >, & and \" in the names", () => {
    // 1. Arrange
    const data = invite({
      organizationName: 'A&B <Ltda> "Sul"',
      invitedByName: "<script>x</script>",
      teamName: "Equipe <b>",
    });

    // 2. Act
    const { html } = inviteEmail(data);

    // 3. Assert
    assert.ok(html.includes("A&amp;B &lt;Ltda&gt; &quot;Sul&quot;"), html);
    assert.ok(html.includes("&lt;script&gt;x&lt;/script&gt;"), html);
    assert.ok(html.includes("Equipe &lt;b&gt;"), html);
    assert.ok(!html.includes("<script>"), html);
    assert.ok(!html.includes("<Ltda>"), html);
  });
});

describe("rawMessage - Unit Test Suite", () => {
  const message = (overrides = {}) => ({
    from: "convites@monamienet.org",
    fromName: "Rota Sul",
    to: "ana@x.com",
    subject: "Convite",
    text: "Olá",
    html: "<p>Olá</p>",
    ...overrides,
  });

  test("Happy Path: the decoded headers carry To and From with the sender's name", () => {
    // 1. Arrange
    const input = message();

    // 2. Act
    const raw = rawMessage(input);

    // 3. Assert
    const headers = headersOf(raw);
    assert.ok(headers.includes("To: ana@x.com"), headers.join("\n"));
    assert.ok(headers.includes("From: Rota Sul <convites@monamienet.org>"), headers.join("\n"));
  });

  test("Edge Case: a non-ASCII subject is encoded as =?UTF-8?B?...?=", () => {
    // 1. Arrange
    const subject = "Rita Lima convidou você para a Rota Sul";
    const input = message({ subject });

    // 2. Act
    const raw = rawMessage(input);

    // 3. Assert
    const line = headersOf(raw).find((h) => h.startsWith("Subject: "));
    const encoded = /^Subject: =\?UTF-8\?B\?([A-Za-z0-9+/=]+)\?=$/.exec(line);
    assert.ok(encoded, line);
    assert.equal(Buffer.from(encoded[1], "base64").toString("utf8"), subject);
  });

  test("Edge Case: the output is base64url (no +, / or padding)", () => {
    // 1. Arrange
    const input = message({ subject: "Ação ???>>>", text: "ÿÿÿ>>>???" });

    // 2. Act
    const raw = rawMessage(input);

    // 3. Assert
    assert.match(raw, /^[A-Za-z0-9_-]+$/);
  });
});
