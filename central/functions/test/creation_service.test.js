const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { checkOrganizationId, createOrganization, myCreations } = require("../creation_service");
const { CreationError } = require("../organization_creation");
const { fakeFirestore } = require("./fake_firestore");

const NOW = new Date("2026-10-26T12:00:00.000Z");
const SEVEN_DAYS_LATER = new Date("2026-11-02T12:00:00.000Z");
const ACTIVE_THEMES = new Set(["grafite", "oceano"]);
/** personKey("dono@x.com"), computed once with `sha256sum`. */
const OWNER_KEY = "cae28455d02087f78701c78329a53cf76712bf86f45c15de24a3509977e34e57";

/** A Community Firestore whose every write rejects. */
function failingCommunityDb() {
  const fail = async () => {
    throw new Error("community firestore unavailable");
  };
  const doc = () => ({ set: fail, collection: () => ({ doc }) });
  return { doc };
}

/** A Community Firestore that keeps the configuration but rejects the
 * owner's organization membership. */
function membershipFailingCommunityDb() {
  const db = fakeFirestore();
  const doc = db.doc;
  db.doc = (path) =>
    path.includes("/organizationMemberships/")
      ? {
          async set() {
            throw new Error("membership write refused");
          },
        }
      : doc(path);
  return db;
}

function deps(overrides = {}) {
  const projects = [];
  return {
    communityDb: fakeFirestore(),
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
  createOrganization(db, d, request(overrides), ACTIVE_THEMES, NOW);

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

describe("checkOrganizationId - Unit Test Suite", () => {
  test("Happy Path: a free id is available", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const result = await checkOrganizationId(db, "rotasul");

    // 3. Assert
    assert.deepEqual(result, { available: true, problem: null });
  });

  test("Sad Path: a bad format is unavailable with its problem", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const result = await checkOrganizationId(db, "Rota Sul");

    // 3. Assert
    assert.equal(result.available, false);
    assert.equal(typeof result.problem, "string");
  });

  test("Sad Path: a bad format is answered without reading the registry", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await checkOrganizationId(db, "ab");

    // 3. Assert
    assert.equal(db.reads, 0);
  });

  const taken = [
    ["already in the registry", { "organizations/rotasul": { status: "active" } }],
    ["retired", { "retiredOrganizationIds/rotasul": { retiredAt: NOW } }],
  ];
  for (const [why, docs] of taken) {
    test(`Sad Path: an id ${why} is unavailable`, async () => {
      // 1. Arrange
      const db = fakeFirestore(docs);

      // 2. Act
      const result = await checkOrganizationId(db, "rotasul");

      // 3. Assert
      assert.equal(result.available, false);
      assert.equal(typeof result.problem, "string");
    });
  }
});

describe("createOrganization (Community) - Unit Test Suite", () => {
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
    assert.deepEqual(db.statuses.get("organizations/rotasul"), ["reserved", "provisioning", "active"]);
  });

  test("Happy Path: the registry keeps name, theme, plan, owner (lower case) and createdAt", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await create(db, deps());

    // 3. Assert
    const doc = db.store.get("organizations/rotasul");
    assert.equal(doc.name, "Rota Sul");
    assert.equal(doc.themeId, "oceano");
    assert.equal(doc.plan, "community");
    assert.equal(doc.ownerEmail, "dono@x.com");
    assert.equal(doc.createdAt.toISOString(), NOW.toISOString());
  });

  test("Happy Path: makes the owner an administrator in the Community project", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const d = deps();

    // 2. Act
    await create(db, d);

    // 3. Assert
    assert.deepEqual(d.communityDb.store.get(`organizations/rotasul/organizationMemberships/${OWNER_KEY}`), {
      email: "dono@x.com",
      role: "admin",
      addedAt: NOW,
    });
  });

  test("Happy Path: adds the organization to the owner's accounts entry", async () => {
    // 1. Arrange
    const db = fakeFirestore({ [`accounts/${OWNER_KEY}`]: { email: "dono@x.com", organizationIds: ["outra"] } });

    // 2. Act
    await create(db, deps());

    // 3. Assert
    assert.deepEqual(db.store.get(`accounts/${OWNER_KEY}`).organizationIds, ["outra", "rotasul"]);
  });

  test("Happy Path: writes branding and plan to the Community project", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const d = deps();

    // 2. Act
    await create(db, d);

    // 3. Assert
    const branding = d.communityDb.store.get("organizations/rotasul/config/branding");
    assert.equal(branding.name, "Rota Sul");
    assert.equal(branding.themeId, "oceano");
    assert.equal(branding.updatedAt.toISOString(), NOW.toISOString());
    assert.deepEqual(d.communityDb.store.get("organizations/rotasul/config/plan"), {
      minIntervalMinutes: 15,
    });
  });

  const failures = [
    [
      "the Community Firestore write",
      () => deps({ communityDb: failingCommunityDb() }),
      "data",
      "community firestore unavailable",
    ],
    [
      "the owner's membership write",
      () => deps({ communityDb: membershipFailingCommunityDb() }),
      "membership",
      "membership write refused",
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
      const doc = db.store.get("organizations/rotasul");
      assert.equal(doc.status, "failed");
      assert.deepEqual(doc.failure, { step, message });
    });
  }
});

describe("createOrganization (Standard) - Unit Test Suite", () => {
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
    const doc = db.store.get("organizations/rotasul");
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
    const doc = db.store.get("organizations/rotasul");
    assert.equal(doc.status, "failed");
    assert.equal(doc.failure.step, "project");
  });
});

describe("createOrganization (refusals) - Unit Test Suite", () => {
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
      assert.equal(db.store.size, 0);
    });
  }

  const taken = [
    ["taken", { "organizations/rotasul": { status: "active", ownerEmail: "outro@x.com" } }],
    ["retired", { "retiredOrganizationIds/rotasul": { retiredAt: NOW } }],
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

  test("Sad Path: a taken id leaves the existing registry entry untouched", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "organizations/rotasul": { status: "active", ownerEmail: "outro@x.com" } });
    const d = deps();

    // 2. Act
    await create(db, d).catch(() => {});

    // 3. Assert
    assert.deepEqual(db.store.get("organizations/rotasul"), { status: "active", ownerEmail: "outro@x.com" });
    assert.equal(d.communityDb.store.size, 0);
  });
});

describe("myCreations - Unit Test Suite", () => {
  const registry = {
    "organizations/aaa": { status: "reserved", ownerEmail: "dono@x.com", name: "Aaa", plan: "community" },
    "organizations/bbb": { status: "awaiting_billing", ownerEmail: "dono@x.com", name: "Bbb", plan: "standard" },
    "organizations/ccc": { status: "provisioning", ownerEmail: "dono@x.com", name: "Ccc", plan: "community" },
    "organizations/ddd": {
      status: "failed",
      ownerEmail: "dono@x.com",
      name: "Ddd",
      plan: "community",
      failure: { step: "data", message: "boom" },
    },
    "organizations/eee": { status: "active", ownerEmail: "dono@x.com", name: "Eee", plan: "community" },
    "organizations/fff": { status: "reserved", ownerEmail: "outro@x.com", name: "Fff", plan: "community" },
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
    assert.equal(result.find((c) => c.id === "ddd").failureStep, "data");
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

describe("createOrganization (owner's access) - Unit Test Suite", () => {
  test("Edge Case: a failed membership write adds nothing to the owner's accounts entry", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    await create(db, deps({ communityDb: membershipFailingCommunityDb() }));

    // 3. Assert
    assert.equal(db.store.has(`accounts/${OWNER_KEY}`), false);
  });
});
