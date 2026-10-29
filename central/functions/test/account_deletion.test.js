const { describe, test } = require("node:test");
const assert = require("node:assert/strict");
const { FieldValue } = require("firebase-admin/firestore");

const {
  ACCOUNT_GRACE_MS,
  DeletionError,
  cancelAccountDeletion,
  eraseDueAccounts,
  leavesByPartner,
  pendingDeletion,
  requestAccountDeletion,
} = require("../account_deletion");

const DAY_MS = 24 * 60 * 60 * 1000;
const NOW = new Date("2026-10-26T12:00:00.000Z");
const THIRTY_DAYS_LATER = new Date("2026-11-25T12:00:00.000Z");
const EMAIL = "ana@x.com";

const isDelete = (value) =>
  value !== null && typeof value?.isEqual === "function" && value.isEqual(FieldValue.delete());

const comparable = (value) => (value instanceof Date ? value.getTime() : value);

/**
 * An in-memory Firestore keyed by document path, with what the deletion
 * service and `transitionPartnerStatus` use: `doc(path)` refs
 * (`get/set/delete/collection`), `collection(path).doc(id)` and
 * `.where(f, "==" | "<=", v)...get()`, `runTransaction` with
 * `tx.get/create/update` (a `FieldValue.delete()` removes the field) and
 * `recursiveDelete(ref)`.
 */
function fakeFirestore(docs = {}) {
  const store = new Map(Object.entries(docs).map(([path, data]) => [path, { ...data }]));
  const ref = (path) => ({
    path,
    id: path.split("/").pop(),
    async get() {
      return snapshot(path);
    },
    async set(data) {
      store.set(path, { ...data });
    },
    async delete() {
      store.delete(path);
    },
    collection: (name) => collection(`${path}/${name}`),
  });
  const snapshot = (path) => {
    const data = store.get(path);
    return {
      id: path.split("/").pop(),
      ref: ref(path),
      exists: data !== undefined,
      data: () => (data === undefined ? undefined : { ...data }),
      get: (field) => data?.[field],
    };
  };
  const query = (path, filters) => ({
    where(field, op, value) {
      assert.ok(op === "==" || op === "<=", `the fake only supports == and <=, got ${op}`);
      return query(path, [...filters, [field, op, value]]);
    },
    async get() {
      const depth = path.split("/").length + 1;
      const docs = [...store.keys()]
        .filter((p) => p.startsWith(`${path}/`) && p.split("/").length === depth)
        .filter((p) =>
          filters.every(([f, op, v]) => {
            const actual = store.get(p)[f];
            if (op === "==") return actual === v;
            return actual !== undefined && comparable(actual) <= comparable(v);
          })
        )
        .map(snapshot);
      return { empty: docs.length === 0, docs };
    },
  });
  const collection = (path) => ({ ...query(path, []), doc: (id) => ref(`${path}/${id}`) });
  return {
    store,
    doc: ref,
    collection,
    async recursiveDelete(target) {
      for (const p of [...store.keys()]) {
        if (p === target.path || p.startsWith(`${target.path}/`)) store.delete(p);
      }
    },
    async runTransaction(fn) {
      const writes = [];
      const tx = {
        async get(r) {
          return snapshot(r.path);
        },
        create(r, data) {
          writes.push(() => store.set(r.path, { ...data }));
        },
        update(r, data) {
          assert.ok(store.has(r.path), `update of missing ${r.path}`);
          writes.push(() => {
            const next = { ...store.get(r.path) };
            for (const [field, value] of Object.entries(data)) {
              if (isDelete(value)) delete next[field];
              else next[field] = value;
            }
            store.set(r.path, next);
          });
        },
      };
      const result = await fn(tx);
      for (const write of writes) write();
      return result;
    },
  };
}

/** A GroupsApi that knows `existing` group e-mails and records every call. */
function fakeGroups(existing = []) {
  const known = new Set(existing);
  const calls = [];
  return {
    calls,
    async lookup(email) {
      calls.push(["lookup", email]);
      return known.has(email) ? `groups/${email}` : null;
    },
    async removeMember(name, email) {
      calls.push(["removeMember", name, email]);
    },
    async addMember(name, email) {
      calls.push(["addMember", name, email]);
    },
  };
}

function requestDeps({ groups = fakeGroups(), direct = [] } = {}) {
  return { groups, directGroups: async () => direct };
}

/** A partner sign-in store: `getUserByEmail` / `deleteUser`, with a
 * `failure` code thrown by `getUserByEmail` when set. */
function fakeAuth({ users = {}, failure = null } = {}) {
  const deleted = [];
  return {
    deleted,
    async getUserByEmail(email) {
      if (failure) throw Object.assign(new Error(failure), { code: failure });
      if (!users[email]) {
        throw Object.assign(new Error("no user"), { code: "auth/user-not-found" });
      }
      return { uid: users[email] };
    },
    async deleteUser(uid) {
      deleted.push(uid);
    },
  };
}

/** Awaits `act` and returns the DeletionError it rejects with. */
async function deletionErrorOf(act) {
  try {
    await act();
  } catch (error) {
    assert.ok(error instanceof DeletionError, `expected DeletionError, got ${error}`);
    return error;
  }
  assert.fail("expected a DeletionError");
}

const activeOwned = (overrides = {}) => ({
  status: "active",
  ownerEmail: EMAIL,
  name: "Rota Sul",
  ...overrides,
});

const pendingRecord = (overrides = {}) => ({
  email: EMAIL,
  uid: "central-uid",
  requestedAt: NOW,
  deleteAt: THIRTY_DAYS_LATER,
  memberships: [{ partnerId: "rotasul", groups: ["rotasul01w@monamienet.org"] }],
  ownedPartners: [],
  ownedNames: {},
  status: "pending",
  ...overrides,
});

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

describe("leavesByPartner - Unit Test Suite", () => {
  test("Happy Path: leaves are grouped by partner", () => {
    // 1. Arrange
    const groups = [
      "rotasul01r@monamienet.org",
      "rotasul01w@monamienet.org",
      "frota02w@monamienet.org",
    ];

    // 2. Act
    const result = leavesByPartner(groups);

    // 3. Assert
    assert.deepEqual(
      result,
      new Map([
        ["rotasul", ["rotasul01r@monamienet.org", "rotasul01w@monamienet.org"]],
        ["frota", ["frota02w@monamienet.org"]],
      ])
    );
  });

  test("Edge Case: an upper-case leaf comes out in lower case", () => {
    // 1. Arrange
    const groups = ["RotaSul13R@MonAmieNet.org"];

    // 2. Act
    const result = leavesByPartner(groups);

    // 3. Assert
    assert.deepEqual(result, new Map([["rotasul", ["rotasul13r@monamienet.org"]]]));
  });

  test("Edge Case: no groups give an empty map", () => {
    // 1. Arrange
    const groups = [];

    // 2. Act
    const result = leavesByPartner(groups);

    // 3. Assert
    assert.equal(result.size, 0);
  });

  test("Happy Path: the root group of an administered partner is left with its leaves", () => {
    // 1. Arrange
    const groups = ["rotasul00@monamienet.org", "rotasul01w@monamienet.org"];

    // 2. Act
    const result = leavesByPartner(groups, ["frota"]);

    // 3. Assert
    assert.deepEqual(
      result,
      new Map([["rotasul", ["rotasul00@monamienet.org", "rotasul01w@monamienet.org"]]])
    );
  });

  test("Edge Case: the root group of an owned partner is kept", () => {
    // 1. Arrange
    const groups = ["rotasul00@monamienet.org", "rotasul01w@monamienet.org"];

    // 2. Act
    const result = leavesByPartner(groups, ["rotasul"]);

    // 3. Assert
    assert.deepEqual(result, new Map([["rotasul", ["rotasul01w@monamienet.org"]]]));
  });

  test("Edge Case: owning one partner does not keep another partner's root group", () => {
    // 1. Arrange
    const groups = ["rotasul00@monamienet.org", "frota00@monamienet.org"];

    // 2. Act
    const result = leavesByPartner(groups, ["rotasul"]);

    // 3. Assert
    assert.deepEqual(result, new Map([["frota", ["frota00@monamienet.org"]]]));
  });

  test("Edge Case: without owned partners every root group is left", () => {
    // 1. Arrange
    const groups = ["RotaSul00@MonAmieNet.org"];

    // 2. Act
    const result = leavesByPartner(groups);

    // 3. Assert
    assert.deepEqual(result, new Map([["rotasul", ["rotasul00@monamienet.org"]]]));
  });

  const ignored = [
    ["a team group", "rotasul01@monamienet.org"],
    ["a root leaf that never exists", "rotasul00r@monamienet.org"],
    ["another domain", "rotasul01r@gmail.com"],
    ["a reserved id", "community01w@monamienet.org"],
    ["a two-letter id", "ab01w@monamienet.org"],
    ["an rw leaf", "rotasul01rw@monamienet.org"],
    ["garbage", "not an e-mail"],
  ];
  for (const [label, email] of ignored) {
    test(`Sad Path: ${label} is ignored`, () => {
      // 1. Arrange
      const groups = [email];

      // 2. Act
      const result = leavesByPartner(groups);

      // 3. Assert
      assert.equal(result.size, 0);
    });
  }
});

describe("requestAccountDeletion - Unit Test Suite", () => {
  test("Happy Path: a member leaves every leaf and a pending record is written", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const groups = fakeGroups(["rotasul01w@monamienet.org", "rotasul02r@monamienet.org"]);
    const deps = requestDeps({
      groups,
      direct: ["rotasul01w@monamienet.org", "rotasul02r@monamienet.org"],
    });

    // 2. Act
    const result = await requestAccountDeletion(db, deps, { email: EMAIL, uid: "u1" }, NOW);

    // 3. Assert
    assert.deepEqual(result, { deleteAt: THIRTY_DAYS_LATER, ownedPartners: [], ownedNames: {} });
    assert.deepEqual(
      groups.calls.filter(([op]) => op === "removeMember"),
      [
        ["removeMember", "groups/rotasul01w@monamienet.org", EMAIL],
        ["removeMember", "groups/rotasul02r@monamienet.org", EMAIL],
      ]
    );
    assert.deepEqual(db.store.get(`accountDeletions/${EMAIL}`), {
      email: EMAIL,
      uid: "u1",
      requestedAt: NOW,
      deleteAt: THIRTY_DAYS_LATER,
      memberships: [
        {
          partnerId: "rotasul",
          groups: ["rotasul01w@monamienet.org", "rotasul02r@monamienet.org"],
        },
      ],
      ownedPartners: [],
      ownedNames: {},
      status: "pending",
    });
  });

  test("Happy Path: a confirmed owner's organizations go to deleting", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      "partners/rotasul": activeOwned(),
      "partners/frota": activeOwned({ name: undefined }),
    });
    const deps = requestDeps();

    // 2. Act
    const result = await requestAccountDeletion(
      db,
      deps,
      { email: EMAIL, uid: "u1", confirmIds: ["rotasul", "frota"] },
      NOW
    );

    // 3. Assert
    assert.deepEqual(result.ownedPartners, ["frota", "rotasul"]);
    assert.deepEqual(result.ownedNames, { rotasul: "Rota Sul" });
    const registry = db.store.get("partners/rotasul");
    assert.equal(registry.status, "deleting");
    assert.deepEqual(registry.deleteAt, THIRTY_DAYS_LATER);
    assert.equal(registry.deletionRequestedBy, EMAIL);
    assert.equal(db.store.get("partners/frota").status, "deleting");
    assert.deepEqual(db.store.get(`accountDeletions/${EMAIL}`).ownedPartners, [
      "frota",
      "rotasul",
    ]);
  });

  test("Happy Path: an administrator who does not own the partner leaves its root group", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "partners/rotasul": activeOwned({ ownerEmail: "bia@x.com" }) });
    const groups = fakeGroups(["rotasul00@monamienet.org", "rotasul01w@monamienet.org"]);
    const deps = requestDeps({
      groups,
      direct: ["rotasul00@monamienet.org", "rotasul01w@monamienet.org"],
    });

    // 2. Act
    const result = await requestAccountDeletion(db, deps, { email: EMAIL, uid: "u1" }, NOW);

    // 3. Assert
    assert.deepEqual(result.ownedPartners, []);
    assert.deepEqual(
      groups.calls.filter(([op]) => op === "removeMember"),
      [
        ["removeMember", "groups/rotasul00@monamienet.org", EMAIL],
        ["removeMember", "groups/rotasul01w@monamienet.org", EMAIL],
      ]
    );
    assert.deepEqual(db.store.get(`accountDeletions/${EMAIL}`).memberships, [
      {
        partnerId: "rotasul",
        groups: ["rotasul00@monamienet.org", "rotasul01w@monamienet.org"],
      },
    ]);
    assert.equal(db.store.get("partners/rotasul").status, "active");
  });

  test("Edge Case: an owner who administers the partner keeps its root group", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "partners/rotasul": activeOwned() });
    const groups = fakeGroups(["rotasul00@monamienet.org", "rotasul01w@monamienet.org"]);
    const deps = requestDeps({
      groups,
      direct: ["rotasul00@monamienet.org", "rotasul01w@monamienet.org"],
    });

    // 2. Act
    await requestAccountDeletion(
      db,
      deps,
      { email: EMAIL, uid: "u1", confirmIds: ["rotasul"] },
      NOW
    );

    // 3. Assert
    assert.deepEqual(
      groups.calls.filter(([op]) => op === "removeMember"),
      [["removeMember", "groups/rotasul01w@monamienet.org", EMAIL]]
    );
    assert.equal(db.store.get("partners/rotasul").status, "deleting");
  });

  test("Edge Case: the e-mail is lower-cased before matching and recording", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "partners/rotasul": activeOwned() });
    const groups = fakeGroups(["rotasul01w@monamienet.org"]);
    const deps = requestDeps({ groups, direct: ["rotasul01w@monamienet.org"] });

    // 2. Act
    await requestAccountDeletion(
      db,
      deps,
      { email: "Ana@X.com", uid: "u1", confirmIds: ["rotasul"] },
      NOW
    );

    // 3. Assert
    assert.equal(db.store.get(`accountDeletions/${EMAIL}`).email, EMAIL);
    assert.equal(db.store.get("partners/rotasul").status, "deleting");
    assert.deepEqual(groups.calls.at(-1), [
      "removeMember",
      "groups/rotasul01w@monamienet.org",
      EMAIL,
    ]);
  });

  test("Edge Case: a leaf whose group is not found is skipped but still recorded", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const groups = fakeGroups([]);
    const deps = requestDeps({ groups, direct: ["rotasul01w@monamienet.org"] });

    // 2. Act
    await requestAccountDeletion(db, deps, { email: EMAIL, uid: "u1" }, NOW);

    // 3. Assert
    assert.deepEqual(
      groups.calls.filter(([op]) => op === "removeMember"),
      []
    );
    assert.deepEqual(db.store.get(`accountDeletions/${EMAIL}`).memberships, [
      { partnerId: "rotasul", groups: ["rotasul01w@monamienet.org"] },
    ]);
  });

  test("Edge Case: organizations not active or owned by others are not touched", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      "partners/frota": activeOwned({ status: "failed" }),
      "partners/outra": activeOwned({ ownerEmail: "bia@x.com" }),
    });
    const deps = requestDeps();

    // 2. Act
    const result = await requestAccountDeletion(db, deps, { email: EMAIL, uid: "u1" }, NOW);

    // 3. Assert
    assert.deepEqual(result.ownedPartners, []);
    assert.equal(db.store.get("partners/frota").status, "failed");
    assert.equal(db.store.get("partners/outra").status, "active");
  });

  test("Sad Path: an owner who did not confirm is refused before anything changes", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      "partners/rotasul": activeOwned(),
      "partners/frota": activeOwned(),
    });
    const groups = fakeGroups(["rotasul01w@monamienet.org"]);
    const deps = requestDeps({ groups, direct: ["rotasul01w@monamienet.org"] });

    // 2. Act
    const error = await deletionErrorOf(() =>
      requestAccountDeletion(db, deps, { email: EMAIL, uid: "u1", confirmIds: ["rotasul"] }, NOW)
    );

    // 3. Assert
    assert.equal(error.code, "confirm");
    assert.equal(db.store.get("partners/rotasul").status, "active");
    assert.equal(db.store.get("partners/frota").status, "active");
    assert.equal(db.store.has(`accountDeletions/${EMAIL}`), false);
    assert.deepEqual(
      groups.calls.filter(([op]) => op === "removeMember"),
      []
    );
  });
});

describe("pendingDeletion - Unit Test Suite", () => {
  test("Happy Path: a pending record is returned", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      [`accountDeletions/${EMAIL}`]: pendingRecord({
        ownedPartners: ["rotasul"],
        ownedNames: { rotasul: "Rota Sul" },
      }),
    });

    // 2. Act
    const result = await pendingDeletion(db, EMAIL);

    // 3. Assert
    assert.deepEqual(result, {
      requestedAt: NOW,
      deleteAt: THIRTY_DAYS_LATER,
      ownedPartners: ["rotasul"],
      ownedNames: { rotasul: "Rota Sul" },
    });
  });

  test("Edge Case: Firestore Timestamps are converted to Dates", async () => {
    // 1. Arrange
    const timestamp = (date) => ({ toDate: () => date });
    const db = fakeFirestore({
      [`accountDeletions/${EMAIL}`]: pendingRecord({
        requestedAt: timestamp(NOW),
        deleteAt: timestamp(THIRTY_DAYS_LATER),
      }),
    });

    // 2. Act
    const result = await pendingDeletion(db, EMAIL);

    // 3. Assert
    assert.deepEqual(result.requestedAt, NOW);
    assert.deepEqual(result.deleteAt, THIRTY_DAYS_LATER);
  });

  test("Edge Case: a record that is no longer pending reads as null", async () => {
    // 1. Arrange
    const db = fakeFirestore({ [`accountDeletions/${EMAIL}`]: pendingRecord({ status: "done" }) });

    // 2. Act
    const result = await pendingDeletion(db, EMAIL);

    // 3. Assert
    assert.equal(result, null);
  });

  test("Sad Path: no record reads as null", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const result = await pendingDeletion(db, EMAIL);

    // 3. Assert
    assert.equal(result, null);
  });
});

describe("cancelAccountDeletion - Unit Test Suite", () => {
  test("Happy Path: rejoins the leaves, reactivates the organization and drops the record", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      "partners/rotasul": activeOwned({ status: "deleting", deleteAt: THIRTY_DAYS_LATER }),
      [`accountDeletions/${EMAIL}`]: pendingRecord({ ownedPartners: ["rotasul"] }),
    });
    const groups = fakeGroups(["rotasul01w@monamienet.org"]);

    // 2. Act
    await cancelAccountDeletion(db, { groups }, EMAIL, NOW);

    // 3. Assert
    assert.deepEqual(
      groups.calls.filter(([op]) => op === "addMember"),
      [["addMember", "groups/rotasul01w@monamienet.org", EMAIL]]
    );
    const registry = db.store.get("partners/rotasul");
    assert.equal(registry.status, "active");
    assert.equal("deleteAt" in registry, false);
    assert.equal(db.store.has(`accountDeletions/${EMAIL}`), false);
  });

  test("Happy Path: a recorded root group is rejoined like the leaves", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      [`accountDeletions/${EMAIL}`]: pendingRecord({
        memberships: [
          {
            partnerId: "rotasul",
            groups: ["rotasul00@monamienet.org", "rotasul01w@monamienet.org"],
          },
        ],
      }),
    });
    const groups = fakeGroups(["rotasul00@monamienet.org", "rotasul01w@monamienet.org"]);

    // 2. Act
    await cancelAccountDeletion(db, { groups }, EMAIL, NOW);

    // 3. Assert
    assert.deepEqual(
      groups.calls.filter(([op]) => op === "addMember"),
      [
        ["addMember", "groups/rotasul00@monamienet.org", EMAIL],
        ["addMember", "groups/rotasul01w@monamienet.org", EMAIL],
      ]
    );
  });

  test("Edge Case: a recorded leaf whose group is gone is skipped", async () => {
    // 1. Arrange
    const db = fakeFirestore({ [`accountDeletions/${EMAIL}`]: pendingRecord() });
    const groups = fakeGroups([]);

    // 2. Act
    await cancelAccountDeletion(db, { groups }, EMAIL, NOW);

    // 3. Assert
    assert.deepEqual(
      groups.calls.filter(([op]) => op === "addMember"),
      []
    );
    assert.equal(db.store.has(`accountDeletions/${EMAIL}`), false);
  });

  test("Edge Case: an owned organization that can no longer be reactivated is skipped", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      "partners/frota": activeOwned({ status: "failed" }),
      [`accountDeletions/${EMAIL}`]: pendingRecord({ ownedPartners: ["gone", "frota"] }),
    });
    const groups = fakeGroups([]);

    // 2. Act
    await cancelAccountDeletion(db, { groups }, EMAIL, NOW);

    // 3. Assert
    assert.equal(db.store.get("partners/frota").status, "failed");
    assert.equal(db.store.has("partners/gone"), false);
    assert.equal(db.store.has(`accountDeletions/${EMAIL}`), false);
  });

  test("Edge Case: an upper-case e-mail finds the record", async () => {
    // 1. Arrange
    const db = fakeFirestore({ [`accountDeletions/${EMAIL}`]: pendingRecord() });
    const groups = fakeGroups(["rotasul01w@monamienet.org"]);

    // 2. Act
    await cancelAccountDeletion(db, { groups }, "ANA@x.com", NOW);

    // 3. Assert
    assert.equal(db.store.has(`accountDeletions/${EMAIL}`), false);
  });

  test("Sad Path: nothing pending is refused with code none", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const groups = fakeGroups();

    // 2. Act
    const error = await deletionErrorOf(() => cancelAccountDeletion(db, { groups }, EMAIL, NOW));

    // 3. Assert
    assert.equal(error.code, "none");
  });

  test("Sad Path: a deadline that has passed is refused with code late", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      [`accountDeletions/${EMAIL}`]: pendingRecord({ deleteAt: NOW }),
    });
    const groups = fakeGroups(["rotasul01w@monamienet.org"]);

    // 2. Act
    const error = await deletionErrorOf(() => cancelAccountDeletion(db, { groups }, EMAIL, NOW));

    // 3. Assert
    assert.equal(error.code, "late");
    assert.equal(db.store.has(`accountDeletions/${EMAIL}`), true);
    assert.deepEqual(groups.calls, []);
  });
});

describe("eraseDueAccounts - Unit Test Suite", () => {
  /** A partner project holding Ana's trail, a day summary and profiles. */
  function partnerWithAna() {
    const db = fakeFirestore({
      [`partners/rotasul/usuarios/${EMAIL}`]: { nome: "Ana" },
      [`partners/rotasul/usuarios/${EMAIL}/historico_posicoes/p1`]: { lat: 1 },
      [`partners/rotasul/usuarios/${EMAIL}/dias/2026-10-01`]: { count: 3 },
      "partners/rotasul/usuarios/bia@x.com": { nome: "Bia" },
      "partners/rotasul/users/uid-ana": { email: EMAIL },
      "partners/rotasul/users/uid-bia": { email: "bia@x.com" },
    });
    const auth = fakeAuth({ users: { [EMAIL]: "partner-uid-ana" } });
    return { db, auth };
  }

  test("Happy Path: a due account is erased everywhere", async () => {
    // 1. Arrange
    const central = fakeFirestore({ [`accountDeletions/${EMAIL}`]: pendingRecord({ deleteAt: NOW }) });
    const partner = partnerWithAna();
    const deletedCentral = [];
    const deps = {
      partner: async (id) => (id === "rotasul" ? partner : null),
      deleteAuthUser: async (uid) => deletedCentral.push(uid),
    };

    // 2. Act
    const erased = await eraseDueAccounts(central, deps, NOW);

    // 3. Assert
    assert.deepEqual(erased, [EMAIL]);
    assert.deepEqual(
      [...partner.db.store.keys()].sort(),
      ["partners/rotasul/users/uid-bia", "partners/rotasul/usuarios/bia@x.com"]
    );
    assert.deepEqual(partner.auth.deleted, ["partner-uid-ana"]);
    assert.deepEqual(deletedCentral, ["central-uid"]);
    assert.equal(central.store.has(`accountDeletions/${EMAIL}`), false);
  });

  test("Edge Case: accounts not yet due or not pending are left alone", async () => {
    // 1. Arrange
    const central = fakeFirestore({
      [`accountDeletions/${EMAIL}`]: pendingRecord(),
      "accountDeletions/bia@x.com": pendingRecord({
        email: "bia@x.com",
        deleteAt: NOW,
        status: "cancelled",
      }),
    });
    const partner = partnerWithAna();
    const deps = { partner: async () => partner, deleteAuthUser: async () => {} };

    // 2. Act
    const erased = await eraseDueAccounts(central, deps, NOW);

    // 3. Assert
    assert.deepEqual(erased, []);
    assert.equal(central.store.size, 2);
    assert.equal(partner.db.store.size, 6);
  });

  test("Edge Case: a partner that no longer exists is skipped", async () => {
    // 1. Arrange
    const central = fakeFirestore({ [`accountDeletions/${EMAIL}`]: pendingRecord({ deleteAt: NOW }) });
    const deps = { partner: async () => null, deleteAuthUser: async () => {} };

    // 2. Act
    const erased = await eraseDueAccounts(central, deps, NOW);

    // 3. Assert
    assert.deepEqual(erased, [EMAIL]);
    assert.equal(central.store.has(`accountDeletions/${EMAIL}`), false);
  });

  test("Edge Case: sign-ins already gone are ignored", async () => {
    // 1. Arrange
    const central = fakeFirestore({ [`accountDeletions/${EMAIL}`]: pendingRecord({ deleteAt: NOW }) });
    const partner = { db: fakeFirestore(), auth: fakeAuth() };
    const notFound = Object.assign(new Error("gone"), { code: "auth/user-not-found" });
    const deps = {
      partner: async () => partner,
      deleteAuthUser: async () => {
        throw notFound;
      },
    };

    // 2. Act
    const erased = await eraseDueAccounts(central, deps, NOW);

    // 3. Assert
    assert.deepEqual(erased, [EMAIL]);
    assert.equal(central.store.has(`accountDeletions/${EMAIL}`), false);
  });

  test("Edge Case: without a uid the central sign-in is not deleted", async () => {
    // 1. Arrange
    const central = fakeFirestore({
      [`accountDeletions/${EMAIL}`]: pendingRecord({ deleteAt: NOW, uid: null }),
    });
    const deletedCentral = [];
    const deps = {
      partner: async () => null,
      deleteAuthUser: async (uid) => deletedCentral.push(uid),
    };

    // 2. Act
    await eraseDueAccounts(central, deps, NOW);

    // 3. Assert
    assert.deepEqual(deletedCentral, []);
  });

  test("Sad Path: another partner sign-in error propagates and keeps the record", async () => {
    // 1. Arrange
    const central = fakeFirestore({ [`accountDeletions/${EMAIL}`]: pendingRecord({ deleteAt: NOW }) });
    const partner = { db: fakeFirestore(), auth: fakeAuth({ failure: "auth/internal-error" }) };
    const deps = { partner: async () => partner, deleteAuthUser: async () => {} };

    // 2. Act
    const act = eraseDueAccounts(central, deps, NOW);

    // 3. Assert
    await assert.rejects(act, { code: "auth/internal-error" });
    assert.equal(central.store.has(`accountDeletions/${EMAIL}`), true);
  });

  test("Sad Path: another central sign-in error propagates", async () => {
    // 1. Arrange
    const central = fakeFirestore({ [`accountDeletions/${EMAIL}`]: pendingRecord({ deleteAt: NOW }) });
    const deps = {
      partner: async () => null,
      deleteAuthUser: async () => {
        throw Object.assign(new Error("boom"), { code: "auth/internal-error" });
      },
    };

    // 2. Act
    const act = eraseDueAccounts(central, deps, NOW);

    // 3. Assert
    await assert.rejects(act, { code: "auth/internal-error" });
  });
});
