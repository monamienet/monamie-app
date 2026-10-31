const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  ACCOUNT_GRACE_MS,
  DeletionError,
  cancelAccountDeletion,
  eraseDueAccounts,
  pendingDeletion,
  requestAccountDeletion,
} = require("../account_deletion");
const { personKey } = require("../person_key");
const { fakeFirestore } = require("./fake_firestore");

const DAY_MS = 24 * 60 * 60 * 1000;
const NOW = new Date("2026-10-26T12:00:00.000Z");
const THIRTY_DAYS_LATER = new Date("2026-11-25T12:00:00.000Z");
const ANA = "ana@x.com";
const ANA_KEY = personKey(ANA);
const ROTASUL = "organizations/rotasul";
const OUTRO = "organizations/outro";

/** Rota Sul's project: Ana is a member, publishes in guias and subscribes
 * to recepcao, with a position and trail in guias. */
function rotasulDb() {
  return fakeFirestore({
    [`${ROTASUL}/organizationMemberships/${ANA_KEY}`]: { email: ANA, role: "member" },
    [`${ROTASUL}/groups/guias`]: { name: "Guias" },
    [`${ROTASUL}/groups/recepcao`]: { name: "Recepção" },
    [`${ROTASUL}/groups/guias/groupMemberships/${ANA_KEY}`]: {
      email: ANA,
      organizationId: "rotasul",
      roles: ["publisher"],
    },
    [`${ROTASUL}/groups/recepcao/groupMemberships/${ANA_KEY}`]: {
      email: ANA,
      organizationId: "rotasul",
      roles: ["subscriber"],
    },
    [`${ROTASUL}/groups/guias/positions/${ANA_KEY}`]: { email: ANA, removedAt: null },
    [`${ROTASUL}/groups/guias/positions/${ANA_KEY}/trail/p1`]: { lat: 1, lng: 2 },
  });
}

/** Outro's project: Ana owns and administers it, in group vendas. */
function outroDb() {
  return fakeFirestore({
    [`${OUTRO}/organizationMemberships/${ANA_KEY}`]: { email: ANA, role: "admin" },
    [`${OUTRO}/groups/vendas`]: { name: "Vendas" },
    [`${OUTRO}/groups/vendas/groupMemberships/${ANA_KEY}`]: {
      email: ANA,
      organizationId: "outro",
      roles: ["publisher", "subscriber"],
    },
  });
}

/** The central project: Ana's accounts entry and both registry entries. */
function centralDb(extra = {}) {
  return fakeFirestore({
    [`accounts/${ANA_KEY}`]: { email: ANA, organizationIds: ["outro", "rotasul"] },
    "organizations/rotasul": { status: "active", ownerEmail: "dono@x.com" },
    "organizations/outro": { status: "active", ownerEmail: ANA, name: "Outro" },
    ...extra,
  });
}

function depsOf(projects) {
  return { organizationDb: async (id) => projects[id] ?? null };
}

async function deletionErrorOf(act) {
  try {
    await act();
  } catch (error) {
    assert.ok(error instanceof DeletionError, `expected DeletionError, got ${error}`);
    return error;
  }
  assert.fail("expected a DeletionError");
}

const ask = (db, projects, confirmIds = ["outro"]) =>
  requestAccountDeletion(db, depsOf(projects), { email: ANA, uid: "u1", confirmIds }, NOW);

describe("ACCOUNT_GRACE_MS - Unit Test Suite", () => {
  test("Happy Path: the grace period is 30 days", () => {
    // 1. Arrange
    const expected = 30 * DAY_MS;

    // 2. Act
    const actual = ACCOUNT_GRACE_MS;

    // 3. Assert
    assert.equal(actual, expected);
  });
});

describe("requestAccountDeletion - Unit Test Suite", () => {
  test("Happy Path: a member leaves the groups and the organization, and the record lists them", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };

    // 2. Act
    await ask(db, projects);

    // 3. Assert
    assert.deepEqual(db.store.get(`accountDeletions/${ANA_KEY}`).memberships, [
      { organizationId: "outro", role: null, groups: [{ groupId: "vendas", roles: ["publisher", "subscriber"] }] },
      {
        organizationId: "rotasul",
        role: "member",
        groups: [
          { groupId: "guias", roles: ["publisher"] },
          { groupId: "recepcao", roles: ["subscriber"] },
        ],
      },
    ]);
  });

  test("Happy Path: the positions are marked removedAt and the non-owned organization leaves the accounts entry", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };

    // 2. Act
    await ask(db, projects);

    // 3. Assert
    assert.deepEqual(
      [
        projects.rotasul.store.get(`${ROTASUL}/groups/guias/positions/${ANA_KEY}`).removedAt,
        projects.rotasul.store.has(`${ROTASUL}/organizationMemberships/${ANA_KEY}`),
        db.store.get(`accounts/${ANA_KEY}`).organizationIds,
      ],
      [NOW, false, ["outro"]]
    );
  });

  test("Edge Case: the owner stays an administrator and the owned organization goes to deleting", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };

    // 2. Act
    const result = await ask(db, projects);

    // 3. Assert
    assert.deepEqual(
      [
        result.ownedOrganizationIds,
        db.store.get("organizations/outro").status,
        projects.outro.store.get(`${OUTRO}/organizationMemberships/${ANA_KEY}`).role,
        result.deleteAt.getTime(),
      ],
      [["outro"], "deleting", "admin", THIRTY_DAYS_LATER.getTime()]
    );
  });

  test("Sad Path: an owner who did not confirm is refused before anything changes", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };

    // 2. Act
    const error = await deletionErrorOf(() => ask(db, projects, []));

    // 3. Assert
    assert.deepEqual(
      [error.code, projects.rotasul.store.has(`${ROTASUL}/organizationMemberships/${ANA_KEY}`)],
      ["confirm", true]
    );
  });
});

describe("pendingDeletion - Unit Test Suite", () => {
  test("Happy Path: a pending record is found by the e-mail's key", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      [`accountDeletions/${ANA_KEY}`]: {
        status: "pending",
        deleteAt: THIRTY_DAYS_LATER,
        ownedOrganizationIds: ["outro"],
      },
    });

    // 2. Act
    const deletion = await pendingDeletion(db, "Ana@X.com");

    // 3. Assert
    assert.deepEqual(deletion.ownedOrganizationIds, ["outro"]);
  });

  test("Edge Case: a record that is no longer pending reads as null", async () => {
    // 1. Arrange
    const db = fakeFirestore({ [`accountDeletions/${ANA_KEY}`]: { status: "done" } });

    // 2. Act
    const deletion = await pendingDeletion(db, ANA);

    // 3. Assert
    assert.equal(deletion, null);
  });

  test("Sad Path: no record reads as null", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const deletion = await pendingDeletion(db, ANA);

    // 3. Assert
    assert.equal(deletion, null);
  });
});

describe("cancelAccountDeletion - Unit Test Suite", () => {
  test("Happy Path: the memberships come back and the owned organization is active again", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };
    await ask(db, projects);

    // 2. Act
    await cancelAccountDeletion(db, depsOf(projects), ANA, NOW);

    // 3. Assert
    assert.deepEqual(
      [
        projects.rotasul.store.get(`${ROTASUL}/organizationMemberships/${ANA_KEY}`).role,
        projects.rotasul.store.get(`${ROTASUL}/groups/guias/groupMemberships/${ANA_KEY}`).roles,
        projects.outro.store.get(`${OUTRO}/groups/vendas/groupMemberships/${ANA_KEY}`).roles,
        [...db.store.get(`accounts/${ANA_KEY}`).organizationIds].sort(),
        db.store.get("organizations/outro").status,
        db.store.has(`accountDeletions/${ANA_KEY}`),
      ],
      ["member", ["publisher"], ["publisher", "subscriber"], ["outro", "rotasul"], "active", false]
    );
  });

  test("Edge Case: a group deleted meanwhile is not written back", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };
    await ask(db, projects);
    projects.rotasul.store.delete(`${ROTASUL}/groups/recepcao`);

    // 2. Act
    await cancelAccountDeletion(db, depsOf(projects), ANA, NOW);

    // 3. Assert
    assert.equal(projects.rotasul.store.has(`${ROTASUL}/groups/recepcao/groupMemberships/${ANA_KEY}`), false);
  });

  test("Sad Path: a deadline that has passed is refused with code late", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      [`accountDeletions/${ANA_KEY}`]: { status: "pending", deleteAt: NOW, memberships: [] },
    });

    // 2. Act
    const error = await deletionErrorOf(() => cancelAccountDeletion(db, depsOf({}), ANA, NOW));

    // 3. Assert
    assert.equal(error.code, "late");
  });
});

/** A sign-in store: `getUserByEmail` / `deleteUser`, recording deletions. */
function fakeAuth(users = {}) {
  const deleted = [];
  return {
    deleted,
    async getUserByEmail(email) {
      if (!users[email]) throw Object.assign(new Error("no user"), { code: "auth/user-not-found" });
      return { uid: users[email] };
    },
    async deleteUser(uid) {
      deleted.push(uid);
    },
  };
}

describe("eraseDueAccounts - Unit Test Suite", () => {
  const dueRecord = (extra = {}) => ({
    [`accountDeletions/${ANA_KEY}`]: {
      email: ANA,
      uid: "central-uid",
      status: "pending",
      deleteAt: NOW,
      memberships: [{ organizationId: "rotasul", role: "member", groups: [] }],
      ...extra,
    },
  });

  test("Happy Path: a due account is erased in its organizations and centrally", async () => {
    // 1. Arrange
    const db = centralDb(dueRecord());
    const rotasul = rotasulDb();
    const auth = fakeAuth({ [ANA]: "org-uid" });
    const deletedCentral = [];

    // 2. Act
    await eraseDueAccounts(
      db,
      {
        organization: async (id) => (id === "rotasul" ? { db: rotasul, auth } : null),
        deleteAuthUser: async (uid) => deletedCentral.push(uid),
      },
      NOW
    );

    // 3. Assert
    assert.deepEqual(
      [
        [...rotasul.store.keys()].filter((p) => p.includes(ANA_KEY)),
        auth.deleted,
        deletedCentral,
        db.store.has(`accounts/${ANA_KEY}`),
        db.store.has(`accountDeletions/${ANA_KEY}`),
      ],
      [[], ["org-uid"], ["central-uid"], false, false]
    );
  });

  test("Edge Case: another person's position in the same project is kept", async () => {
    // 1. Arrange
    const db = centralDb(dueRecord());
    const rotasul = rotasulDb();
    const other = `${ROTASUL}/groups/guias/positions/${personKey("vera@x.com")}`;
    rotasul.store.set(other, { email: "vera@x.com" });

    // 2. Act
    await eraseDueAccounts(
      db,
      {
        organization: async (id) => (id === "rotasul" ? { db: rotasul, auth: fakeAuth() } : null),
        deleteAuthUser: async () => {},
      },
      NOW
    );

    // 3. Assert
    assert.ok(rotasul.store.has(other));
  });

  test("Sad Path: a record not yet due is left alone", async () => {
    // 1. Arrange
    const db = centralDb(dueRecord({ deleteAt: new Date(NOW.getTime() + DAY_MS) }));

    // 2. Act
    const erased = await eraseDueAccounts(
      db,
      { organization: async () => null, deleteAuthUser: async () => {} },
      NOW
    );

    // 3. Assert
    assert.deepEqual([erased, db.store.has(`accountDeletions/${ANA_KEY}`)], [[], true]);
  });
});

describe("requestAccountDeletion (more) - Unit Test Suite", () => {
  test("Happy Path: the owner loses their group memberships in the owned organization", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };

    // 2. Act
    await ask(db, projects);

    // 3. Assert
    assert.equal(projects.outro.store.has(`${OUTRO}/groups/vendas/groupMemberships/${ANA_KEY}`), false);
  });

  test("Edge Case: an organization whose project cannot be opened is skipped", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { outro: outroDb() };

    // 2. Act
    await ask(db, projects);

    // 3. Assert
    assert.deepEqual(
      db.store.get(`accountDeletions/${ANA_KEY}`).memberships.map((m) => m.organizationId),
      ["outro"]
    );
  });

  test("Sad Path: the wrong id typed by an owner is refused with confirm", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };

    // 2. Act
    const error = await deletionErrorOf(() => ask(db, projects, ["rotasul"]));

    // 3. Assert
    assert.deepEqual(
      [error.code, db.store.get("organizations/outro").status, db.store.has(`accountDeletions/${ANA_KEY}`)],
      ["confirm", "active", false]
    );
  });
});

describe("cancelAccountDeletion (more) - Unit Test Suite", () => {
  test("Happy Path: the owner's kept admin membership is not written back over", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };
    await ask(db, projects);

    // 2. Act
    await cancelAccountDeletion(db, depsOf(projects), ANA, NOW);

    // 3. Assert
    assert.equal(projects.outro.store.get(`${OUTRO}/organizationMemberships/${ANA_KEY}`).role, "admin");
  });

  test("Edge Case: an organization whose project cannot be opened is skipped and the rest restored", async () => {
    // 1. Arrange
    const db = centralDb();
    const projects = { rotasul: rotasulDb(), outro: outroDb() };
    await ask(db, projects);

    // 2. Act
    await cancelAccountDeletion(db, depsOf({ outro: projects.outro }), ANA, NOW);

    // 3. Assert
    assert.deepEqual(
      [
        projects.rotasul.store.has(`${ROTASUL}/organizationMemberships/${ANA_KEY}`),
        projects.outro.store.has(`${OUTRO}/groups/vendas/groupMemberships/${ANA_KEY}`),
        db.store.has(`accountDeletions/${ANA_KEY}`),
      ],
      [false, true, false]
    );
  });

  test("Sad Path: without a pending deletion it is refused with code none", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const error = await deletionErrorOf(() => cancelAccountDeletion(db, depsOf({}), ANA, NOW));

    // 3. Assert
    assert.equal(error.code, "none");
  });
});

describe("eraseDueAccounts (more) - Unit Test Suite", () => {
  const record = {
    [`accountDeletions/${ANA_KEY}`]: {
      email: ANA,
      uid: "central-uid",
      status: "pending",
      deleteAt: NOW,
      memberships: [],
    },
  };

  test("Happy Path: an organization still in the accounts entry is erased too", async () => {
    // 1. Arrange
    const db = centralDb(record);
    const rotasul = rotasulDb();

    // 2. Act
    await eraseDueAccounts(
      db,
      {
        organization: async (id) => (id === "rotasul" ? { db: rotasul, auth: fakeAuth() } : null),
        deleteAuthUser: async () => {},
      },
      NOW
    );

    // 3. Assert
    assert.deepEqual([...rotasul.store.keys()].filter((p) => p.includes(ANA_KEY)), []);
  });

  test("Edge Case: a retired organization is skipped and the account is still erased centrally", async () => {
    // 1. Arrange
    const db = centralDb(record);

    // 2. Act
    const erased = await eraseDueAccounts(
      db,
      { organization: async () => null, deleteAuthUser: async () => {} },
      NOW
    );

    // 3. Assert
    assert.deepEqual(
      [erased, db.store.has(`accounts/${ANA_KEY}`), db.store.has(`accountDeletions/${ANA_KEY}`)],
      [[ANA], false, false]
    );
  });

  test("Sad Path: a central sign-in already gone does not stop the erasure", async () => {
    // 1. Arrange
    const db = centralDb(record);

    // 2. Act
    const erased = await eraseDueAccounts(
      db,
      {
        organization: async () => null,
        deleteAuthUser: async () => {
          throw Object.assign(new Error("gone"), { code: "auth/user-not-found" });
        },
      },
      NOW
    );

    // 3. Assert
    assert.deepEqual(erased, [ANA]);
  });
});
