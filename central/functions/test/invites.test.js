const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  InviteError,
  inviteExpiry,
  inviteState,
  validateInvites,
} = require("../invites");

/** Runs `act` and returns the InviteError it throws. */
function inviteErrorOf(act) {
  try {
    act();
  } catch (error) {
    assert.ok(error instanceof InviteError, `expected InviteError, got ${error}`);
    return error;
  }
  assert.fail("expected an InviteError");
}

const person = (email, roles = ["publisher"]) => ({ email, roles });

describe("validateInvites - Unit Test Suite", () => {
  test("Happy Path: trims and lower-cases the e-mail, sorts and dedupes the roles", () => {
    // 1. Arrange
    const invites = [person("  Ana@X.com ", ["subscriber", "publisher", "subscriber"])];

    // 2. Act
    const people = validateInvites(invites);

    // 3. Assert
    assert.deepEqual(people, [{ email: "ana@x.com", roles: ["publisher", "subscriber"] }]);
  });

  test("Edge Case: exactly 50 people are accepted", () => {
    // 1. Arrange
    const invites = Array.from({ length: 50 }, (_, i) => person(`p${i}@x.com`));

    // 2. Act
    const people = validateInvites(invites);

    // 3. Assert
    assert.equal(people.length, 50);
  });

  const fiftyOne = Array.from({ length: 51 }, (_, i) => person(`p${i}@x.com`));
  const rejected = [
    ["not an array", { email: "ana@x.com", roles: ["publisher"] }, "empty"],
    ["null", null, "empty"],
    ["an empty list", [], "empty"],
    ["51 people", fiftyOne, "too_many"],
    ["an e-mail without domain", [person("ana@")], "email"],
    ["an e-mail with a space", [person("ana souza@x.com")], "email"],
    ["a missing e-mail", [{ roles: ["publisher"] }], "email"],
    ["the same e-mail twice, in another case", [person("ana@x.com"), person("ANA@x.com ")], "duplicate"],
    ["no role", [person("ana@x.com", [])], "roles"],
    ["no roles field", [{ email: "ana@x.com" }], "roles"],
    ["an unknown role", [person("ana@x.com", ["publisher", "admin"])], "roles"],
  ];
  for (const [label, invites, code] of rejected) {
    test(`Sad Path: ${label} throws ${code}`, () => {
      // 1. Arrange
      const input = invites;

      // 2. Act
      const error = inviteErrorOf(() => validateInvites(input));

      // 3. Assert
      assert.equal(error.code, code);
    });
  }
});

describe("inviteExpiry - Unit Test Suite", () => {
  test("Happy Path: an invite sent on Oct 26 expires 14 days later, on Nov 9", () => {
    // 1. Arrange
    const now = new Date("2026-10-26T12:00:00Z");

    // 2. Act
    const expiry = inviteExpiry(now);

    // 3. Assert
    assert.equal(expiry.toISOString(), "2026-11-09T12:00:00.000Z");
  });

  test("Edge Case: the 14 days cross the end of the year", () => {
    // 1. Arrange
    const now = new Date("2026-12-25T08:30:00Z");

    // 2. Act
    const expiry = inviteExpiry(now);

    // 3. Assert
    assert.equal(expiry.toISOString(), "2027-01-08T08:30:00.000Z");
  });
});

describe("inviteState - Unit Test Suite", () => {
  const now = new Date("2026-10-27T12:00:00Z");
  const later = new Date("2026-11-09T12:00:00Z");
  const earlier = new Date("2026-10-20T12:00:00Z");
  const cases = [
    ["Happy Path", "pending with a future Date", { status: "pending", expiresAt: later }, "ok"],
    ["Happy Path", "pending with a future ISO string", { status: "pending", expiresAt: later.toISOString() }, "ok"],
    ["Happy Path", "pending with a future Timestamp-like", { status: "pending", expiresAt: { toDate: () => later } }, "ok"],
    ["Happy Path", "cancelled, even before expiring", { status: "cancelled", expiresAt: later }, "cancelled"],
    ["Happy Path", "accepted, even before expiring", { status: "accepted", expiresAt: later }, "accepted"],
    ["Edge Case", "expiring exactly now", { status: "pending", expiresAt: new Date(now) }, "expired"],
    ["Edge Case", "cancelled after expiring", { status: "cancelled", expiresAt: earlier }, "cancelled"],
    ["Sad Path", "past expiry", { status: "pending", expiresAt: earlier }, "expired"],
    ["Sad Path", "past ISO expiry", { status: "pending", expiresAt: earlier.toISOString() }, "expired"],
    ["Sad Path", "no expiry", { status: "pending" }, "expired"],
    ["Sad Path", "no invite at all", undefined, "expired"],
  ];
  for (const [kind, label, invite, state] of cases) {
    test(`${kind}: ${label} is ${state}`, () => {
      // 1. Arrange
      const input = invite;

      // 2. Act
      const result = inviteState(input, now);

      // 3. Assert
      assert.equal(result, state);
    });
  }
});
