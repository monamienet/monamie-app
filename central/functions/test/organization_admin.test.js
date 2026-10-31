const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { administeredOrganization } = require("../organization_admin");
const { personKey } = require("../person_key");
const { fakeFirestore } = require("./fake_firestore");

const OLGA = "olga@x.com";

/** An opener for organization `rotasul` with `status`, whose project holds `docs`. */
function opener(docs, status = "active") {
  const db = fakeFirestore(docs);
  return {
    db,
    open: async (id) => (id === "rotasul" ? { db, registry: { status } } : null),
  };
}

const membership = (email, role) => ({
  [`organizations/rotasul/organizationMemberships/${personKey(email)}`]: { email, role },
});

describe("administeredOrganization - Unit Test Suite", () => {
  test("Happy Path: an admin membership of an active organization gives its Firestore", async () => {
    // 1. Arrange
    const { db, open } = opener(membership(OLGA, "admin"));

    // 2. Act
    const result = await administeredOrganization(open, "rotasul", OLGA);

    // 3. Assert
    assert.equal(result, db);
  });

  test("Edge Case: the e-mail is matched ignoring case", async () => {
    // 1. Arrange
    const { db, open } = opener(membership(OLGA, "admin"));

    // 2. Act
    const result = await administeredOrganization(open, "rotasul", "Olga@X.com");

    // 3. Assert
    assert.equal(result, db);
  });

  const refused = [
    ["a plain member", membership(OLGA, "member"), "active", "rotasul"],
    ["someone without a membership", {}, "active", "rotasul"],
    ["an administrator of a deleting organization", membership(OLGA, "admin"), "deleting", "rotasul"],
    ["an organization missing from the registry", membership(OLGA, "admin"), "active", "outro"],
  ];
  for (const [label, docs, status, id] of refused) {
    test(`Sad Path: ${label} is not an administrator`, async () => {
      // 1. Arrange
      const { open } = opener(docs, status);

      // 2. Act
      const result = await administeredOrganization(open, id, OLGA);

      // 3. Assert
      assert.equal(result, null);
    });
  }
});
