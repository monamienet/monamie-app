const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { isPartnerAdmin } = require("../partner_admin");

const EMAIL = "ana@x.com";
const ROOT = "rotasul00@monamienet.org";

/** An in-memory Firestore with `doc(path).get()` only. */
function fakeFirestore(docs = {}) {
  return {
    doc: (path) => ({
      async get() {
        const data = docs[path];
        return { exists: data !== undefined, get: (field) => data?.[field] };
      },
    }),
  };
}

/**
 * A GroupsApi where `groups` maps each existing group e-mail to its direct
 * members. A group's resource name is `groups/<e-mail>`.
 */
function fakeGroups(groups = {}) {
  const calls = [];
  return {
    calls,
    async lookup(email) {
      calls.push(["lookup", email]);
      return email in groups ? `groups/${email}` : null;
    },
    async isMember(name, email) {
      calls.push(["isMember", name, email]);
      const members = groups[name.replace(/^groups\//, "")] ?? [];
      return members.includes(email);
    },
  };
}

const activeRegistry = (overrides = {}) => ({
  "partners/rotasul": { status: "active", ownerEmail: "bia@x.com", ...overrides },
});

describe("isPartnerAdmin - Unit Test Suite", () => {
  test("Happy Path: a direct member of the root group of an active partner is an administrator", async () => {
    // 1. Arrange
    const db = fakeFirestore(activeRegistry());
    const groups = fakeGroups({ [ROOT]: [EMAIL] });

    // 2. Act
    const result = await isPartnerAdmin(db, groups, "rotasul", EMAIL);

    // 3. Assert
    assert.equal(result, true);
  });

  test("Edge Case: the e-mail is lower-cased before checking the membership", async () => {
    // 1. Arrange
    const db = fakeFirestore(activeRegistry());
    const groups = fakeGroups({ [ROOT]: [EMAIL] });

    // 2. Act
    const result = await isPartnerAdmin(db, groups, "rotasul", "Ana@X.com");

    // 3. Assert
    assert.equal(result, true);
    assert.deepEqual(groups.calls.at(-1), ["isMember", `groups/${ROOT}`, EMAIL]);
  });

  test("Edge Case: an administrator without ownerEmail in the registry is still an administrator", async () => {
    // 1. Arrange
    const db = fakeFirestore(activeRegistry({ ownerEmail: undefined }));
    const groups = fakeGroups({ [ROOT]: [EMAIL] });

    // 2. Act
    const result = await isPartnerAdmin(db, groups, "rotasul", EMAIL);

    // 3. Assert
    assert.equal(result, true);
  });

  test("Edge Case: the owner who is not in the root group is not an administrator", async () => {
    // 1. Arrange
    const db = fakeFirestore(activeRegistry({ ownerEmail: EMAIL }));
    const groups = fakeGroups({ [ROOT]: ["bia@x.com"] });

    // 2. Act
    const result = await isPartnerAdmin(db, groups, "rotasul", EMAIL);

    // 3. Assert
    assert.equal(result, false);
  });

  test("Sad Path: a person who is not in the root group is not an administrator", async () => {
    // 1. Arrange
    const db = fakeFirestore(activeRegistry());
    const groups = fakeGroups({ [ROOT]: ["bia@x.com"] });

    // 2. Act
    const result = await isPartnerAdmin(db, groups, "rotasul", EMAIL);

    // 3. Assert
    assert.equal(result, false);
  });

  test("Sad Path: a partner without a root group has no administrators", async () => {
    // 1. Arrange
    const db = fakeFirestore(activeRegistry());
    const groups = fakeGroups({});

    // 2. Act
    const result = await isPartnerAdmin(db, groups, "rotasul", EMAIL);

    // 3. Assert
    assert.equal(result, false);
  });

  test("Sad Path: a partner missing from the registry has no administrators", async () => {
    // 1. Arrange
    const db = fakeFirestore({});
    const groups = fakeGroups({ [ROOT]: [EMAIL] });

    // 2. Act
    const result = await isPartnerAdmin(db, groups, "rotasul", EMAIL);

    // 3. Assert
    assert.equal(result, false);
  });

  for (const status of ["reserved", "provisioning", "deleting", "failed", undefined]) {
    test(`Sad Path: a partner whose status is ${status} has no administrators`, async () => {
      // 1. Arrange
      const db = fakeFirestore(activeRegistry({ status }));
      const groups = fakeGroups({ [ROOT]: [EMAIL] });

      // 2. Act
      const result = await isPartnerAdmin(db, groups, "rotasul", EMAIL);

      // 3. Assert
      assert.equal(result, false);
    });
  }

  const invalidIds = [
    ["a two-letter id", "ab"],
    ["a reserved id", "community"],
    ["an id with digits", "rota1"],
    ["an upper-case id", "RotaSul"],
    ["a non-string id", 42],
    ["a missing id", undefined],
  ];
  for (const [label, partnerId] of invalidIds) {
    test(`Sad Path: ${label} is refused without touching Firestore or the groups`, async () => {
      // 1. Arrange
      const db = fakeFirestore({ [`partners/${partnerId}`]: { status: "active" } });
      const groups = fakeGroups({ [`${partnerId}00@monamienet.org`]: [EMAIL] });

      // 2. Act
      const result = await isPartnerAdmin(db, groups, partnerId, EMAIL);

      // 3. Assert
      assert.equal(result, false);
      assert.deepEqual(groups.calls, []);
    });
  }

  for (const email of ["", undefined, null]) {
    test(`Sad Path: a caller without an e-mail (${JSON.stringify(email)}) is not an administrator`, async () => {
      // 1. Arrange
      const db = fakeFirestore(activeRegistry());
      const groups = fakeGroups({ [ROOT]: [EMAIL] });

      // 2. Act
      const result = await isPartnerAdmin(db, groups, "rotasul", email);

      // 3. Assert
      assert.equal(result, false);
    });
  }
});
