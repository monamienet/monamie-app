const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  canTransition,
  dueOrganizationIds,
  retireOrganization,
  statusFields,
} = require("../organization_status");

const NOW = new Date("2026-10-26T12:00:00.000Z");
const SEVEN_DAYS_LATER = new Date("2026-11-02T12:00:00.000Z");
const THIRTY_DAYS_LATER = new Date("2026-11-25T12:00:00.000Z");

/**
 * An in-memory central Firestore with the few methods `retireOrganization` uses.
 * Every read and write is appended to `log`, so a test can check the order.
 */
function fakeDb(documents = {}) {
  const store = new Map(Object.entries(documents));
  const log = [];
  const db = {
    store,
    log,
    doc(path) {
      return {
        path,
        async get() {
          log.push(["get", path]);
          const data = store.get(path);
          return { exists: data !== undefined, data: () => data };
        },
      };
    },
    batch() {
      const ops = [];
      return {
        delete(ref) {
          ops.push(["delete", ref.path]);
        },
        set(ref, data) {
          ops.push(["set", ref.path, data]);
        },
        async commit() {
          log.push(["commit", ops.map(([op, path]) => `${op} ${path}`)]);
          for (const [op, path, data] of ops) {
            if (op === "delete") store.delete(path);
            else store.set(path, data);
          }
        },
      };
    },
  };
  return db;
}

describe("canTransition - Unit Test Suite", () => {
  const allowed = [
    [null, "reserved"],
    ["reserved", "awaiting_billing"],
    ["reserved", "provisioning"],
    ["awaiting_billing", "provisioning"],
    ["provisioning", "active"],
    ["provisioning", "failed"],
    ["failed", "provisioning"],
    ["active", "migrating"],
    ["active", "deleting"],
    ["migrating", "active"],
    ["deleting", "active"],
  ];
  for (const [from, to] of allowed) {
    test(`Happy Path: ${from} -> ${to} is allowed`, () => {
      // 1. Arrange
      const current = from;

      // 2. Act
      const result = canTransition(current, to);

      // 3. Assert
      assert.equal(result, true);
    });
  }

  const rejected = [
    ["Sad Path", null, "active"],
    ["Sad Path", null, "provisioning"],
    ["Sad Path", "reserved", "active"],
    ["Edge Case", "reserved", "reserved"],
    ["Sad Path", "awaiting_billing", "active"],
    ["Sad Path", "awaiting_billing", "reserved"],
    ["Sad Path", "provisioning", "deleting"],
    ["Sad Path", "failed", "active"],
    ["Sad Path", "active", "reserved"],
    ["Edge Case", "active", "active"],
    ["Sad Path", "active", "awaiting_billing"],
    ["Sad Path", "migrating", "deleting"],
    ["Sad Path", "deleting", "provisioning"],
    ["Sad Path", "deleting", "migrating"],
    ["Sad Path", "archived", "active"],
    ["Sad Path", "active", "archived"],
    ["Sad Path", undefined, "reserved"],
  ];
  for (const [label, from, to] of rejected) {
    test(`${label}: ${from} -> ${to} is rejected`, () => {
      // 1. Arrange
      const current = from;

      // 2. Act
      const result = canTransition(current, to);

      // 3. Assert
      assert.equal(result, false);
    });
  }
});

describe("statusFields - Unit Test Suite", () => {
  const cases = [
    ["Happy Path", "awaiting_billing", SEVEN_DAYS_LATER],
    ["Happy Path", "deleting", THIRTY_DAYS_LATER],
    ["Edge Case", "reserved", null],
    ["Edge Case", "provisioning", null],
    ["Edge Case", "active", null],
    ["Edge Case", "migrating", null],
    ["Edge Case", "failed", null],
  ];
  for (const [label, to, deleteAt] of cases) {
    test(`${label}: entering ${to} sets deleteAt to ${deleteAt?.toISOString() ?? "null"}`, () => {
      // 1. Arrange
      const now = new Date(NOW);

      // 2. Act
      const fields = statusFields(to, now);

      // 3. Assert
      assert.deepEqual(fields, { status: to, updatedAt: NOW, deleteAt });
    });
  }

  test("Sad Path: an unknown status has no deleteAt", () => {
    // 1. Arrange
    const now = new Date(NOW);

    // 2. Act
    const fields = statusFields("archived", now);

    // 3. Assert
    assert.equal(fields.deleteAt, null);
  });
});

describe("dueOrganizationIds - Unit Test Suite", () => {
  const past = new Date("2026-10-25T12:00:00.000Z");
  const future = new Date("2026-10-27T12:00:00.000Z");
  const cases = [
    ["Happy Path: a due awaiting_billing organization is due", { id: "acme", status: "awaiting_billing", deleteAt: past }, ["acme"]],
    ["Happy Path: a due deleting organization is due", { id: "acme", status: "deleting", deleteAt: past }, ["acme"]],
    ["Edge Case: deleteAt exactly now is due", { id: "acme", status: "deleting", deleteAt: new Date(NOW) }, ["acme"]],
    ["Edge Case: a Timestamp-like deleteAt is read through toDate()", { id: "acme", status: "awaiting_billing", deleteAt: { toDate: () => past } }, ["acme"]],
    ["Edge Case: a deleteAt one millisecond after now is not due", { id: "acme", status: "deleting", deleteAt: new Date(NOW.getTime() + 1) }, []],
    ["Edge Case: a not yet due organization is not due", { id: "acme", status: "awaiting_billing", deleteAt: future }, []],
    ["Edge Case: a not yet due Timestamp-like deleteAt is not due", { id: "acme", status: "deleting", deleteAt: { toDate: () => future } }, []],
    ["Sad Path: an active organization with a past deleteAt is not due", { id: "acme", status: "active", deleteAt: past }, []],
    ["Sad Path: an organization without deleteAt is not due", { id: "acme", status: "deleting" }, []],
    ["Sad Path: an organization with a malformed deleteAt is not due", { id: "acme", status: "deleting", deleteAt: "2026-10-25" }, []],
    ["Sad Path: an organization without status is not due", { id: "acme", deleteAt: past }, []],
  ];
  for (const [label, doc, expected] of cases) {
    test(label, () => {
      // 1. Arrange
      const docs = [doc];

      // 2. Act
      const ids = dueOrganizationIds(docs, NOW);

      // 3. Assert
      assert.deepEqual(ids, expected);
    });
  }

  test("Happy Path: keeps only the due ids of a mixed list", () => {
    // 1. Arrange
    const docs = [
      { id: "alpha", status: "awaiting_billing", deleteAt: past },
      { id: "beta", status: "active" },
      { id: "gamma", status: "deleting", deleteAt: future },
      { id: "delta", status: "deleting", deleteAt: { toDate: () => past } },
      { id: "eps", status: "migrating", deleteAt: past },
    ];

    // 2. Act
    const ids = dueOrganizationIds(docs, NOW);

    // 3. Assert
    assert.deepEqual(ids, ["alpha", "delta"]);
  });

  test("Edge Case: no documents give no ids", () => {
    // 1. Arrange
    const docs = [];

    // 2. Act
    const ids = dueOrganizationIds(docs, NOW);

    // 3. Assert
    assert.deepEqual(ids, []);
  });
});

describe("retireOrganization - Unit Test Suite", () => {
  const registry = { status: "deleting", createdBy: "owner@example.com" };

  test("Happy Path: erases the data with the registry entry", async () => {
    // 1. Arrange
    const db = fakeDb({ "organizations/acme": registry });
    const erased = [];
    const eraseData = async (id, data) => {
      erased.push([id, data]);
    };

    // 2. Act
    await retireOrganization(db, "acme", eraseData, { now: NOW });

    // 3. Assert
    assert.deepEqual(erased, [["acme", registry]]);
  });

  test("Happy Path: deletes the entry and retires the id in one batch", async () => {
    // 1. Arrange
    const db = fakeDb({ "organizations/acme": registry });

    // 2. Act
    await retireOrganization(db, "acme", async () => {}, { now: NOW });

    // 3. Assert
    assert.deepEqual(db.log.filter(([op]) => op === "commit"), [
      ["commit", ["delete organizations/acme", "set retiredOrganizationIds/acme"]],
    ]);
  });

  test("Happy Path: the retired marker holds only retiredAt", async () => {
    // 1. Arrange
    const db = fakeDb({ "organizations/acme": registry });

    // 2. Act
    await retireOrganization(db, "acme", async () => {}, { now: NOW });

    // 3. Assert
    assert.deepEqual(
      [db.store.has("organizations/acme"), db.store.get("retiredOrganizationIds/acme")],
      [false, { retiredAt: NOW }]
    );
  });

  test("Happy Path: erases the data before committing the batch", async () => {
    // 1. Arrange
    const db = fakeDb({ "organizations/acme": registry });
    const eraseData = async () => {
      db.log.push(["erase"]);
    };

    // 2. Act
    await retireOrganization(db, "acme", eraseData, { now: NOW });

    // 3. Assert
    assert.deepEqual(
      db.log.map(([op]) => op).filter((op) => op !== "get"),
      ["erase", "commit"]
    );
  });

  test("Edge Case: a missing entry does nothing and erases nothing", async () => {
    // 1. Arrange
    const db = fakeDb({ "organizations/other": registry });
    let erased = false;
    const eraseData = async () => {
      erased = true;
    };

    // 2. Act
    await retireOrganization(db, "acme", eraseData, { now: NOW });

    // 3. Assert
    assert.deepEqual(
      [erased, db.log.some(([op]) => op === "commit"), [...db.store.keys()]],
      [false, false, ["organizations/other"]]
    );
  });

  test("Sad Path: when erasing fails the error propagates", async () => {
    // 1. Arrange
    const db = fakeDb({ "organizations/acme": registry });
    const eraseData = async () => {
      throw new Error("project deletion failed");
    };

    // 2. Act
    const retiring = retireOrganization(db, "acme", eraseData, { now: NOW });

    // 3. Assert
    await assert.rejects(retiring, { message: "project deletion failed" });
  });

  test("Sad Path: when erasing fails nothing is deleted or written", async () => {
    // 1. Arrange
    const db = fakeDb({ "organizations/acme": registry });
    const eraseData = async () => {
      throw new Error("project deletion failed");
    };

    // 2. Act
    await retireOrganization(db, "acme", eraseData, { now: NOW }).catch(() => {});

    // 3. Assert
    assert.deepEqual(
      [db.log.some(([op]) => op === "commit"), [...db.store.entries()]],
      [false, [["organizations/acme", registry]]]
    );
  });
});
