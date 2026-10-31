// Security rules of an organization project (firestore.rules), against the
// Firestore emulator. Every organization's data lives under organizations/{organizationId}.
// Capabilities come from the custom claims share, watch (team keys), admin
// and organizations (organization ids) that syncClaims sets.
const { after, before, beforeEach, describe, test } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  Timestamp,
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} = require("firebase/firestore");

const rulesPath = path.join(__dirname, "..", "..", "firestore.rules");

const HERE = "organizations/rotasul";
const THERE = "organizations/outro";

const TEAM_01 = "rotasul01@monamienet.org";
const TEAM_02 = "rotasul02@monamienet.org";
const OTHER_TEAM = "outro01@monamienet.org";

const LONG_AGO = Timestamp.fromMillis(1_700_000_000_000);

/** A live position document as stored (seeded with rules disabled). */
function stored(email, groupId) {
  return {
    email,
    name: email.split("@")[0],
    lat: -22.9,
    lng: -43.1,
    capturedAt: LONG_AGO,
    receivedAt: LONG_AGO,
    isPublishing: true,
    groupId,
  };
}

/** A new live position, as the tracking service writes it. */
function position(email, groupId) {
  return {
    email,
    name: email.split("@")[0],
    lat: -22.9,
    lng: -43.1,
    capturedAt: Timestamp.now(),
    receivedAt: serverTimestamp(),
    isPublishing: true,
    groupId,
  };
}

/** The document written at sign-in, before any position. */
function signIn(email, groupId) {
  return { email, name: email.split("@")[0], isPublishing: false, groupId };
}

/** A position move of an existing document. */
const moved = { lat: -23.0, lng: -43.2, receivedAt: serverTimestamp() };

/** A trail point as the app writes it. */
function point(groupId) {
  const data = { lat: -23.0, lng: -43.2, receivedAt: serverTimestamp() };
  if (groupId !== undefined) data.groupId = groupId;
  return data;
}

/** A trail point as stored (seeded). */
function storedPoint(groupId) {
  return { lat: -22.9, lng: -43.1, receivedAt: LONG_AGO, groupId };
}

/** People and their claims. */
const people = {
  // Field person of rotasul01: shares only.
  ana: { email: "ana@example.com", share: ["rotasul01"], organizations: ["rotasul"] },
  // Field person of rotasul02.
  bia: { email: "bia@example.com", share: ["rotasul02"], organizations: ["rotasul"] },
  // Watches rotasul01's map only.
  vera: { email: "vera@example.com", watch: ["rotasul01"], organizations: ["rotasul"] },
  // Watches rotasul02's map only.
  walter: { email: "walter@example.com", watch: ["rotasul02"], organizations: ["rotasul"] },
  // Shares and watches in rotasul01.
  duda: {
    email: "duda@example.com",
    share: ["rotasul01"],
    watch: ["rotasul01"],
    organizations: ["rotasul"],
  },
  // Administrator of rotasul.
  olga: { email: "olga@example.com", admin: ["rotasul"], organizations: ["rotasul"] },
  // Watcher and administrator of another organization.
  otto: { email: "otto@example.com", watch: ["outro01"], admin: ["outro"], organizations: ["outro"] },
  // Every capability in rotasul, none in outro.
  zack: {
    email: "zack@example.com",
    share: ["rotasul01"],
    watch: ["rotasul01"],
    admin: ["rotasul"],
    organizations: ["rotasul"],
  },
  // Shares in a team of each organization.
  mia: {
    email: "mia@example.com",
    share: ["outro01", "rotasul01"],
    organizations: ["outro", "rotasul"],
  },
  // Shares in rotasul01 but has no `organizations` claim (claims of before #94).
  lia: { email: "lia@example.com", share: ["rotasul01"] },
};

let env;

function dbOf(name) {
  const { email, ...claims } = people[name];
  return env.authenticatedContext(name, { email, ...claims }).firestore();
}

async function seed(fn) {
  await env.withSecurityRulesDisabled(async (context) => fn(context.firestore()));
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-organization",
    firestore: {
      rules: fs.readFileSync(rulesPath, "utf8"),
      host: "127.0.0.1",
      port: 8181,
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, `${HERE}/positions/ana@example.com`), stored("ana@example.com", TEAM_01));
    await setDoc(doc(db, `${HERE}/positions/bia@example.com`), stored("bia@example.com", TEAM_02));
    await setDoc(doc(db, `${HERE}/positions/caio@example.com`), stored("caio@example.com", TEAM_01));
    // A document of organization A naming a team of another organization.
    await setDoc(doc(db, `${HERE}/positions/zeca@example.com`), stored("zeca@example.com", OTHER_TEAM));
    await setDoc(doc(db, `${HERE}/positions/ana@example.com/trail/p1`), storedPoint(TEAM_01));
    await setDoc(doc(db, `${HERE}/positions/bia@example.com/trail/p1`), storedPoint(TEAM_02));
    await setDoc(doc(db, `${HERE}/config/branding`), { name: "Rota Sul" });

    await setDoc(doc(db, `${THERE}/positions/oscar@example.com`), stored("oscar@example.com", OTHER_TEAM));
    await setDoc(doc(db, `${THERE}/positions/zack@example.com`), stored("zack@example.com", OTHER_TEAM));
    await setDoc(doc(db, `${THERE}/positions/oscar@example.com/trail/p1`), storedPoint(OTHER_TEAM));
    await setDoc(doc(db, `${THERE}/positions/zack@example.com/trail/p1`), storedPoint(OTHER_TEAM));
    await setDoc(doc(db, `${THERE}/config/plan`), { minIntervalMinutes: 15 });
    await setDoc(doc(db, `${THERE}/config/branding`), { name: "Outro" });

    // Documents at the root, outside any organization: no rule allows them.
    await setDoc(doc(db, "positions/ana@example.com"), stored("ana@example.com", TEAM_01));
    await setDoc(doc(db, "config/branding"), { name: "Rota Sul" });
  });
});

after(async () => {
  await env.cleanup();
});

describe("organization rules: read positions/{email} - Rules Test Suite", () => {
  const allowed = [
    ["Happy Path: the person reads their own document", "ana", "ana@example.com"],
    ["Happy Path: a watcher of the team reads a member", "vera", "ana@example.com"],
    ["Happy Path: an administrator reads a member of team 01", "olga", "ana@example.com"],
    ["Happy Path: an administrator reads a member of team 02", "olga", "bia@example.com"],
    ["Edge Case: a person who shares and watches reads a teammate", "duda", "ana@example.com"],
  ];
  for (const [label, who, target] of allowed) {
    test(`${label} (${who} → ${target})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDoc(doc(db, `${HERE}/positions/${target}`));

      // 3. Assert
      await assertSucceeds(read);
    });
  }

  const denied = [
    ["a field-only person reading a teammate", "ana", "caio@example.com"],
    ["a field-only person reading someone of another team", "ana", "bia@example.com"],
    ["a watcher of another team", "walter", "ana@example.com"],
    ["a watcher of another organization", "otto", "ana@example.com"],
    ["an administrator of another organization", "otto", "bia@example.com"],
    ["an administrator of rotasul reading a document naming another organization's team", "olga", "zeca@example.com"],
    ["the watcher of outro01 reading a document of rotasul naming outro01", "otto", "zeca@example.com"],
  ];
  for (const [label, who, target] of denied) {
    test(`Sad Path: ${label} is denied (${who} → ${target})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDoc(doc(db, `${HERE}/positions/${target}`));

      // 3. Assert
      await assertFails(read);
    });
  }

  test("Sad Path: an unauthenticated client is denied", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/positions/ana@example.com`));

    // 3. Assert
    await assertFails(read);
  });
});

describe("organization rules: write positions/{email} - Rules Test Suite", () => {
  test("Happy Path: a field person creates their own document with a position", async () => {
    // 1. Arrange
    const db = dbOf("duda");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/positions/duda@example.com`), position("duda@example.com", TEAM_01));

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Happy Path: a field person updates their own position", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/positions/ana@example.com`), moved);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: creating the document without a position at sign-in is accepted", async () => {
    // 1. Arrange
    const db = dbOf("duda");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/positions/duda@example.com`), signIn("duda@example.com", TEAM_01));

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a document without groupId is accepted", async () => {
    // 1. Arrange
    const db = dbOf("duda");
    const { groupId: _ignored, ...data } = position("duda@example.com", TEAM_01);

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/positions/duda@example.com`), data);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: groupId null is accepted", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/positions/ana@example.com`), { groupId: null });

    // 3. Assert
    await assertSucceeds(write);
  });

  const denied = [
    ["a watch-only person writing their own document", "vera", "vera@example.com", () => position("vera@example.com", TEAM_01)],
    ["an administrator writing their own document", "olga", "olga@example.com", () => position("olga@example.com", TEAM_01)],
    ["a field person writing someone else's document", "duda", "ana@example.com", () => position("ana@example.com", TEAM_01)],
    ["a field person without the organizations claim", "lia", "lia@example.com", () => position("lia@example.com", TEAM_01)],
    ["an e-mail field that is not their own", "duda", "duda@example.com", () => ({ ...position("duda@example.com", TEAM_01), email: "ana@example.com" })],
    ["an extra field", "duda", "duda@example.com", () => ({ ...position("duda@example.com", TEAM_01), role: "admin" })],
    ["groupId of a team where they do not share", "duda", "duda@example.com", () => position("duda@example.com", TEAM_02)],
    ["groupId of another organization's team where they share", "mia", "mia@example.com", () => position("mia@example.com", OTHER_TEAM)],
  ];
  for (const [label, who, target, data] of denied) {
    test(`Sad Path: ${label} is denied (${who} → ${target})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const write = setDoc(doc(db, `${HERE}/positions/${target}`), data());

      // 3. Assert
      await assertFails(write);
    });
  }

  test("Sad Path: deleting their own document is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = deleteDoc(doc(db, `${HERE}/positions/ana@example.com`));

    // 3. Assert
    await assertFails(write);
  });
});

describe("organization rules: position timing of positions/{email} - Rules Test Suite", () => {
  test("Happy Path: a heartbeat that does not move the position is accepted", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/positions/ana@example.com`), { capturedAt: new Date() });

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Happy Path: without a plan (Standard) a second position right away is accepted", async () => {
    // 1. Arrange
    const db = dbOf("ana");
    const ref = doc(db, `${HERE}/positions/ana@example.com`);
    await assertSucceeds(updateDoc(ref, moved));

    // 2. Act
    const write = updateDoc(ref, { lat: -23.5, lng: -43.5, receivedAt: serverTimestamp() });

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: with a 15-minute plan the first position after a long pause is accepted", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/config/plan`), { minIntervalMinutes: 15 }));
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/positions/ana@example.com`), moved);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Sad Path: with a 15-minute plan a second position right after the first is denied", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/config/plan`), { minIntervalMinutes: 15 }));
    const db = dbOf("ana");
    const ref = doc(db, `${HERE}/positions/ana@example.com`);
    await assertSucceeds(updateDoc(ref, moved));

    // 2. Act
    const write = updateDoc(ref, { lat: -23.5, lng: -43.5, receivedAt: serverTimestamp() });

    // 3. Assert
    await assertFails(write);
  });

  const denied = [
    ["moving the position without receivedAt", { lat: -23.0, lng: -43.2 }],
    ["moving only the latitude without receivedAt", { lat: -23.0 }],
    ["moving the position with a client receivedAt", { lat: -23.0, lng: -43.2, receivedAt: Timestamp.now() }],
    ["a heartbeat that changes receivedAt", { capturedAt: new Date(), receivedAt: serverTimestamp() }],
    ["a heartbeat that removes receivedAt", { capturedAt: new Date(), receivedAt: null }],
  ];
  for (const [label, data] of denied) {
    test(`Sad Path: ${label} is denied`, async () => {
      // 1. Arrange
      const db = dbOf("ana");

      // 2. Act
      const write = updateDoc(doc(db, `${HERE}/positions/ana@example.com`), data);

      // 3. Assert
      await assertFails(write);
    });
  }

  const deniedCreates = [
    ["creating with a position but no receivedAt", () => {
      const { receivedAt: _ignored, ...data } = position("duda@example.com", TEAM_01);
      return data;
    }],
    ["creating with a position and a client receivedAt", () => ({ ...position("duda@example.com", TEAM_01), receivedAt: Timestamp.now() })],
    ["creating without a position but with receivedAt", () => ({ ...signIn("duda@example.com", TEAM_01), receivedAt: serverTimestamp() })],
  ];
  for (const [label, data] of deniedCreates) {
    test(`Sad Path: ${label} is denied`, async () => {
      // 1. Arrange
      const db = dbOf("duda");

      // 2. Act
      const write = setDoc(doc(db, `${HERE}/positions/duda@example.com`), data());

      // 3. Assert
      await assertFails(write);
    });
  }
});

describe("organization rules: positions/{email}/trail - Rules Test Suite", () => {
  /** A batch with `who`'s position update and a point in `owner`'s trail. */
  function batchWithPoint(who, owner, data, { withPosition = true } = {}) {
    const db = dbOf(who);
    const batch = writeBatch(db);
    if (withPosition) {
      batch.update(doc(db, `${HERE}/positions/${people[who].email}`), moved);
    }
    batch.set(doc(collection(db, `${HERE}/positions/${owner}/trail`)), data);
    return batch;
  }

  test("Happy Path: a point in the same batch as the position update is accepted", async () => {
    // 1. Arrange
    const batch = batchWithPoint("ana", "ana@example.com", point(TEAM_01));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a point without groupId is accepted", async () => {
    // 1. Arrange
    const batch = batchWithPoint("ana", "ana@example.com", point());

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a point with groupId null is accepted", async () => {
    // 1. Arrange
    const batch = batchWithPoint("ana", "ana@example.com", point(null));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Sad Path: a point alone, without the position update, is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = addDoc(collection(db, `${HERE}/positions/ana@example.com/trail`), point(TEAM_01));

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a point batched with a heartbeat (no new position) is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");
    const batch = writeBatch(db);
    batch.update(doc(db, `${HERE}/positions/ana@example.com`), { capturedAt: new Date() });
    batch.set(doc(collection(db, `${HERE}/positions/ana@example.com/trail`)), point(TEAM_01));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertFails(write);
  });

  const deniedWrites = [
    ["a watch-only person", "vera", "vera@example.com", point(TEAM_01)],
    ["someone else's trail", "duda", "ana@example.com", point(TEAM_01)],
    ["a team where they do not share", "ana", "ana@example.com", point(TEAM_02)],
    ["another organization's team where they share", "mia", "mia@example.com", point(OTHER_TEAM)],
    ["a latitude that is not a number", "ana", "ana@example.com", { ...point(TEAM_01), lat: "-22.9" }],
    ["a longitude that is not a number", "ana", "ana@example.com", { ...point(TEAM_01), lng: null }],
    ["a client receivedAt", "ana", "ana@example.com", { ...point(TEAM_01), receivedAt: Timestamp.now() }],
    ["a receivedAt that is not a timestamp", "ana", "ana@example.com", { ...point(TEAM_01), receivedAt: 1700000000000 }],
    ["an extra field", "ana", "ana@example.com", { ...point(TEAM_01), speed: 3 }],
  ];
  for (const [label, who, owner, data] of deniedWrites) {
    test(`Sad Path: creating a point is denied for ${label}`, async () => {
      // 1. Arrange
      const batch = batchWithPoint(who, owner, data);

      // 2. Act
      const write = batch.commit();

      // 3. Assert
      await assertFails(write);
    });
  }

  test("Sad Path: mia's own position with a point of another organization's team is denied", async () => {
    // 1. Arrange: mia's document exists in rotasul, sharing in rotasul01.
    await seed((admin) => setDoc(doc(admin, `${HERE}/positions/mia@example.com`), stored("mia@example.com", TEAM_01)));
    const batch = batchWithPoint("mia", "mia@example.com", point(OTHER_TEAM));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertFails(write);
  });

  const allowedReads = [
    ["Happy Path: the person reads their own trail", "ana", "ana@example.com"],
    ["Happy Path: a watcher of the current team reads the trail", "vera", "ana@example.com"],
    ["Happy Path: an administrator reads the trail", "olga", "bia@example.com"],
  ];
  for (const [label, who, owner] of allowedReads) {
    test(`${label} (${who} → ${owner})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDocs(collection(db, `${HERE}/positions/${owner}/trail`));

      // 3. Assert
      await assertSucceeds(read);
    });
  }

  const deniedReads = [
    ["a field-only person reading someone else's trail", "duda", "bia@example.com"],
    ["a watcher of another team", "walter", "ana@example.com"],
    ["an administrator of another organization", "otto", "ana@example.com"],
    ["an administrator of rotasul reading a trail whose team is another organization's", "olga", "zeca@example.com"],
  ];
  for (const [label, who, owner] of deniedReads) {
    test(`Sad Path: reading the trail is denied for ${label}`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDocs(collection(db, `${HERE}/positions/${owner}/trail`));

      // 3. Assert
      await assertFails(read);
    });
  }

  // The trail follows the person's CURRENT team, not the team of each point.
  test("Edge Case: a watcher of the current team reads points of an old team", async () => {
    // 1. Arrange
    await seed((admin) =>
      setDoc(doc(admin, `${HERE}/positions/bia@example.com/trail/p0`), storedPoint(TEAM_01))
    );
    const db = dbOf("walter");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/positions/bia@example.com/trail/p0`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: a watcher of a former team cannot read the trail", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/positions/bia@example.com/trail/p1`));

    // 3. Assert
    await assertFails(read);
  });

  for (const [label, write] of [
    ["updating", (db) => updateDoc(doc(db, `${HERE}/positions/ana@example.com/trail/p1`), { lat: 0 })],
    ["deleting", (db) => deleteDoc(doc(db, `${HERE}/positions/ana@example.com/trail/p1`))],
  ]) {
    test(`Sad Path: ${label} their own point is denied`, async () => {
      // 1. Arrange
      const db = dbOf("ana");

      // 2. Act
      const action = write(db);

      // 3. Assert
      await assertFails(action);
    });
  }
});

describe("organization rules: positions/{email}/trailDays/{day} - Rules Test Suite", () => {
  const DAY = "2026-10-27";

  /** A day summary as the app writes it with each position. */
  function summary(groupId) {
    const data = { lastAt: serverTimestamp(), pointCount: increment(1) };
    if (groupId !== undefined) data.groupId = groupId;
    return data;
  }

  /** A day summary as stored (seeded). */
  function storedSummary(groupId) {
    return { lastAt: LONG_AGO, pointCount: 3, groupId };
  }

  /** A batch with `who`'s position update and `owner`'s summary of `day`. */
  function batchWithSummary(who, owner, data, day = DAY) {
    const db = dbOf(who);
    const batch = writeBatch(db);
    batch.update(doc(db, `${HERE}/positions/${people[who].email}`), moved);
    batch.set(doc(db, `${HERE}/positions/${owner}/trailDays/${day}`), data, { merge: true });
    return batch;
  }

  beforeEach(async () => {
    await seed(async (db) => {
      await setDoc(doc(db, `${HERE}/positions/ana@example.com/trailDays/${DAY}`), storedSummary(TEAM_01));
      await setDoc(doc(db, `${HERE}/positions/caio@example.com/trailDays/${DAY}`), storedSummary(TEAM_01));
      // bia shares in rotasul02 now; this day was shared in rotasul01.
      await setDoc(doc(db, `${HERE}/positions/bia@example.com/trailDays/${DAY}`), storedSummary(TEAM_01));
      await setDoc(doc(db, `${HERE}/positions/zeca@example.com/trailDays/${DAY}`), storedSummary(OTHER_TEAM));
      // People who do not share, with a live document, so only the
      // summary rule decides.
      await setDoc(doc(db, `${HERE}/positions/vera@example.com`), stored("vera@example.com", TEAM_01));
      await setDoc(doc(db, `${HERE}/positions/mia@example.com`), stored("mia@example.com", TEAM_01));
      await setDoc(doc(db, `${HERE}/positions/lia@example.com`), stored("lia@example.com", TEAM_01));
      await setDoc(doc(db, `${HERE}/positions/duda@example.com`), stored("duda@example.com", TEAM_01));
    });
  });

  test("Happy Path: a new day's summary in the same batch as the position is accepted", async () => {
    // 1. Arrange
    const batch = batchWithSummary("ana", "ana@example.com", summary(TEAM_01), "2026-10-28");

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Happy Path: an existing day's summary is incremented with the position", async () => {
    // 1. Arrange
    const batch = batchWithSummary("ana", "ana@example.com", summary(TEAM_01));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a summary without groupId is accepted", async () => {
    // 1. Arrange
    const batch = batchWithSummary("ana", "ana@example.com", summary(), "2026-10-28");

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a summary with groupId null is accepted", async () => {
    // 1. Arrange
    const batch = batchWithSummary("ana", "ana@example.com", summary(null), "2026-10-28");

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: pointCount as a plain int is accepted", async () => {
    // 1. Arrange
    const batch = batchWithSummary("ana", "ana@example.com", { ...summary(TEAM_01), pointCount: 1 }, "2026-10-28");

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Sad Path: a summary written alone, without the position, is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/positions/ana@example.com/trailDays/2026-10-28`), summary(TEAM_01));

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a summary batched with a heartbeat (no new position) is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");
    const batch = writeBatch(db);
    batch.update(doc(db, `${HERE}/positions/ana@example.com`), { capturedAt: new Date() });
    batch.set(doc(db, `${HERE}/positions/ana@example.com/trailDays/2026-10-28`), summary(TEAM_01));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertFails(write);
  });

  const deniedWrites = [
    ["a watch-only person", "vera", "vera@example.com", summary(TEAM_01), DAY],
    ["someone else's summary", "duda", "ana@example.com", summary(TEAM_01), DAY],
    ["a person without the organizations claim", "lia", "lia@example.com", summary(TEAM_01), DAY],
    ["a team where they do not share", "ana", "ana@example.com", summary(TEAM_02), DAY],
    ["another organization's team where they share", "mia", "mia@example.com", summary(OTHER_TEAM), DAY],
    ["a client lastAt", "ana", "ana@example.com", { ...summary(TEAM_01), lastAt: Timestamp.now() }, DAY],
    ["pointCount that is not a number", "ana", "ana@example.com", { ...summary(TEAM_01), pointCount: "1" }, DAY],
    ["pointCount that is not an int", "ana", "ana@example.com", { ...summary(TEAM_01), pointCount: 1.5 }, DAY],
    ["an extra field", "ana", "ana@example.com", { ...summary(TEAM_01), lat: -22.9 }, DAY],
    ["a day id without zero padding", "ana", "ana@example.com", summary(TEAM_01), "2026-10-7"],
    ["a day id in another order", "ana", "ana@example.com", summary(TEAM_01), "27-10-2026"],
    ["a day id with a suffix", "ana", "ana@example.com", summary(TEAM_01), "2026-10-27x"],
    ["a day id that is not a date", "ana", "ana@example.com", summary(TEAM_01), "today"],
  ];
  for (const [label, who, owner, data, day] of deniedWrites) {
    test(`Sad Path: writing a day summary is denied for ${label}`, async () => {
      // 1. Arrange
      const batch = batchWithSummary(who, owner, data, day);

      // 2. Act
      const write = batch.commit();

      // 3. Assert
      await assertFails(write);
    });
  }

  const allowedReads = [
    ["Happy Path: the person reads their own summaries", "ana", "ana@example.com"],
    ["Happy Path: a watcher of the current team reads the summaries", "vera", "ana@example.com"],
    ["Happy Path: an administrator reads the summaries", "olga", "bia@example.com"],
  ];
  for (const [label, who, owner] of allowedReads) {
    test(`${label} (${who} → ${owner})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDocs(collection(db, `${HERE}/positions/${owner}/trailDays`));

      // 3. Assert
      await assertSucceeds(read);
    });
  }

  const deniedReads = [
    ["a field-only person reading someone else's", "ana", "caio@example.com"],
    ["a watcher of another team", "walter", "ana@example.com"],
    ["a member of another organization", "otto", "ana@example.com"],
    ["an administrator of rotasul reading a person whose team is another organization's", "olga", "zeca@example.com"],
  ];
  for (const [label, who, owner] of deniedReads) {
    test(`Sad Path: reading day summaries is denied for ${label}`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDoc(doc(db, `${HERE}/positions/${owner}/trailDays/${DAY}`));

      // 3. Assert
      await assertFails(read);
    });
  }

  test("Sad Path: reading day summaries is denied when unauthenticated", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/positions/ana@example.com/trailDays/${DAY}`));

    // 3. Assert
    await assertFails(read);
  });

  // Summaries follow the person's CURRENT team, not the team of each day.
  test("Edge Case: a watcher of the current team reads a day shared with an old team", async () => {
    // 1. Arrange
    const db = dbOf("walter");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/positions/bia@example.com/trailDays/${DAY}`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: a watcher of a former team cannot read the day", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/positions/bia@example.com/trailDays/${DAY}`));

    // 3. Assert
    await assertFails(read);
  });

  test("Sad Path: deleting their own day summary is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = deleteDoc(doc(db, `${HERE}/positions/ana@example.com/trailDays/${DAY}`));

    // 3. Assert
    await assertFails(write);
  });
});

describe("organization rules: config/branding - Rules Test Suite", () => {
  test("Happy Path: an unauthenticated client reads the branding", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/config/branding`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Edge Case: a member of another organization reads the branding", async () => {
    // 1. Arrange
    const db = dbOf("otto");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/config/branding`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: even an administrator cannot write the branding", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/config/branding`), { name: "Outro" });

    // 3. Assert
    await assertFails(write);
  });
});

describe("organization rules: config/plan - Rules Test Suite", () => {
  test("Happy Path: a member reads the plan", async () => {
    // 1. Arrange
    const db = dbOf("otto");

    // 2. Act
    const read = getDoc(doc(db, `${THERE}/config/plan`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Edge Case: a member reads a plan that does not exist (Standard)", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/config/plan`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: an unauthenticated client cannot read the plan", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, `${THERE}/config/plan`));

    // 3. Assert
    await assertFails(read);
  });

  test("Sad Path: even an administrator cannot write the plan", async () => {
    // 1. Arrange
    const db = dbOf("otto");

    // 2. Act
    const write = setDoc(doc(db, `${THERE}/config/plan`), { minIntervalMinutes: 0 });

    // 3. Assert
    await assertFails(write);
  });
});

/** config/tracking as an administrator's app writes it. */
function trackingBy(email, intervalMinutes = 5, distanceMeters = 10) {
  return { intervalMinutes, distanceMeters, updatedAt: serverTimestamp(), updatedBy: email };
}

describe("organization rules: config/tracking - Rules Test Suite", () => {
  test("Happy Path: a member reads the tracking settings", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/config/tracking`), { intervalMinutes: 5, distanceMeters: 10 }));
    const db = dbOf("ana");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/config/tracking`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: a member of another organization cannot read the tracking settings", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/config/tracking`), { intervalMinutes: 5, distanceMeters: 10 }));
    const db = dbOf("otto");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/config/tracking`));

    // 3. Assert
    await assertFails(read);
  });

  test("Sad Path: an unauthenticated client cannot read the tracking settings", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/config/tracking`));

    // 3. Assert
    await assertFails(read);
  });

  test("Happy Path: an administrator writes allowed values (no plan: 1 min, 5 m)", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/config/tracking`), trackingBy("olga@example.com", 1, 5));

    // 3. Assert
    await assertSucceeds(write);
  });

  const allowedOnCommunity = [
    ["Edge Case: on a 15-minute plan an administrator writes 15 minutes", 15],
    ["Edge Case: on a 15-minute plan an administrator writes 30 minutes", 30],
  ];
  for (const [label, minutes] of allowedOnCommunity) {
    test(label, async () => {
      // 1. Arrange
      const db = dbOf("otto");

      // 2. Act
      const write = setDoc(doc(db, `${THERE}/config/tracking`), trackingBy("otto@example.com", minutes, 100));

      // 3. Assert
      await assertSucceeds(write);
    });
  }

  const denied = [
    ["a member who is not an administrator", "ana", HERE, trackingBy("ana@example.com")],
    ["an administrator of another organization", "otto", HERE, trackingBy("otto@example.com")],
    ["interval 4, not an allowed value", "olga", HERE, trackingBy("olga@example.com", 4, 10)],
    ["distance 15, not an allowed value", "olga", HERE, trackingBy("olga@example.com", 5, 15)],
    [
      "a client timestamp in updatedAt",
      "olga",
      HERE,
      { ...trackingBy("olga@example.com"), updatedAt: Timestamp.now() },
    ],
    ["someone else's e-mail in updatedBy", "olga", HERE, trackingBy("ana@example.com")],
    ["an extra field", "olga", HERE, { ...trackingBy("olga@example.com"), extra: true }],
    ["interval 5 on a 15-minute plan", "otto", THERE, trackingBy("otto@example.com", 5, 100)],
  ];
  for (const [label, who, organization, data] of denied) {
    test(`Sad Path: write denied with ${label} (${who})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const write = setDoc(doc(db, `${organization}/config/tracking`), data);

      // 3. Assert
      await assertFails(write);
    });
  }
});

// zack has every capability in rotasul (share, watch, admin) and none in
// outro; nothing under organizations/outro is his, whatever his claims allow in
// rotasul.
describe("organization rules: cross-organization isolation - Rules Test Suite", () => {
  test("Happy Path: zack reads a member of his own organization", async () => {
    // 1. Arrange
    const db = dbOf("zack");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/positions/ana@example.com`));

    // 3. Assert
    await assertSucceeds(read);
  });

  const deniedReads = [
    ["another organization's member", `${THERE}/positions/oscar@example.com`],
    ["his own document left in another organization", `${THERE}/positions/zack@example.com`],
    ["another organization's trail point", `${THERE}/positions/oscar@example.com/trail/p1`],
    ["his own trail point left in another organization", `${THERE}/positions/zack@example.com/trail/p1`],
    ["another organization's plan", `${THERE}/config/plan`],
  ];
  for (const [label, target] of deniedReads) {
    test(`Sad Path: reading ${label} is denied (${target})`, async () => {
      // 1. Arrange
      const db = dbOf("zack");

      // 2. Act
      const read = getDoc(doc(db, target));

      // 3. Assert
      await assertFails(read);
    });
  }

  test("Sad Path: listing another organization's trail is denied", async () => {
    // 1. Arrange
    const db = dbOf("zack");

    // 2. Act
    const read = getDocs(collection(db, `${THERE}/positions/oscar@example.com/trail`));

    // 3. Assert
    await assertFails(read);
  });

  test("Sad Path: creating his own document in another organization is denied", async () => {
    // 1. Arrange
    await seed((admin) => deleteDoc(doc(admin, `${THERE}/positions/zack@example.com`)));
    const db = dbOf("zack");

    // 2. Act
    const write = setDoc(doc(db, `${THERE}/positions/zack@example.com`), signIn("zack@example.com", null));

    // 3. Assert
    await assertFails(write);
  });

  const deniedWrites = [
    ["another organization's plan", `${THERE}/config/plan`, { minIntervalMinutes: 0 }],
    ["another organization's branding", `${THERE}/config/branding`, { name: "Zack" }],
  ];
  for (const [label, target, data] of deniedWrites) {
    test(`Sad Path: writing ${label} in another organization is denied (${target})`, async () => {
      // 1. Arrange
      const db = dbOf("zack");

      // 2. Act
      const write = setDoc(doc(db, target), data);

      // 3. Assert
      await assertFails(write);
    });
  }

  test("Sad Path: moving his own position in another organization is denied", async () => {
    // 1. Arrange
    const db = dbOf("zack");

    // 2. Act
    const write = updateDoc(doc(db, `${THERE}/positions/zack@example.com`), moved);

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a position and point batch in another organization is denied", async () => {
    // 1. Arrange
    const db = dbOf("zack");
    const batch = writeBatch(db);
    batch.update(doc(db, `${THERE}/positions/zack@example.com`), moved);
    batch.set(doc(collection(db, `${THERE}/positions/zack@example.com/trail`)), point(null));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a member of another organization cannot write in rotasul with outro's team", async () => {
    // 1. Arrange
    const db = dbOf("otto");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/positions/otto@example.com`), signIn("otto@example.com", OTHER_TEAM));

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: groupId of another organization's team under rotasul is denied", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/positions/mia@example.com`), stored("mia@example.com", TEAM_01)));
    const db = dbOf("mia");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/positions/mia@example.com`), { groupId: OTHER_TEAM });

    // 3. Assert
    await assertFails(write);
  });
});

describe("organization rules: root paths - Rules Test Suite", () => {
  test("Happy Path: the same document under the organization is readable", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/positions/ana@example.com`));

    // 3. Assert
    await assertSucceeds(read);
  });

  const deniedReads = [
    ["an administrator reading positions", "olga", "positions/ana@example.com"],
    ["the person reading their own root document", "ana", "positions/ana@example.com"],
    ["a member reading config/branding", "ana", "config/branding"],
  ];
  for (const [label, who, target] of deniedReads) {
    test(`Sad Path: ${label} at the root is denied (${target})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDoc(doc(db, target));

      // 3. Assert
      await assertFails(read);
    });
  }

  test("Sad Path: an unauthenticated client cannot read the root branding", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, "config/branding"));

    // 3. Assert
    await assertFails(read);
  });

  test("Sad Path: a field person cannot write their position at the root", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, "positions/ana@example.com"), moved);

    // 3. Assert
    await assertFails(write);
  });
});
