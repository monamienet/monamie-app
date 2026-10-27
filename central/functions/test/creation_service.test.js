const { describe, test } = require("node:test");
const assert = require("node:assert/strict");
const { FieldValue } = require("firebase-admin/firestore");

const { checkPartnerId, createPartner, myCreations } = require("../creation_service");
const { CreationError } = require("../partner_creation");

const CUSTOMER = "customers/C0abc";
const NOW = new Date("2026-10-26T12:00:00.000Z");
const SEVEN_DAYS_LATER = new Date("2026-11-02T12:00:00.000Z");
const ACTIVE_THEMES = new Set(["grafite", "oceano"]);
const ROOT = "rotasul00@monamienet.org";

const isDelete = (value) =>
  value !== null && typeof value?.isEqual === "function" && value.isEqual(FieldValue.delete());

/**
 * An in-memory central Firestore with what the creation service and
 * `transitionPartnerStatus` use: `doc(path).get()`, `runTransaction` with
 * `tx.get/create/update` (a `FieldValue.delete()` removes the field) and
 * `collection(c).where(f, "==" | "in", v)...get()`. `reads` counts every
 * read; `statuses` keeps each status written, by path, in order.
 */
function fakeFirestore(docs = {}) {
  const store = new Map(Object.entries(docs).map(([path, data]) => [path, { ...data }]));
  const statuses = new Map();
  let reads = 0;
  let transactions = 0;
  const snapshot = (path) => {
    const data = store.get(path);
    return {
      id: path.split("/").pop(),
      exists: data !== undefined,
      data: () => (data === undefined ? undefined : { ...data }),
      get: (field) => data?.[field],
    };
  };
  const noteStatus = (path, data) => {
    if (data.status !== undefined) statuses.set(path, [...(statuses.get(path) ?? []), data.status]);
  };
  const query = (collection, filters) => ({
    where(field, op, value) {
      assert.ok(op === "==" || op === "in", `the fake only supports == and in, got ${op}`);
      return query(collection, [...filters, [field, op, value]]);
    },
    async get() {
      reads++;
      const docs = [...store.keys()]
        .filter((path) => path.startsWith(`${collection}/`) && path.split("/").length === 2)
        .filter((path) =>
          filters.every(([f, op, v]) =>
            op === "==" ? store.get(path)[f] === v : v.includes(store.get(path)[f])
          )
        )
        .map(snapshot);
      return { empty: docs.length === 0, docs };
    },
  });
  return {
    store,
    statuses,
    get reads() {
      return reads;
    },
    get transactions() {
      return transactions;
    },
    doc(path) {
      return {
        path,
        async get() {
          reads++;
          return snapshot(path);
        },
      };
    },
    collection(name) {
      return query(name, []);
    },
    async runTransaction(fn) {
      transactions++;
      const writes = [];
      const tx = {
        async get(ref) {
          reads++;
          return snapshot(ref.path);
        },
        create(ref, data) {
          assert.equal(store.has(ref.path), false, `create over existing ${ref.path}`);
          writes.push(() => {
            store.set(ref.path, { ...data });
            noteStatus(ref.path, data);
          });
        },
        update(ref, data) {
          assert.ok(store.has(ref.path), `update of missing ${ref.path}`);
          writes.push(() => {
            const next = { ...store.get(ref.path) };
            for (const [field, value] of Object.entries(data)) {
              if (isDelete(value)) delete next[field];
              else next[field] = value;
            }
            store.set(ref.path, next);
            noteStatus(ref.path, data);
          });
        },
      };
      const result = await fn(tx);
      for (const write of writes) write();
      return result;
    },
  };
}

/** The shared Community Firestore: `doc(p).collection(c).doc(d).set(data)`;
 * every set rejects when `failing` is set. */
function fakeCommunityDb({ failing = false } = {}) {
  const store = new Map();
  const doc = (path) => ({
    collection: (name) => ({ doc: (id) => doc(`${path}/${name}/${id}`) }),
    async set(data) {
      if (failing) throw new Error("community firestore unavailable");
      store.set(path, { ...data });
    },
  });
  return { store, doc };
}

/** An in-memory GroupsApi recording calls; `failCreate` makes `create` reject. */
function fakeGroupsApi({ existing = [], failCreate = false } = {}) {
  const groups = new Set(existing);
  const calls = [];
  return {
    calls,
    async lookup(email) {
      calls.push(["lookup", email]);
      return groups.has(email) ? `groups/${email}` : null;
    },
    async create(email, displayName, customer) {
      calls.push(["create", email, displayName, customer]);
      if (failCreate) throw new Error("cloud identity refused");
      groups.add(email);
      return `groups/${email}`;
    },
    async setMonAmieSettings(email) {
      calls.push(["setMonAmieSettings", email]);
    },
    async addMember(name, email) {
      calls.push(["addMember", name, email]);
    },
  };
}

function deps(overrides = {}) {
  const projects = [];
  return {
    groups: fakeGroupsApi(),
    communityDb: fakeCommunityDb(),
    customer: CUSTOMER,
    projects,
    async createStandardProject(id, ownerEmail) {
      projects.push([id, ownerEmail]);
    },
    ...overrides,
  };
}

function request(overrides = {}) {
  return {
    id: "rotasul",
    name: "Rota Sul",
    themeId: "oceano",
    plan: "community",
    ownerEmail: "Dono@X.com",
    ...overrides,
  };
}

const create = (db, d, overrides = {}) =>
  createPartner(db, d, request(overrides), ACTIVE_THEMES, NOW);

/** Awaits `act` and returns the CreationError it rejects with. */
async function creationErrorOf(act) {
  try {
    await act();
  } catch (error) {
    assert.ok(error instanceof CreationError, `expected CreationError, got ${error}`);
    return error;
  }
  assert.fail("expected a CreationError");
}

describe("checkPartnerId - Unit Test Suite", () => {
  test("Happy Path: a free id is available", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const result = await checkPartnerId(db, "rotasul");

    // 3. Assert
    assert.deepEqual(result, { available: true, problem: null });
  });

  test("Sad Path: a bad format is unavailable with its problem", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const result = await checkPartnerId(db, "Rota Sul");

    // 3. Assert
    assert.equal(result.available, false);
    assert.equal(typeof result.problem, "string");
  });

  test("Sad Path: a bad format is answered without reading the registry", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await checkPartnerId(db, "ab");

    // 3. Assert
    assert.equal(db.reads, 0);
  });

  const taken = [
    ["already in the registry", { "partners/rotasul": { status: "active" } }],
    ["retired", { "retiredPartnerIds/rotasul": { retiredAt: NOW } }],
  ];
  for (const [why, docs] of taken) {
    test(`Sad Path: an id ${why} is unavailable`, async () => {
      // 1. Arrange
      const db = fakeFirestore(docs);

      // 2. Act
      const result = await checkPartnerId(db, "rotasul");

      // 3. Assert
      assert.equal(result.available, false);
      assert.equal(typeof result.problem, "string");
    });
  }
});

describe("createPartner (Community) - Unit Test Suite", () => {
  test("Happy Path: returns the id as active", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const result = await create(db, deps());

    // 3. Assert
    assert.deepEqual(result, { id: "rotasul", status: "active" });
  });

  test("Happy Path: the registry goes reserved -> provisioning -> active", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await create(db, deps());

    // 3. Assert
    assert.deepEqual(db.statuses.get("partners/rotasul"), ["reserved", "provisioning", "active"]);
  });

  test("Happy Path: the registry keeps name, theme, plan, owner (lower case) and createdAt", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await create(db, deps());

    // 3. Assert
    const doc = db.store.get("partners/rotasul");
    assert.equal(doc.name, "Rota Sul");
    assert.equal(doc.themeId, "oceano");
    assert.equal(doc.plan, "community");
    assert.equal(doc.ownerEmail, "dono@x.com");
    assert.equal(doc.createdAt.toISOString(), NOW.toISOString());
  });

  test("Happy Path: creates the root group, applies the settings and adds the owner", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const d = deps();

    // 2. Act
    await create(db, d);

    // 3. Assert
    const writes = d.groups.calls.filter(([op]) => op !== "lookup");
    assert.deepEqual(writes, [
      ["create", ROOT, "Rota Sul", CUSTOMER],
      ["setMonAmieSettings", ROOT],
      ["addMember", `groups/${ROOT}`, "dono@x.com"],
    ]);
  });

  test("Happy Path: writes branding and plan to the Community project", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const d = deps();

    // 2. Act
    await create(db, d);

    // 3. Assert
    const branding = d.communityDb.store.get("partners/rotasul/config/branding");
    assert.equal(branding.name, "Rota Sul");
    assert.equal(branding.themeId, "oceano");
    assert.equal(branding.updatedAt.toISOString(), NOW.toISOString());
    assert.deepEqual(d.communityDb.store.get("partners/rotasul/config/plan"), {
      minIntervalMinutes: 15,
    });
  });

  test("Edge Case: an existing root group is not created again, the owner is still added", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const d = deps({ groups: fakeGroupsApi({ existing: [ROOT] }) });

    // 2. Act
    await create(db, d);

    // 3. Assert
    const writes = d.groups.calls.filter(([op]) => op !== "lookup");
    assert.deepEqual(writes, [["addMember", `groups/${ROOT}`, "dono@x.com"]]);
  });

  const failures = [
    ["group creation", () => deps({ groups: fakeGroupsApi({ failCreate: true }) }), "group", "cloud identity refused"],
    [
      "the Community Firestore write",
      () => deps({ communityDb: fakeCommunityDb({ failing: true }) }),
      "data",
      "community firestore unavailable",
    ],
  ];
  for (const [why, makeDeps, step, message] of failures) {
    test(`Sad Path: failing ${why} returns failed without throwing`, async () => {
      // 1. Arrange
      const db = fakeFirestore();

      // 2. Act
      const result = await create(db, makeDeps());

      // 3. Assert
      assert.equal(result.status, "failed");
    });

    test(`Sad Path: failing ${why} leaves the registry failed at step '${step}'`, async () => {
      // 1. Arrange
      const db = fakeFirestore();

      // 2. Act
      await create(db, makeDeps());

      // 3. Assert
      const doc = db.store.get("partners/rotasul");
      assert.equal(doc.status, "failed");
      assert.deepEqual(doc.failure, { step, message });
    });
  }
});

describe("createPartner (Standard) - Unit Test Suite", () => {
  test("Happy Path: creates the project for the owner and returns awaiting_billing", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const d = deps();

    // 2. Act
    const result = await create(db, d, { plan: "standard" });

    // 3. Assert
    assert.deepEqual(result, { id: "rotasul", status: "awaiting_billing" });
    assert.deepEqual(d.projects, [["rotasul", "dono@x.com"]]);
  });

  test("Happy Path: awaiting_billing gets a deleteAt 7 days later", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await create(db, deps(), { plan: "standard" });

    // 3. Assert
    const doc = db.store.get("partners/rotasul");
    assert.equal(doc.status, "awaiting_billing");
    assert.equal(doc.deleteAt.toISOString(), SEVEN_DAYS_LATER.toISOString());
  });

  test("Sad Path: a failing project creation leaves the registry failed at step 'project'", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const d = deps({
      async createStandardProject() {
        throw new Error("quota exceeded");
      },
    });

    // 2. Act
    const result = await create(db, d, { plan: "standard" });

    // 3. Assert
    assert.equal(result.status, "failed");
    const doc = db.store.get("partners/rotasul");
    assert.equal(doc.status, "failed");
    assert.equal(doc.failure.step, "project");
  });
});

describe("createPartner (refusals) - Unit Test Suite", () => {
  const invalid = [
    ["a bad id", { id: "Rota" }, "id"],
    ["a short name", { name: "R" }, "name"],
    ["an inactive theme", { themeId: "lava" }, "themeId"],
    ["an unknown plan", { plan: "premium" }, "plan"],
  ];
  for (const [why, overrides, code] of invalid) {
    test(`Sad Path: ${why} throws CreationError '${code}'`, async () => {
      // 1. Arrange
      const db = fakeFirestore();

      // 2. Act
      const error = await creationErrorOf(() => create(db, deps(), overrides));

      // 3. Assert
      assert.equal(error.code, code);
    });

    test(`Sad Path: ${why} does not touch the registry`, async () => {
      // 1. Arrange
      const db = fakeFirestore();

      // 2. Act
      await create(db, deps(), overrides).catch(() => {});

      // 3. Assert
      assert.equal(db.transactions, 0);
      assert.equal(db.store.size, 0);
    });
  }

  const taken = [
    ["taken", { "partners/rotasul": { status: "active", ownerEmail: "outro@x.com" } }],
    ["retired", { "retiredPartnerIds/rotasul": { retiredAt: NOW } }],
  ];
  for (const [why, docs] of taken) {
    test(`Sad Path: a ${why} id throws CreationError 'id'`, async () => {
      // 1. Arrange
      const db = fakeFirestore(docs);

      // 2. Act
      const error = await creationErrorOf(() => create(db, deps()));

      // 3. Assert
      assert.equal(error.code, "id");
    });
  }

  test("Sad Path: a taken id leaves the existing registry entry and groups untouched", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "partners/rotasul": { status: "active", ownerEmail: "outro@x.com" } });
    const d = deps();

    // 2. Act
    await create(db, d).catch(() => {});

    // 3. Assert
    assert.deepEqual(db.store.get("partners/rotasul"), { status: "active", ownerEmail: "outro@x.com" });
    assert.deepEqual(d.groups.calls, []);
  });
});

describe("myCreations - Unit Test Suite", () => {
  const registry = {
    "partners/aaa": { status: "reserved", ownerEmail: "dono@x.com", name: "Aaa", plan: "community" },
    "partners/bbb": { status: "awaiting_billing", ownerEmail: "dono@x.com", name: "Bbb", plan: "standard" },
    "partners/ccc": { status: "provisioning", ownerEmail: "dono@x.com", name: "Ccc", plan: "community" },
    "partners/ddd": {
      status: "failed",
      ownerEmail: "dono@x.com",
      name: "Ddd",
      plan: "community",
      failure: { step: "group", message: "boom" },
    },
    "partners/eee": { status: "active", ownerEmail: "dono@x.com", name: "Eee", plan: "community" },
    "partners/fff": { status: "reserved", ownerEmail: "outro@x.com", name: "Fff", plan: "community" },
  };

  test("Happy Path: lists the caller's organizations still being created", async () => {
    // 1. Arrange
    const db = fakeFirestore(registry);

    // 2. Act
    const result = await myCreations(db, "dono@x.com");

    // 3. Assert
    assert.deepEqual(result.map((c) => c.id).sort(), ["aaa", "bbb", "ccc", "ddd"]);
  });

  test("Happy Path: a failed creation carries its failureStep", async () => {
    // 1. Arrange
    const db = fakeFirestore(registry);

    // 2. Act
    const result = await myCreations(db, "dono@x.com");

    // 3. Assert
    assert.equal(result.find((c) => c.id === "ddd").failureStep, "group");
  });

  test("Edge Case: the e-mail is matched case-insensitively", async () => {
    // 1. Arrange
    const db = fakeFirestore(registry);

    // 2. Act
    const result = await myCreations(db, "Dono@X.COM");

    // 3. Assert
    assert.equal(result.length, 4);
  });

  test("Sad Path: someone who creates nothing gets an empty list", async () => {
    // 1. Arrange
    const db = fakeFirestore(registry);

    // 2. Act
    const result = await myCreations(db, "ninguem@x.com");

    // 3. Assert
    assert.deepEqual(result, []);
  });
});
