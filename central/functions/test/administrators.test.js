const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  AdministratorError,
  isOwner,
  listAdministrators,
  ownedOrganization,
  setAdministrator,
  splitByRole,
} = require("../administrators");
const { personKey } = require("../person_key");
const { fakeFirestore } = require("./fake_firestore");

const ORG = "organizations/rotasul";
const OWNER = "olga@x.com";
const ANA = "ana@x.com";
const CAIO = "caio@x.com";

/** Rota Sul: Olga owns it, Ana administers it, Caio is a member. */
function organization() {
  return fakeFirestore({
    [`${ORG}/organizationMemberships/${personKey(OWNER)}`]: { email: OWNER, role: "admin" },
    [`${ORG}/organizationMemberships/${personKey(ANA)}`]: { email: ANA, role: "admin" },
    [`${ORG}/organizationMemberships/${personKey(CAIO)}`]: { email: CAIO, role: "member" },
  });
}

const roleOf = (db, email) =>
  db.store.get(`${ORG}/organizationMemberships/${personKey(email)}`)?.role;

/** Opens `db` as organization rotasul with `registry`. */
const openerOf = (db, registry) => async (id) => (id === "rotasul" ? { db, registry } : null);

const ACTIVE = Object.freeze({ status: "active", ownerEmail: OWNER });

async function administratorErrorOf(act) {
  try {
    await act();
  } catch (error) {
    assert.ok(error instanceof AdministratorError, `expected AdministratorError, got ${error}`);
    return error;
  }
  assert.fail("expected an AdministratorError");
}

describe("splitByRole - Unit Test Suite", () => {
  test("Happy Path: the owner comes first among the administrators", () => {
    // 1. Arrange
    const memberships = [
      { email: ANA, role: "admin" },
      { email: "caio@x.com", role: "member" },
      { email: OWNER, role: "admin" },
    ];

    // 2. Act
    const result = splitByRole(memberships, OWNER);

    // 3. Assert
    assert.deepEqual(result, {
      administrators: [
        { email: OWNER, owner: true },
        { email: ANA, owner: false },
      ],
      members: [{ email: "caio@x.com" }],
    });
  });
});

describe("setAdministrator - Unit Test Suite", () => {
  test("Happy Path: a demoted administrator stays in the organization as a member", async () => {
    // 1. Arrange
    const db = organization();
    const centralDb = fakeFirestore();

    // 2. Act
    await setAdministrator(db, centralDb, "rotasul", OWNER, ANA, false);

    // 3. Assert
    assert.equal(db.store.get(`${ORG}/organizationMemberships/${personKey(ANA)}`).role, "member");
  });

  test("Sad Path: the owner cannot be demoted", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const act = setAdministrator(db, fakeFirestore(), "rotasul", OWNER, " Olga@X.com ", false);

    // 3. Assert
    await assert.rejects(act, (e) => e instanceof AdministratorError && e.code === "owner");
  });
});

describe("isOwner - Unit Test Suite", () => {
  test("Happy Path: the registry's ownerEmail is the owner", () => {
    // 1. Arrange
    const registry = { ownerEmail: OWNER };

    // 2. Act
    const result = isOwner(registry, OWNER);

    // 3. Assert
    assert.equal(result, true);
  });

  test("Edge Case: case and spaces are ignored on both sides", () => {
    // 1. Arrange
    const registry = { ownerEmail: " Olga@X.com" };

    // 2. Act
    const result = isOwner(registry, "OLGA@x.COM ");

    // 3. Assert
    assert.equal(result, true);
  });

  test("Sad Path: another person is not the owner", () => {
    // 1. Arrange
    const registry = { ownerEmail: OWNER };

    // 2. Act
    const result = isOwner(registry, ANA);

    // 3. Assert
    assert.equal(result, false);
  });

  test("Sad Path: a registry without ownerEmail has no owner, not even an empty e-mail", () => {
    // 1. Arrange
    const registry = {};

    // 2. Act
    const result = isOwner(registry, "");

    // 3. Assert
    assert.equal(result, false);
  });
});

describe("ownedOrganization - Unit Test Suite", () => {
  test("Happy Path: the owner of an active organization gets its Firestore", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const owned = await ownedOrganization(openerOf(db, ACTIVE), "rotasul", OWNER);

    // 3. Assert
    assert.deepEqual(owned, { db, ownerEmail: OWNER });
  });

  test("Edge Case: the owner's e-mail comes back in lower case", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const owned = await ownedOrganization(openerOf(db, ACTIVE), "rotasul", " Olga@X.com ");

    // 3. Assert
    assert.equal(owned.ownerEmail, OWNER);
  });

  test("Sad Path: an administrator who is not the owner gets nothing", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const owned = await ownedOrganization(openerOf(db, ACTIVE), "rotasul", ANA);

    // 3. Assert
    assert.equal(owned, null);
  });

  test("Sad Path: the owner of an organization that is not active gets nothing", async () => {
    // 1. Arrange
    const db = organization();
    const registry = { status: "deleting", ownerEmail: OWNER };

    // 2. Act
    const owned = await ownedOrganization(openerOf(db, registry), "rotasul", OWNER);

    // 3. Assert
    assert.equal(owned, null);
  });

  test("Sad Path: an unknown organization gives nothing", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const owned = await ownedOrganization(openerOf(db, ACTIVE), "verdemar", OWNER);

    // 3. Assert
    assert.equal(owned, null);
  });

  test("Sad Path: a call without an e-mail gives nothing", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const owned = await ownedOrganization(openerOf(db, ACTIVE), "rotasul", undefined);

    // 3. Assert
    assert.equal(owned, null);
  });
});

describe("splitByRole (more) - Unit Test Suite", () => {
  test("Happy Path: administrators after the owner and members come by e-mail", () => {
    // 1. Arrange
    const memberships = [
      { email: "zeca@x.com", role: "member" },
      { email: "rui@x.com", role: "admin" },
      { email: "bia@x.com", role: "member" },
      { email: OWNER, role: "admin" },
      { email: ANA, role: "admin" },
    ];

    // 2. Act
    const result = splitByRole(memberships, OWNER);

    // 3. Assert
    assert.deepEqual(result, {
      administrators: [
        { email: OWNER, owner: true },
        { email: ANA, owner: false },
        { email: "rui@x.com", owner: false },
      ],
      members: [{ email: "bia@x.com" }, { email: "zeca@x.com" }],
    });
  });

  test("Edge Case: an organization with only the owner has no members", () => {
    // 1. Arrange
    const memberships = [{ email: OWNER, role: "admin" }];

    // 2. Act
    const result = splitByRole(memberships, OWNER);

    // 3. Assert
    assert.deepEqual(result, { administrators: [{ email: OWNER, owner: true }], members: [] });
  });

  test("Sad Path: entries without an e-mail or with an unknown role are left out", () => {
    // 1. Arrange
    const memberships = [
      { email: OWNER, role: "admin" },
      { email: "", role: "member" },
      { email: 7, role: "admin" },
      { role: "member" },
      { email: "rui@x.com", role: "guest" },
    ];

    // 2. Act
    const result = splitByRole(memberships, OWNER);

    // 3. Assert
    assert.deepEqual(result, { administrators: [{ email: OWNER, owner: true }], members: [] });
  });
});

describe("listAdministrators - Unit Test Suite", () => {
  test("Happy Path: reads the organization memberships, the owner first", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await listAdministrators(db, "rotasul", OWNER);

    // 3. Assert
    assert.deepEqual(result, {
      administrators: [
        { email: OWNER, owner: true },
        { email: ANA, owner: false },
      ],
      members: [{ email: CAIO }],
    });
  });

  test("Edge Case: group memberships and other organizations are not listed", async () => {
    // 1. Arrange
    const db = organization();
    db.store.set(`${ORG}/groups/guias/groupMemberships/${personKey("rui@x.com")}`, {
      email: "rui@x.com",
      roles: ["publisher"],
    });
    db.store.set(`organizations/verdemar/organizationMemberships/${personKey("bia@x.com")}`, {
      email: "bia@x.com",
      role: "member",
    });

    // 2. Act
    const result = await listAdministrators(db, "rotasul", OWNER);

    // 3. Assert
    assert.deepEqual(result.members, [{ email: CAIO }]);
  });

  test("Sad Path: an organization with no memberships lists nobody", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const result = await listAdministrators(db, "rotasul", OWNER);

    // 3. Assert
    assert.deepEqual(result, { administrators: [], members: [] });
  });
});

describe("setAdministrator (more) - Unit Test Suite", () => {
  test("Happy Path: a member is appointed administrator", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await setAdministrator(db, fakeFirestore(), "rotasul", OWNER, CAIO, true);

    // 3. Assert
    assert.deepEqual([result, roleOf(db, CAIO)], [{ email: CAIO, role: "admin" }, "admin"]);
  });

  test("Happy Path: the person's accounts entry lists the organization once", async () => {
    // 1. Arrange
    const db = organization();
    const centralDb = fakeFirestore({
      [`accounts/${personKey(ANA)}`]: { email: ANA, organizationIds: ["rotasul", "verdemar"] },
    });

    // 2. Act
    await setAdministrator(db, centralDb, "rotasul", OWNER, ANA, false);

    // 3. Assert
    assert.deepEqual(centralDb.store.get(`accounts/${personKey(ANA)}`).organizationIds, [
      "rotasul",
      "verdemar",
    ]);
  });

  test("Edge Case: a missing accounts entry is written with the organization", async () => {
    // 1. Arrange
    const db = organization();
    const centralDb = fakeFirestore();

    // 2. Act
    await setAdministrator(db, centralDb, "rotasul", OWNER, CAIO, true);

    // 3. Assert
    assert.deepEqual(centralDb.store.get(`accounts/${personKey(CAIO)}`), {
      email: CAIO,
      organizationIds: ["rotasul"],
    });
  });

  test("Edge Case: the e-mail is matched ignoring case and spaces", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await setAdministrator(db, fakeFirestore(), "rotasul", OWNER, " Caio@X.com ", true);

    // 3. Assert
    assert.deepEqual([result.email, roleOf(db, CAIO)], [CAIO, "admin"]);
  });

  test("Edge Case: appointing an administrator again changes nothing", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await setAdministrator(db, fakeFirestore(), "rotasul", OWNER, ANA, true);

    // 3. Assert
    assert.deepEqual([result.role, roleOf(db, ANA)], ["admin", "admin"]);
  });

  test("Sad Path: someone outside the organization is refused with member", async () => {
    // 1. Arrange
    const db = organization();
    const centralDb = fakeFirestore();

    // 2. Act
    const error = await administratorErrorOf(() =>
      setAdministrator(db, centralDb, "rotasul", OWNER, "rui@x.com", true)
    );

    // 3. Assert
    assert.deepEqual(
      [error.code, db.store.has(`${ORG}/organizationMemberships/${personKey("rui@x.com")}`), centralDb.store.size],
      ["member", false, 0]
    );
  });

  test("Sad Path: a blank e-mail is refused with email", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await administratorErrorOf(() =>
      setAdministrator(db, fakeFirestore(), "rotasul", OWNER, "  ", true)
    );

    // 3. Assert
    assert.equal(error.code, "email");
  });

  test("Sad Path: an e-mail that is not text is refused with email", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await administratorErrorOf(() =>
      setAdministrator(db, fakeFirestore(), "rotasul", OWNER, { email: CAIO }, true)
    );

    // 3. Assert
    assert.equal(error.code, "email");
  });

  test("Sad Path: admin that is not a boolean is refused with admin and nothing changes", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await administratorErrorOf(() =>
      setAdministrator(db, fakeFirestore(), "rotasul", OWNER, CAIO, "true")
    );

    // 3. Assert
    assert.deepEqual([error.code, roleOf(db, CAIO)], ["admin", "member"]);
  });

  test("Sad Path: the owner cannot be appointed either", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await administratorErrorOf(() =>
      setAdministrator(db, fakeFirestore(), "rotasul", OWNER, OWNER, true)
    );

    // 3. Assert
    assert.equal(error.code, "owner");
  });
});
