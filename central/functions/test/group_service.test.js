const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  GroupError,
  MAX_GROUPS,
  createGroup,
  deleteGroup,
  groupDeletionImpact,
  listGroups,
  normalizeGroupName,
  removeMember,
  renameGroup,
  setMemberRoles,
  validGroupId,
  validateGroupName,
  validateRoles,
  whoLosesAccess,
} = require("../group_service");
const { personKey } = require("../person_key");
const { fakeFirestore } = require("./fake_firestore");

const NOW = new Date("2026-10-31T12:00:00.000Z");
const ORG = "organizations/rotasul";
const ANA = "ana@x.com";
const VERA = "vera@x.com";
const OLGA = "olga@x.com";

/** Rota Sul: Ana publishes in guias and recepcao, Vera subscribes to guias,
 * Olga administers it and is in guias. */
function organization() {
  const member = (email, role) => ({
    [`${ORG}/organizationMemberships/${personKey(email)}`]: { email, role },
  });
  const inGroup = (groupId, email, roles) => ({
    [`${ORG}/groups/${groupId}/groupMemberships/${personKey(email)}`]: {
      email,
      organizationId: "rotasul",
      roles,
    },
  });
  return fakeFirestore({
    [`${ORG}/groups/guias`]: { name: "Guias", createdAt: NOW },
    [`${ORG}/groups/recepcao`]: { name: "Recepção", createdAt: NOW },
    ...member(ANA, "member"),
    ...member(VERA, "member"),
    ...member(OLGA, "admin"),
    ...inGroup("guias", ANA, ["publisher"]),
    ...inGroup("recepcao", ANA, ["publisher"]),
    ...inGroup("guias", VERA, ["maintainer", "subscriber"]),
    ...inGroup("guias", OLGA, ["subscriber"]),
    [`${ORG}/groups/guias/positions/${personKey(ANA)}`]: { email: ANA, removedAt: null },
  });
}

/** The central project with everyone's `accounts` entry. */
function central() {
  return fakeFirestore(
    Object.fromEntries(
      [ANA, VERA, OLGA].map((email) => [
        `accounts/${personKey(email)}`,
        { email, organizationIds: ["rotasul"] },
      ])
    )
  );
}

async function groupErrorOf(act) {
  try {
    await act();
  } catch (error) {
    assert.ok(error instanceof GroupError, `expected GroupError, got ${error}`);
    return error;
  }
  assert.fail("expected a GroupError");
}

describe("validateGroupName - Unit Test Suite", () => {
  test("Happy Path: trims and collapses the spaces of a new name", () => {
    // 1. Arrange
    const name = "  Guias   Norte ";

    // 2. Act
    const clean = validateGroupName(name, ["Recepção"]);

    // 3. Assert
    assert.equal(clean, "Guias Norte");
  });

  test("Edge Case: a name equal to another but for case and accents is a duplicate", async () => {
    // 1. Arrange
    const name = "recepcao";

    // 2. Act
    const error = await groupErrorOf(() => validateGroupName(name, ["Recepção"]));

    // 3. Assert
    assert.equal(error.code, "duplicate");
  });

  test("Sad Path: a name with one letter is refused", async () => {
    // 1. Arrange
    const name = "A1";

    // 2. Act
    const error = await groupErrorOf(() => validateGroupName(name, []));

    // 3. Assert
    assert.equal(error.code, "name");
  });
});

describe("validateRoles - Unit Test Suite", () => {
  test("Happy Path: both roles come back sorted without duplicates", () => {
    // 1. Arrange
    const roles = ["subscriber", "publisher", "subscriber"];

    // 2. Act
    const result = validateRoles(roles);

    // 3. Assert
    assert.deepEqual(result, ["publisher", "subscriber"]);
  });

  test("Edge Case: maintainer cannot be given yet", async () => {
    // 1. Arrange
    const roles = ["maintainer"];

    // 2. Act
    const error = await groupErrorOf(() => validateRoles(roles));

    // 3. Assert
    assert.equal(error.code, "roles");
  });

  test("Sad Path: no role is refused", async () => {
    // 1. Arrange
    const roles = [];

    // 2. Act
    const error = await groupErrorOf(() => validateRoles(roles));

    // 3. Assert
    assert.equal(error.code, "roles");
  });
});

describe("whoLosesAccess - Unit Test Suite", () => {
  const groups = [
    { id: "guias", people: [{ email: ANA }, { email: VERA }, { email: OLGA }] },
    { id: "recepcao", people: [{ email: ANA }] },
  ];

  test("Happy Path: only the people in no other group lose access", () => {
    // 1. Arrange
    const admins = new Set([OLGA]);

    // 2. Act
    const impact = whoLosesAccess("guias", groups, admins);

    // 3. Assert
    assert.deepEqual(impact, { loses: [VERA], stays: [ANA, OLGA] });
  });

  test("Edge Case: an administrator in no other group stays", () => {
    // 1. Arrange
    const admins = new Set([OLGA, VERA]);

    // 2. Act
    const impact = whoLosesAccess("guias", groups, admins);

    // 3. Assert
    assert.deepEqual(impact.loses, []);
  });

  test("Sad Path: an unknown group affects nobody", () => {
    // 1. Arrange
    const admins = new Set();

    // 2. Act
    const impact = whoLosesAccess("nope", groups, admins);

    // 3. Assert
    assert.deepEqual(impact, { loses: [], stays: [] });
  });
});

describe("listGroups and createGroup - Unit Test Suite", () => {
  test("Happy Path: groups come sorted by name with their people", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const groups = await listGroups(db, "rotasul");

    // 3. Assert
    assert.deepEqual(
      groups.map((g) => [g.name, g.people.map((p) => p.email)]),
      [
        ["Guias", [ANA, OLGA, VERA]],
        ["Recepção", [ANA]],
      ]
    );
  });

  test("Happy Path: a new group is stored with its name and creation time", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const { id, name } = await createGroup(db, "rotasul", " Vendas ", NOW);

    // 3. Assert
    assert.deepEqual(db.store.get(`${ORG}/groups/${id}`), { name, createdAt: NOW });
  });

  test("Sad Path: a duplicate name creates nothing", async () => {
    // 1. Arrange
    const db = organization();
    const before = db.store.size;

    // 2. Act
    await createGroup(db, "rotasul", "GUIAS", NOW).catch(() => {});

    // 3. Assert
    assert.equal(db.store.size, before);
  });
});

describe("setMemberRoles - Unit Test Suite", () => {
  test("Happy Path: losing publisher marks the position removedAt", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    await setMemberRoles(db, "rotasul", "guias", ANA, ["subscriber"], NOW);

    // 3. Assert
    assert.equal(db.store.get(`${ORG}/groups/guias/positions/${personKey(ANA)}`).removedAt, NOW);
  });

  test("Edge Case: a maintainer role already held is kept", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const { roles } = await setMemberRoles(db, "rotasul", "guias", VERA, ["publisher"], NOW);

    // 3. Assert
    assert.deepEqual(roles, ["maintainer", "publisher"]);
  });

  test("Sad Path: someone who is not in the group is refused with member", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await groupErrorOf(() =>
      setMemberRoles(db, "rotasul", "recepcao", VERA, ["publisher"], NOW)
    );

    // 3. Assert
    assert.equal(error.code, "member");
  });
});

describe("removeMember - Unit Test Suite", () => {
  test("Happy Path: leaving the last group leaves the organization and its accounts entry", async () => {
    // 1. Arrange
    const db = organization();
    const centralDb = central();

    // 2. Act
    await removeMember(db, centralDb, "rotasul", "guias", VERA, NOW);

    // 3. Assert
    assert.deepEqual(
      [
        db.store.has(`${ORG}/organizationMemberships/${personKey(VERA)}`),
        centralDb.store.get(`accounts/${personKey(VERA)}`).organizationIds,
      ],
      [false, []]
    );
  });

  test("Edge Case: someone still in another group stays in the organization", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await removeMember(db, central(), "rotasul", "guias", ANA, NOW);

    // 3. Assert
    assert.deepEqual(result, { leftOrganization: false });
  });

  test("Edge Case: an administrator left in no group stays in the organization", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await removeMember(db, central(), "rotasul", "guias", OLGA, NOW);

    // 3. Assert
    assert.deepEqual(result, { leftOrganization: false });
  });

  test("Sad Path: an unknown group is refused with group", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await groupErrorOf(() => removeMember(db, central(), "rotasul", "nope", ANA, NOW));

    // 3. Assert
    assert.equal(error.code, "group");
  });
});

describe("deleteGroup - Unit Test Suite", () => {
  test("Happy Path: the group goes with everything under it", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    await deleteGroup(db, central(), "rotasul", "guias", async () => {});

    // 3. Assert
    assert.deepEqual(
      [...db.store.keys()].filter((p) => p.startsWith(`${ORG}/groups/guias`)),
      []
    );
  });

  test("Edge Case: only the people left in no group leave the organization", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    await deleteGroup(db, central(), "rotasul", "guias", async () => {});

    // 3. Assert
    assert.deepEqual(
      [ANA, VERA, OLGA].map((e) => db.store.has(`${ORG}/organizationMemberships/${personKey(e)}`)),
      [true, false, true]
    );
  });

  test("Sad Path: when cancelling the invites fails, the group is kept for a retry", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    await deleteGroup(db, central(), "rotasul", "guias", async () => {
      throw new Error("central unavailable");
    }).catch(() => {});

    // 3. Assert
    assert.ok(db.store.has(`${ORG}/groups/guias`));
  });
});

describe("normalizeGroupName - Unit Test Suite", () => {
  test("Happy Path: accents, case and extra spaces are ignored", () => {
    // 1. Arrange
    const name = "  Recepção   Léste ";

    // 2. Act
    const normal = normalizeGroupName(name);

    // 3. Assert
    assert.equal(normal, "recepcao leste");
  });

  test("Edge Case: a name already in comparison form is unchanged", () => {
    // 1. Arrange
    const name = "guias";

    // 2. Act
    const normal = normalizeGroupName(name);

    // 3. Assert
    assert.equal(normal, "guias");
  });

  test("Sad Path: a name of only spaces is empty", () => {
    // 1. Arrange
    const name = "   ";

    // 2. Act
    const normal = normalizeGroupName(name);

    // 3. Assert
    assert.equal(normal, "");
  });
});

describe("validateGroupName limits - Unit Test Suite", () => {
  test("Happy Path: a name of exactly 40 characters is accepted", () => {
    // 1. Arrange
    const name = "a".repeat(40);

    // 2. Act
    const clean = validateGroupName(name, []);

    // 3. Assert
    assert.equal(clean.length, 40);
  });

  test("Edge Case: a name of 41 characters is refused", async () => {
    // 1. Arrange
    const name = "a".repeat(41);

    // 2. Act
    const error = await groupErrorOf(() => validateGroupName(name, []));

    // 3. Assert
    assert.equal(error.code, "name");
  });

  test("Sad Path: a name that is not text is refused", async () => {
    // 1. Arrange
    const name = 42;

    // 2. Act
    const error = await groupErrorOf(() => validateGroupName(name, []));

    // 3. Assert
    assert.equal(error.code, "name");
  });
});

describe("validGroupId - Unit Test Suite", () => {
  test("Happy Path: a Firestore auto id is accepted", () => {
    // 1. Arrange
    const groupId = "Xk3_9a-ZqP0wLmN2tYv8";

    // 2. Act
    const id = validGroupId(groupId);

    // 3. Assert
    assert.equal(id, groupId);
  });

  test("Edge Case: a 64-character id is accepted", () => {
    // 1. Arrange
    const groupId = "a".repeat(64);

    // 2. Act
    const id = validGroupId(groupId);

    // 3. Assert
    assert.equal(id, groupId);
  });

  for (const groupId of ["", "a/b", "a".repeat(65), undefined, 7]) {
    test(`Sad Path: ${JSON.stringify(groupId)} is refused with group`, async () => {
      // 1. Arrange
      const input = groupId;

      // 2. Act
      const error = await groupErrorOf(() => validGroupId(input));

      // 3. Assert
      assert.equal(error.code, "group");
    });
  }
});

describe("listGroups (response shape) - Unit Test Suite", () => {
  test("Happy Path: createdAt goes out as ISO text and roles sorted", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const groups = await listGroups(db, "rotasul");

    // 3. Assert
    const guias = groups.find((g) => g.id === "guias");
    assert.deepEqual(
      [guias.createdAt, guias.people.find((p) => p.email === VERA).roles],
      ["2026-10-31T12:00:00.000Z", ["maintainer", "subscriber"]]
    );
  });

  test("Edge Case: a group without createdAt goes out with null", async () => {
    // 1. Arrange
    const db = fakeFirestore({ [`${ORG}/groups/g1`]: { name: "Vendas" } });

    // 2. Act
    const [group] = await listGroups(db, "rotasul");

    // 3. Assert
    assert.deepEqual(group, { id: "g1", name: "Vendas", createdAt: null, people: [] });
  });

  test("Sad Path: an organization without groups lists none", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const groups = await listGroups(db, "rotasul");

    // 3. Assert
    assert.deepEqual(groups, []);
  });
});

describe("createGroup (limit) - Unit Test Suite", () => {
  test("Sad Path: an organization with 99 groups is refused with full", async () => {
    // 1. Arrange
    const docs = {};
    for (let i = 0; i < MAX_GROUPS; i++) docs[`${ORG}/groups/g${i}`] = { name: `Grupo ${i}` };
    const db = fakeFirestore(docs);

    // 2. Act
    const error = await groupErrorOf(() => createGroup(db, "rotasul", "Vendas", NOW));

    // 3. Assert
    assert.deepEqual([MAX_GROUPS, error.code], [99, "full"]);
  });
});

describe("renameGroup - Unit Test Suite", () => {
  test("Happy Path: the group gets the new name and keeps its id", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await renameGroup(db, "rotasul", "guias", "  Guias   Norte ");

    // 3. Assert
    assert.deepEqual(
      [result, db.store.get(`${ORG}/groups/guias`).name],
      [{ id: "guias", name: "Guias Norte" }, "Guias Norte"]
    );
  });

  test("Edge Case: the group may keep its own name with another case", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await renameGroup(db, "rotasul", "guias", "GUIAS");

    // 3. Assert
    assert.deepEqual(result, { id: "guias", name: "GUIAS" });
  });

  test("Sad Path: the name of another group is refused with duplicate", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await groupErrorOf(() => renameGroup(db, "rotasul", "guias", "recepcao"));

    // 3. Assert
    assert.deepEqual([error.code, db.store.get(`${ORG}/groups/guias`).name], ["duplicate", "Guias"]);
  });

  test("Sad Path: an unknown group is refused with group", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await groupErrorOf(() => renameGroup(db, "rotasul", "nope", "Vendas"));

    // 3. Assert
    assert.equal(error.code, "group");
  });
});

describe("groupDeletionImpact - Unit Test Suite", () => {
  test("Happy Path: only the members in no other group would leave; administrators stay", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const impact = await groupDeletionImpact(db, "rotasul", "guias");

    // 3. Assert
    assert.deepEqual(impact, { loses: [VERA], stays: [ANA, OLGA] });
  });

  test("Edge Case: a group whose people are all elsewhere loses nobody", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const impact = await groupDeletionImpact(db, "rotasul", "recepcao");

    // 3. Assert
    assert.deepEqual(impact, { loses: [], stays: [ANA] });
  });

  test("Sad Path: a malformed group id is refused with group", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await groupErrorOf(() => groupDeletionImpact(db, "rotasul", "../x"));

    // 3. Assert
    assert.equal(error.code, "group");
  });
});

describe("setMemberRoles (more) - Unit Test Suite", () => {
  test("Happy Path: the roles are stored on the person's group membership", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    await setMemberRoles(db, "rotasul", "guias", ANA, ["subscriber", "publisher"], NOW);

    // 3. Assert
    assert.deepEqual(
      db.store.get(`${ORG}/groups/guias/groupMemberships/${personKey(ANA)}`).roles,
      ["publisher", "subscriber"]
    );
  });

  test("Edge Case: keeping publisher leaves the position published", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    await setMemberRoles(db, "rotasul", "guias", " Ana@X.com ", ["publisher", "subscriber"], NOW);

    // 3. Assert
    assert.equal(db.store.get(`${ORG}/groups/guias/positions/${personKey(ANA)}`).removedAt, null);
  });

  test("Sad Path: an unknown role is refused and nothing changes", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await groupErrorOf(() =>
      setMemberRoles(db, "rotasul", "guias", ANA, ["admin"], NOW)
    );

    // 3. Assert
    assert.deepEqual(
      [error.code, db.store.get(`${ORG}/groups/guias/groupMemberships/${personKey(ANA)}`).roles],
      ["roles", ["publisher"]]
    );
  });
});

describe("removeMember (more) - Unit Test Suite", () => {
  test("Happy Path: the group membership goes and the position is marked removedAt", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    await removeMember(db, central(), "rotasul", "guias", ANA, NOW);

    // 3. Assert
    assert.deepEqual(
      [
        db.store.has(`${ORG}/groups/guias/groupMemberships/${personKey(ANA)}`),
        db.store.get(`${ORG}/groups/guias/positions/${personKey(ANA)}`).removedAt,
      ],
      [false, NOW]
    );
  });

  test("Edge Case: the e-mail is matched ignoring case and spaces", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const result = await removeMember(db, central(), "rotasul", "guias", " Vera@X.com ", NOW);

    // 3. Assert
    assert.deepEqual(result, { leftOrganization: true });
  });

  test("Sad Path: someone who is not in the group is refused with member", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const error = await groupErrorOf(() => removeMember(db, central(), "rotasul", "recepcao", VERA, NOW));

    // 3. Assert
    assert.deepEqual(
      [error.code, db.store.has(`${ORG}/organizationMemberships/${personKey(VERA)}`)],
      ["member", true]
    );
  });
});

describe("deleteGroup (more) - Unit Test Suite", () => {
  test("Happy Path: the people who leave lose their accounts entry too", async () => {
    // 1. Arrange
    const db = organization();
    const centralDb = central();

    // 2. Act
    await deleteGroup(db, centralDb, "rotasul", "guias", async () => {});

    // 3. Assert
    assert.deepEqual(
      [ANA, VERA, OLGA].map((e) => centralDb.store.get(`accounts/${personKey(e)}`).organizationIds),
      [["rotasul"], [], ["rotasul"]]
    );
  });

  test("Edge Case: repeating it after the group document is gone finishes the rest", async () => {
    // 1. Arrange
    const db = organization();
    db.store.delete(`${ORG}/groups/guias`);

    // 2. Act
    await deleteGroup(db, central(), "rotasul", "guias", async () => {});

    // 3. Assert
    assert.deepEqual(
      [...db.store.keys()].filter((p) => p.startsWith(`${ORG}/groups/guias/`)),
      []
    );
  });

  test("Sad Path: a malformed group id deletes nothing", async () => {
    // 1. Arrange
    const db = organization();
    const before = db.store.size;

    // 2. Act
    await deleteGroup(db, central(), "rotasul", "a/b", async () => {}).catch(() => {});

    // 3. Assert
    assert.equal(db.store.size, before);
  });
});
