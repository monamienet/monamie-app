const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  accountOrganizationIds,
  addToAccount,
  erasePerson,
  joinGroup,
  leaveOrganizationIfGroupless,
  markPositionRemoved,
  organizationOpener,
  personGroupMemberships,
  removeFromAccount,
  removeOrganizationFromAccounts,
  sortedRoles,
} = require("../membership_store");
const { personKey } = require("../person_key");
const { fakeFirestore } = require("./fake_firestore");

describe("organizationOpener - Unit Test Suite", () => {
  const central = () =>
    fakeFirestore({
      "organizations/rotasul": { status: "active", plan: "community" },
      "organizations/acme": { status: "active", plan: "standard" },
    });

  test("Happy Path: a Community organization opens the shared project", async () => {
    // 1. Arrange
    const open = organizationOpener(central(), (projectId) => projectId);

    // 2. Act
    const organization = await open("rotasul");

    // 3. Assert
    assert.equal(organization.db, "monamienet-community");
  });

  test("Edge Case: a Standard organization opens its own project", async () => {
    // 1. Arrange
    const open = organizationOpener(central(), (projectId) => projectId);

    // 2. Act
    const organization = await open("acme");

    // 3. Assert
    assert.equal(organization.db, "monamienet-acme");
  });

  for (const id of ["outro", "app", "../x", 42]) {
    test(`Sad Path: ${JSON.stringify(id)} (missing or invalid) opens nothing`, async () => {
      // 1. Arrange
      const open = organizationOpener(central(), (projectId) => projectId);

      // 2. Act
      const organization = await open(id);

      // 3. Assert
      assert.equal(organization, null);
    });
  }
});

describe("removeOrganizationFromAccounts - Unit Test Suite", () => {
  test("Happy Path: the retired id leaves every accounts entry holding it", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      "accounts/a": { email: "a@x.com", organizationIds: ["rotasul", "outro"] },
      "accounts/b": { email: "b@x.com", organizationIds: ["rotasul"] },
    });

    // 2. Act
    await removeOrganizationFromAccounts(db, "rotasul");

    // 3. Assert
    assert.deepEqual(
      [db.store.get("accounts/a").organizationIds, db.store.get("accounts/b").organizationIds],
      [["outro"], []]
    );
  });

  test("Edge Case: entries without the id are untouched", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "accounts/a": { email: "a@x.com", organizationIds: ["outro"] } });

    // 2. Act
    const count = await removeOrganizationFromAccounts(db, "rotasul");

    // 3. Assert
    assert.deepEqual([count, db.store.get("accounts/a").organizationIds], [0, ["outro"]]);
  });

  test("Sad Path: no accounts at all changes nothing", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const count = await removeOrganizationFromAccounts(db, "rotasul");

    // 3. Assert
    assert.equal(count, 0);
  });
});

const NOW = new Date("2026-10-31T12:00:00.000Z");
const EARLIER = new Date("2026-10-01T12:00:00.000Z");
const ANA = "ana@x.com";
const ANA_KEY = personKey(ANA);
const ROTASUL = "organizations/rotasul";
const OUTRO = "organizations/outro";

const groupMembership = (org, groupId, email, roles) => ({
  [`organizations/${org}/groups/${groupId}/groupMemberships/${personKey(email)}`]: {
    email,
    organizationId: org,
    roles,
  },
});

describe("sortedRoles - Unit Test Suite", () => {
  test("Happy Path: known roles come back sorted without duplicates", () => {
    // 1. Arrange
    const roles = ["subscriber", "publisher", "subscriber"];

    // 2. Act
    const result = sortedRoles(roles);

    // 3. Assert
    assert.deepEqual(result, ["publisher", "subscriber"]);
  });

  test("Edge Case: maintainer is kept and unknown roles are dropped", () => {
    // 1. Arrange
    const roles = ["owner", "maintainer", "watch"];

    // 2. Act
    const result = sortedRoles(roles);

    // 3. Assert
    assert.deepEqual(result, ["maintainer"]);
  });

  test("Sad Path: a missing roles field gives no roles", () => {
    // 1. Arrange
    const roles = undefined;

    // 2. Act
    const result = sortedRoles(roles);

    // 3. Assert
    assert.deepEqual(result, []);
  });
});

describe("personGroupMemberships - Unit Test Suite", () => {
  test("Happy Path: the person's groups in the organization come by group id with their roles", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      ...groupMembership("rotasul", "recepcao", ANA, ["subscriber"]),
      ...groupMembership("rotasul", "guias", ANA, ["subscriber", "publisher"]),
      ...groupMembership("rotasul", "guias", "vera@x.com", ["publisher"]),
    });

    // 2. Act
    const groups = await personGroupMemberships(db, "rotasul", ANA);

    // 3. Assert
    assert.deepEqual(groups, [
      { groupId: "guias", roles: ["publisher", "subscriber"] },
      { groupId: "recepcao", roles: ["subscriber"] },
    ]);
  });

  test("Edge Case: the e-mail is matched ignoring case", async () => {
    // 1. Arrange
    const db = fakeFirestore(groupMembership("rotasul", "guias", ANA, ["publisher"]));

    // 2. Act
    const groups = await personGroupMemberships(db, "rotasul", "Ana@X.com");

    // 3. Assert
    assert.deepEqual(groups, [{ groupId: "guias", roles: ["publisher"] }]);
  });

  test("Sad Path: memberships of another organization in the same project are left out", async () => {
    // 1. Arrange
    const db = fakeFirestore(groupMembership("outro", "vendas", ANA, ["publisher"]));

    // 2. Act
    const groups = await personGroupMemberships(db, "rotasul", ANA);

    // 3. Assert
    assert.deepEqual(groups, []);
  });
});

describe("joinGroup - Unit Test Suite", () => {
  test("Happy Path: a newcomer becomes a member of the organization and of the group", async () => {
    // 1. Arrange
    const db = fakeFirestore({ [`${ROTASUL}/groups/guias`]: { name: "Guias" } });

    // 2. Act
    await joinGroup(db, "rotasul", "guias", "Ana@X.com", ["subscriber"], NOW);

    // 3. Assert
    assert.deepEqual(
      [
        db.store.get(`${ROTASUL}/organizationMemberships/${ANA_KEY}`),
        db.store.get(`${ROTASUL}/groups/guias/groupMemberships/${ANA_KEY}`),
      ],
      [
        { email: ANA, role: "member", addedAt: NOW },
        { email: ANA, organizationId: "rotasul", roles: ["subscriber"], addedAt: NOW },
      ]
    );
  });

  test("Edge Case: an administrator keeps the role and the group roles are united, keeping addedAt", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      [`${ROTASUL}/organizationMemberships/${ANA_KEY}`]: { email: ANA, role: "admin", addedAt: EARLIER },
      [`${ROTASUL}/groups/guias/groupMemberships/${ANA_KEY}`]: {
        email: ANA,
        organizationId: "rotasul",
        roles: ["maintainer", "subscriber"],
        addedAt: EARLIER,
      },
    });

    // 2. Act
    await joinGroup(db, "rotasul", "guias", ANA, ["publisher"], NOW);

    // 3. Assert
    assert.deepEqual(
      [
        db.store.get(`${ROTASUL}/organizationMemberships/${ANA_KEY}`).role,
        db.store.get(`${ROTASUL}/groups/guias/groupMemberships/${ANA_KEY}`),
      ],
      [
        "admin",
        {
          email: ANA,
          organizationId: "rotasul",
          roles: ["maintainer", "publisher", "subscriber"],
          addedAt: EARLIER,
        },
      ]
    );
  });

  test("Sad Path: unknown roles are not stored", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await joinGroup(db, "rotasul", "guias", ANA, ["publisher", "owner"], NOW);

    // 3. Assert
    assert.deepEqual(db.store.get(`${ROTASUL}/groups/guias/groupMemberships/${ANA_KEY}`).roles, [
      "publisher",
    ]);
  });
});

describe("markPositionRemoved - Unit Test Suite", () => {
  test("Happy Path: the person's position in the group gets removedAt and keeps the rest", async () => {
    // 1. Arrange
    const path = `${ROTASUL}/groups/guias/positions/${ANA_KEY}`;
    const db = fakeFirestore({ [path]: { email: ANA, lat: 1, lng: 2, removedAt: null } });

    // 2. Act
    await markPositionRemoved(db, "rotasul", "guias", ANA, NOW);

    // 3. Assert
    assert.deepEqual(db.store.get(path), { email: ANA, lat: 1, lng: 2, removedAt: NOW });
  });

  test("Edge Case: the position in another group is untouched", async () => {
    // 1. Arrange
    const other = `${ROTASUL}/groups/recepcao/positions/${ANA_KEY}`;
    const db = fakeFirestore({ [other]: { email: ANA, removedAt: null } });

    // 2. Act
    await markPositionRemoved(db, "rotasul", "guias", ANA, NOW);

    // 3. Assert
    assert.equal(db.store.get(other).removedAt, null);
  });

  test("Sad Path: someone who never published there gets no position", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await markPositionRemoved(db, "rotasul", "guias", ANA, NOW);

    // 3. Assert
    assert.equal(db.store.size, 0);
  });
});

describe("leaveOrganizationIfGroupless - Unit Test Suite", () => {
  const member = (role) => ({
    [`${ROTASUL}/organizationMemberships/${ANA_KEY}`]: { email: ANA, role },
  });
  const central = () =>
    fakeFirestore({ [`accounts/${ANA_KEY}`]: { email: ANA, organizationIds: ["outro", "rotasul"] } });

  test("Happy Path: a member left in no group leaves the organization and its accounts entry", async () => {
    // 1. Arrange
    const db = fakeFirestore(member("member"));
    const centralDb = central();

    // 2. Act
    const left = await leaveOrganizationIfGroupless(db, centralDb, "rotasul", ANA);

    // 3. Assert
    assert.deepEqual(
      [
        left,
        db.store.has(`${ROTASUL}/organizationMemberships/${ANA_KEY}`),
        centralDb.store.get(`accounts/${ANA_KEY}`).organizationIds,
      ],
      [true, false, ["outro"]]
    );
  });

  test("Edge Case: an administrator left in no group stays", async () => {
    // 1. Arrange
    const db = fakeFirestore(member("admin"));

    // 2. Act
    const left = await leaveOrganizationIfGroupless(db, central(), "rotasul", ANA);

    // 3. Assert
    assert.deepEqual([left, db.store.has(`${ROTASUL}/organizationMemberships/${ANA_KEY}`)], [false, true]);
  });

  test("Sad Path: a member still in a group stays", async () => {
    // 1. Arrange
    const db = fakeFirestore({ ...member("member"), ...groupMembership("rotasul", "guias", ANA, ["publisher"]) });

    // 2. Act
    const left = await leaveOrganizationIfGroupless(db, central(), "rotasul", ANA);

    // 3. Assert
    assert.deepEqual([left, db.store.has(`${ROTASUL}/organizationMemberships/${ANA_KEY}`)], [false, true]);
  });
});

describe("accounts entries - Unit Test Suite", () => {
  test("Happy Path: adding an organization creates the entry with the lowercased e-mail", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();

    // 2. Act
    await addToAccount(centralDb, "Ana@X.com", "rotasul");

    // 3. Assert
    assert.deepEqual(centralDb.store.get(`accounts/${ANA_KEY}`), { email: ANA, organizationIds: ["rotasul"] });
  });

  test("Edge Case: adding an organization already listed does not repeat it", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ [`accounts/${ANA_KEY}`]: { email: ANA, organizationIds: ["rotasul"] } });

    // 2. Act
    await addToAccount(centralDb, ANA, "rotasul");

    // 3. Assert
    assert.deepEqual(centralDb.store.get(`accounts/${ANA_KEY}`).organizationIds, ["rotasul"]);
  });

  test("Sad Path: removing from a person without an entry creates none", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();

    // 2. Act
    await removeFromAccount(centralDb, ANA, "rotasul");

    // 3. Assert
    assert.equal(centralDb.store.size, 0);
  });
});

describe("accountOrganizationIds - Unit Test Suite", () => {
  test("Happy Path: the ids come sorted without duplicates", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({
      [`accounts/${ANA_KEY}`]: { email: ANA, organizationIds: ["rotasul", "acme", "rotasul"] },
    });

    // 2. Act
    const ids = await accountOrganizationIds(centralDb, "Ana@X.com");

    // 3. Assert
    assert.deepEqual(ids, ["acme", "rotasul"]);
  });

  test("Edge Case: values that are not text are dropped", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({
      [`accounts/${ANA_KEY}`]: { email: ANA, organizationIds: ["rotasul", 42, null] },
    });

    // 2. Act
    const ids = await accountOrganizationIds(centralDb, ANA);

    // 3. Assert
    assert.deepEqual(ids, ["rotasul"]);
  });

  for (const [label, docs] of [
    ["no entry", {}],
    ["a malformed organizationIds", { [`accounts/${ANA_KEY}`]: { email: ANA, organizationIds: "rotasul" } }],
  ]) {
    test(`Sad Path: ${label} gives no organizations`, async () => {
      // 1. Arrange
      const centralDb = fakeFirestore(docs);

      // 2. Act
      const ids = await accountOrganizationIds(centralDb, ANA);

      // 3. Assert
      assert.deepEqual(ids, []);
    });
  }
});

describe("erasePerson - Unit Test Suite", () => {
  /** A Community project with Ana in rotasul (group guias, position and
   * trail) and in outro (group vendas, position). */
  function community() {
    return fakeFirestore({
      [`${ROTASUL}/organizationMemberships/${ANA_KEY}`]: { email: ANA, role: "member" },
      [`${ROTASUL}/groups/guias`]: { name: "Guias" },
      ...groupMembership("rotasul", "guias", ANA, ["publisher"]),
      [`${ROTASUL}/groups/guias/positions/${ANA_KEY}`]: { email: ANA, removedAt: null },
      [`${ROTASUL}/groups/guias/positions/${ANA_KEY}/trail/p1`]: { lat: 1, lng: 2 },
      [`${ROTASUL}/groups/guias/positions/${ANA_KEY}/trailDays/2026-10-31`]: { pointCount: 1 },
      [`${OUTRO}/organizationMemberships/${ANA_KEY}`]: { email: ANA, role: "member" },
      ...groupMembership("outro", "vendas", ANA, ["publisher"]),
      [`${OUTRO}/groups/vendas/positions/${ANA_KEY}`]: { email: ANA, removedAt: null },
    });
  }

  test("Happy Path: memberships, positions, trail and day summaries in the organization are erased", async () => {
    // 1. Arrange
    const db = community();

    // 2. Act
    await erasePerson(db, "rotasul", "Ana@X.com");

    // 3. Assert
    assert.deepEqual([...db.store.keys()].filter((p) => p.startsWith(`${ROTASUL}/`) && p.includes(ANA_KEY)), []);
  });

  test("Edge Case: the person's data in another organization of the same project is kept", async () => {
    // 1. Arrange
    const db = community();

    // 2. Act
    await erasePerson(db, "rotasul", ANA);

    // 3. Assert
    assert.deepEqual(
      [...db.store.keys()].filter((p) => p.startsWith(`${OUTRO}/`)).sort(),
      [
        `${OUTRO}/groups/vendas/groupMemberships/${ANA_KEY}`,
        `${OUTRO}/groups/vendas/positions/${ANA_KEY}`,
        `${OUTRO}/organizationMemberships/${ANA_KEY}`,
      ]
    );
  });

  test("Sad Path: a person with nothing in the organization erases nothing", async () => {
    // 1. Arrange
    const db = community();
    const before = db.store.size;

    // 2. Act
    await erasePerson(db, "rotasul", "vera@x.com");

    // 3. Assert
    assert.equal(db.store.size, before);
  });
});
