const { describe, test, before } = require("node:test");
const assert = require("node:assert/strict");

const { personKey } = require("../person_key");

// setBranding reads and writes through `firebase-admin`; the module is
// replaced in the require cache by an in-memory Firestore before index.js
// loads, so the administrator check runs without a project.
const docs = new Map();
const fakeAdmin = {
  initializeApp() {},
  firestore: () => ({
    doc: (path) => ({
      async get() {
        const data = docs.get(path);
        return { exists: data !== undefined, get: (field) => data?.[field] };
      },
      async set(data, options) {
        docs.set(path, { ...(options?.merge ? docs.get(path) : {}), ...data });
      },
    }),
  }),
};
const adminPath = require.resolve("firebase-admin");
require.cache[adminPath] = { id: adminPath, filename: adminPath, loaded: true, exports: fakeAdmin };

const OLGA = "olga@x.com";
const membershipPath = (email) => `organizations/rotasul/organizationMemberships/${personKey(email)}`;
const BRANDING = "organizations/rotasul/config/branding";

/** A callable request from `email` (verified unless told otherwise). */
function request(email, data = { organizationId: "rotasul", name: "Rota Sul Turismo" }, verified = true) {
  return { auth: { uid: "u1", token: { email, email_verified: verified } }, data };
}

async function codeOf(act) {
  try {
    await act();
  } catch (error) {
    return error.code;
  }
  assert.fail("expected an HttpsError");
}

describe("setBranding (administrator check) - Unit Test Suite", () => {
  let setBranding;
  before(() => {
    ({ setBranding } = require("../index"));
  });

  const reset = (memberships) => {
    docs.clear();
    for (const [email, role] of Object.entries(memberships)) docs.set(membershipPath(email), { email, role });
  };

  test("Happy Path: an administrator's change is written to the branding", async () => {
    // 1. Arrange
    reset({ [OLGA]: "admin" });

    // 2. Act
    await setBranding.run(request(OLGA));

    // 3. Assert
    assert.equal(docs.get(BRANDING).name, "Rota Sul Turismo");
  });

  test("Edge Case: the e-mail of the token is matched ignoring case", async () => {
    // 1. Arrange
    reset({ [OLGA]: "admin" });

    // 2. Act
    await setBranding.run(request("Olga@X.com"));

    // 3. Assert
    assert.equal(docs.get(BRANDING).name, "Rota Sul Turismo");
  });

  const refused = [
    ["a plain member", { [OLGA]: "member" }, request(OLGA)],
    ["someone without a membership", {}, request(OLGA)],
    ["an administrator with an unverified e-mail", { [OLGA]: "admin" }, request(OLGA, undefined, false)],
    [
      "an administrator of another organization",
      { [OLGA]: "admin" },
      request(OLGA, { organizationId: "outro", name: "Outro" }),
    ],
    [
      "a malformed organization id",
      { [OLGA]: "admin" },
      request(OLGA, { organizationId: "rotasul/x", name: "Rota" }),
    ],
  ];
  for (const [label, memberships, call] of refused) {
    test(`Sad Path: ${label} is refused with permission-denied and nothing is written`, async () => {
      // 1. Arrange
      reset(memberships);

      // 2. Act
      const code = await codeOf(() => setBranding.run(call));

      // 3. Assert
      assert.deepEqual([code, [...docs.keys()].some((p) => p.endsWith("/config/branding"))], ["permission-denied", false]);
    });
  }

  test("Sad Path: a call without sign-in is refused with unauthenticated", async () => {
    // 1. Arrange
    reset({ [OLGA]: "admin" });

    // 2. Act
    const code = await codeOf(() => setBranding.run({ data: { organizationId: "rotasul", name: "Rota" } }));

    // 3. Assert
    assert.equal(code, "unauthenticated");
  });
});
