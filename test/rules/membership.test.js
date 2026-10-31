// Membership-based rules of a partner project (#159, phase 1), against the
// Firestore and Storage emulators. Organizations, groups and roles live in
// Firestore documents keyed by personKey (the lowercase-hex SHA-256 of the
// lowercased e-mail); the rules read them with get() instead of claims.
// Positions live inside each group: groups/{groupId}/positions/{personKey}.
const { after, before, beforeEach, describe, test } = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  Timestamp,
  collection,
  collectionGroup,
  doc,
  documentId,
  getDoc,
  getDocs,
  increment,
  query,
  serverTimestamp,
  setDoc,
  where,
  writeBatch,
} = require("firebase/firestore");
const { ref, uploadBytes } = require("firebase/storage");

const root = path.join(__dirname, "..", "..");

const HERE = "partners/rotasul";
const THERE = "partners/outro";
const GUIAS = `${HERE}/groups/guias`;
const RECEPCAO = `${HERE}/groups/recepcao`;
const VENDAS = `${THERE}/groups/vendas`;

const LONG_AGO = Timestamp.fromMillis(1_700_000_000_000);

/** personKey of ana@example.com, computed once with `sha256sum`. */
const ANA_KEY = "8e43ca37701228e74983efdbd0cff5c16b3b1e5d4e29a7c05626d4d25a018e11";

/** Fixture keys for seeding paths (the rules compute their own). */
function keyOf(email) {
  return crypto.createHash("sha256").update(email.toLowerCase(), "utf8").digest("hex");
}

const people = {
  ana: "ana@example.com", // publisher + subscriber in guias, publisher in recepcao
  vera: "vera@example.com", // subscriber in guias
  caio: "caio@example.com", // publisher in guias only
  olga: "olga@example.com", // administrator of rotasul, in no group
  nina: "nina@example.com", // not in rotasul
  otto: "otto@example.com", // administrator of outro
  pia: "pia@example.com", // publisher in outro's vendas (Community: 15 min)
};

let env;

/** Firestore as [name], with a verified e-mail unless said otherwise. */
function dbOf(name, { email = people[name], verified = true } = {}) {
  return env.authenticatedContext(name, { email, email_verified: verified }).firestore();
}

function storageOf(name, { email = people[name] } = {}) {
  return env.authenticatedContext(name, { email, email_verified: true }).storage();
}

function positionPath(group, name) {
  return `${group}/positions/${keyOf(people[name])}`;
}

function storedPosition(email, extra = {}) {
  return {
    email,
    name: email.split("@")[0],
    lat: -22.9,
    lng: -43.1,
    capturedAt: LONG_AGO,
    receivedAt: LONG_AGO,
    isPublishing: true,
    removedAt: null,
    ...extra,
  };
}

function newPosition(email, extra = {}) {
  return {
    ...storedPosition(email),
    lat: -23.0,
    capturedAt: Timestamp.now(),
    receivedAt: serverTimestamp(),
    ...extra,
  };
}

/** The batch the tracking service writes for one group. */
function publishBatch(db, group, key, position, { trail = true, day = true } = {}) {
  const base = `${group}/positions/${key}`;
  const batch = writeBatch(db);
  if (position) batch.set(doc(db, base), position);
  if (trail) {
    batch.set(doc(collection(db, `${base}/trail`)), {
      lat: -23.0,
      lng: -43.2,
      receivedAt: serverTimestamp(),
    });
  }
  if (day) {
    batch.set(
      doc(db, `${base}/trailDays/2026-10-31`),
      { lastAt: serverTimestamp(), pointCount: increment(1) },
      { merge: true }
    );
  }
  return batch.commit();
}

before(async () => {
  env = await initializeTestEnvironment({
    // The Storage emulator's firestore.get() reads the project the
    // emulators were started with (package.json), so this file uses that
    // id; the other files keep their own.
    projectId: "demo-monamie",
    firestore: {
      rules: fs.readFileSync(path.join(root, "firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8181,
    },
    storage: {
      rules: fs.readFileSync(path.join(root, "storage.rules"), "utf8"),
      host: "127.0.0.1",
      port: 9199,
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const member = (org, name, role) =>
      setDoc(doc(db, `${org}/organizationMemberships/${keyOf(people[name])}`), {
        email: people[name],
        role,
        addedAt: LONG_AGO,
      });
    const inGroup = (group, org, name, roles) =>
      setDoc(doc(db, `${group}/groupMemberships/${keyOf(people[name])}`), {
        email: people[name],
        organizationId: org.split("/")[1],
        roles,
      });

    for (const name of ["ana", "vera", "caio"]) await member(HERE, name, "member");
    await member(HERE, "olga", "admin");
    await member(THERE, "otto", "admin");
    await member(THERE, "pia", "member");

    await setDoc(doc(db, GUIAS), { name: "Guias", createdAt: LONG_AGO });
    await setDoc(doc(db, RECEPCAO), { name: "Recepção", createdAt: LONG_AGO });
    await setDoc(doc(db, VENDAS), { name: "Vendas", createdAt: LONG_AGO });
    await setDoc(doc(db, `${THERE}/config/plan`), { minIntervalMinutes: 15 });

    await inGroup(GUIAS, HERE, "ana", ["publisher", "subscriber"]);
    await inGroup(RECEPCAO, HERE, "ana", ["publisher"]);
    await inGroup(GUIAS, HERE, "vera", ["subscriber"]);
    await inGroup(GUIAS, HERE, "caio", ["publisher"]);
    await inGroup(VENDAS, THERE, "pia", ["publisher"]);

    await setDoc(doc(db, positionPath(GUIAS, "ana")), storedPosition(people.ana));
    await setDoc(doc(db, positionPath(GUIAS, "caio")), storedPosition(people.caio));
    await setDoc(doc(db, `${positionPath(GUIAS, "ana")}/trail/p1`), {
      lat: -22.9,
      lng: -43.1,
      receivedAt: LONG_AGO,
    });
    await setDoc(doc(db, `${positionPath(GUIAS, "ana")}/trailDays/2026-10-30`), {
      lastAt: LONG_AGO,
      pointCount: 1,
    });
    await setDoc(doc(db, `${positionPath(RECEPCAO, "ana")}/trail/p1`), {
      lat: -22.9,
      lng: -43.1,
      receivedAt: LONG_AGO,
    });
    // Rui stopped publishing in guias: no membership, position marked.
    await setDoc(
      doc(db, `${GUIAS}/positions/${keyOf("rui@example.com")}`),
      storedPosition("rui@example.com", { removedAt: LONG_AGO })
    );
    await setDoc(doc(db, `${GUIAS}/positions/${keyOf("rui@example.com")}/trail/p1`), {
      lat: -22.9,
      lng: -43.1,
      receivedAt: LONG_AGO,
    });
    // Pia published a moment ago (Community interval not over).
    await setDoc(
      doc(db, positionPath(VENDAS, "pia")),
      storedPosition(people.pia, { receivedAt: Timestamp.now() })
    );
  });
});

after(async () => {
  await env.cleanup();
});

describe("membership rules: personKey - Rules Test Suite", () => {
  test("Happy Path: the rules find Ana's membership at the fixed key of her e-mail", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/organizationMemberships/${ANA_KEY}`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Edge Case: an e-mail with uppercase letters gives the same key", async () => {
    // 1. Arrange
    const db = dbOf("ana", { email: "Ana@Example.COM" });

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/organizationMemberships/${ANA_KEY}`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: an unverified e-mail is denied its own membership", async () => {
    // 1. Arrange
    const db = dbOf("ana", { verified: false });

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/organizationMemberships/${ANA_KEY}`));

    // 3. Assert
    await assertFails(read);
  });
});

describe("membership rules: organizationMemberships - Rules Test Suite", () => {
  test("Happy Path: an administrator reads another person's membership", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/organizationMemberships/${keyOf(people.vera)}`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Happy Path: an administrator lists the memberships", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const list = getDocs(collection(db, `${HERE}/organizationMemberships`));

    // 3. Assert
    await assertSucceeds(list);
  });

  test("Edge Case: a person reads their own missing membership (to learn they were removed)", async () => {
    // 1. Arrange
    const db = dbOf("nina");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/organizationMemberships/${keyOf(people.nina)}`));

    // 3. Assert
    await assertSucceeds(read);
  });

  const denied = [
    ["a member reading another member", "vera", () => getDoc(doc(dbOf("vera"), `${HERE}/organizationMemberships/${ANA_KEY}`))],
    ["a member listing the memberships", "vera", () => getDocs(collection(dbOf("vera"), `${HERE}/organizationMemberships`))],
    ["another organization's administrator reading here", "otto", () => getDoc(doc(dbOf("otto"), `${HERE}/organizationMemberships/${ANA_KEY}`))],
    [
      "an administrator writing a membership",
      "olga",
      () => setDoc(doc(dbOf("olga"), `${HERE}/organizationMemberships/${keyOf(people.nina)}`), { email: people.nina, role: "admin" }),
    ],
  ];
  for (const [label, who, act] of denied) {
    test(`Sad Path: ${label} is denied (${who})`, async () => {
      // 1. Arrange
      // (people and memberships are seeded in beforeEach)

      // 2. Act
      const request = act();

      // 3. Assert
      await assertFails(request);
    });
  }
});

describe("membership rules: groups - Rules Test Suite", () => {
  test("Happy Path: a member of the organization reads a group", async () => {
    // 1. Arrange
    const db = dbOf("caio");

    // 2. Act
    const read = getDoc(doc(db, RECEPCAO));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: someone outside the organization cannot read its groups", async () => {
    // 1. Arrange
    const db = dbOf("nina");

    // 2. Act
    const read = getDoc(doc(db, GUIAS));

    // 3. Assert
    await assertFails(read);
  });

  test("Sad Path: an administrator cannot write a group from the app", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/groups/nova`), { name: "Nova" });

    // 3. Assert
    await assertFails(write);
  });
});

describe("membership rules: my groups (collection-group query) - Rules Test Suite", () => {
  const myGroups = (db, email) =>
    getDocs(
      query(
        collectionGroup(db, "groupMemberships"),
        where("email", "==", email),
        where("organizationId", "==", "rotasul")
      )
    );

  test("Happy Path: Ana finds her two groups of the organization", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const snapshot = await myGroups(db, people.ana);

    // 3. Assert
    assert.equal(snapshot.size, 2);
  });

  test("Sad Path: asking for another person's groups is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const list = myGroups(db, people.vera);

    // 3. Assert
    await assertFails(list);
  });

  test("Sad Path: a query without the e-mail filter is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const list = getDocs(
      query(collectionGroup(db, "groupMemberships"), where("organizationId", "==", "rotasul"))
    );

    // 3. Assert
    await assertFails(list);
  });
});

describe("membership rules: publish a position - Rules Test Suite", () => {
  test("Happy Path: a publisher writes position, trail point and day summary in one batch", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = publishBatch(db, GUIAS, keyOf(people.ana), newPosition(people.ana));

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Happy Path: a publisher in two groups also writes to the second one", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = publishBatch(db, RECEPCAO, keyOf(people.ana), newPosition(people.ana));

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a Community publisher within the plan's interval is denied", async () => {
    // 1. Arrange
    const db = dbOf("pia");

    // 2. Act
    const write = publishBatch(db, VENDAS, keyOf(people.pia), newPosition(people.pia));

    // 3. Assert
    await assertFails(write);
  });

  const denied = [
    ["a subscriber without publisher", "vera", GUIAS, () => keyOf(people.vera), () => newPosition(people.vera), {}],
    ["a publisher writing under another person's key", "ana", GUIAS, () => keyOf(people.caio), () => newPosition(people.ana), {}],
    ["a publisher writing another person's e-mail", "caio", GUIAS, () => keyOf(people.caio), () => newPosition(people.vera), {}],
    ["a publisher setting removedAt", "ana", GUIAS, () => keyOf(people.ana), () => newPosition(people.ana, { removedAt: Timestamp.now() }), {}],
    ["a publisher in a group where they are not", "caio", RECEPCAO, () => keyOf(people.caio), () => newPosition(people.caio), {}],
    ["a trail point without its position in the batch", "ana", GUIAS, () => keyOf(people.ana), () => null, { day: false }],
  ];
  for (const [label, who, group, key, position, options] of denied) {
    test(`Sad Path: ${label} is denied (${who})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const write = publishBatch(db, group, key(), position(), options);

      // 3. Assert
      await assertFails(write);
    });
  }
});

describe("membership rules: read the map - Rules Test Suite", () => {
  const map = (db, group) =>
    getDocs(query(collection(db, `${group}/positions`), where("removedAt", "==", null)));

  test("Happy Path: a subscriber reads the group's map", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const list = map(db, GUIAS);

    // 3. Assert
    await assertSucceeds(list);
  });

  test("Happy Path: the map leaves out the position marked removedAt", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const snapshot = await map(db, GUIAS);

    // 3. Assert
    assert.deepEqual(snapshot.docs.map((d) => d.data().email).sort(), [people.ana, people.caio]);
  });

  test("Happy Path: an administrator in no group reads the map", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const list = map(db, RECEPCAO);

    // 3. Assert
    await assertSucceeds(list);
  });

  test("Edge Case: a publisher without subscriber reads their own position", async () => {
    // 1. Arrange
    const db = dbOf("caio");

    // 2. Act
    const read = getDoc(doc(db, positionPath(GUIAS, "caio")));

    // 3. Assert
    await assertSucceeds(read);
  });

  const denied = [
    ["a publisher without subscriber", "caio", GUIAS],
    ["a subscriber of another group", "vera", RECEPCAO],
    ["another organization's administrator", "otto", GUIAS],
  ];
  for (const [label, who, group] of denied) {
    test(`Sad Path: ${label} cannot read the map (${who})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const list = map(db, group);

      // 3. Assert
      await assertFails(list);
    });
  }
});

describe("membership rules: history - Rules Test Suite", () => {
  test("Happy Path: a subscriber reads the trail of someone who left the group", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const list = getDocs(collection(db, `${GUIAS}/positions/${keyOf("rui@example.com")}/trail`));

    // 3. Assert
    await assertSucceeds(list);
  });

  test("Happy Path: the history lists the removed person's position", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const snapshot = await getDocs(collection(db, `${GUIAS}/positions`));

    // 3. Assert
    assert.equal(snapshot.size, 3);
  });

  test("Edge Case: the calendar reads a month of day summaries by id range", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const list = getDocs(
      query(
        collection(db, `${positionPath(GUIAS, "ana")}/trailDays`),
        where(documentId(), ">=", "2026-10-01"),
        where(documentId(), "<=", "2026-10-31")
      )
    );

    // 3. Assert
    await assertSucceeds(list);
  });

  test("Sad Path: a subscriber of guias cannot read Ana's trail in recepcao", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const list = getDocs(collection(db, `${positionPath(RECEPCAO, "ana")}/trail`));

    // 3. Assert
    await assertFails(list);
  });
});

describe("membership rules: logo upload with a Firestore admin - Rules Test Suite", () => {
  const png = () => {
    const bytes = new Uint8Array(64);
    bytes.set([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    return bytes;
  };
  const upload = (storage) =>
    uploadBytes(ref(storage, "partners/rotasul/logo.png"), png(), { contentType: "image/png" });

  test("Happy Path: an administrator in Firestore (no claims) uploads the logo", async () => {
    // 1. Arrange
    const storage = storageOf("olga");

    // 2. Act
    const write = upload(storage);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: the Storage rules hash an uppercase e-mail to the same key", async () => {
    // 1. Arrange
    const storage = storageOf("olga", { email: "OLGA@example.com" });

    // 2. Act
    const write = upload(storage);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Sad Path: a member who is not an administrator cannot upload the logo", async () => {
    // 1. Arrange
    const storage = storageOf("vera");

    // 2. Act
    const write = upload(storage);

    // 3. Assert
    await assertFails(write);
  });
});
