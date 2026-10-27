// Security rules of a partner project (firestore.rules), against the
// Firestore emulator. Every partner's data lives under partners/{partnerId}.
// Capabilities come from the custom claims share, watch (team keys), owns
// and partners (partner ids) that syncClaims sets.
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
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} = require("firebase/firestore");

const rulesPath = path.join(__dirname, "..", "..", "firestore.rules");

const HERE = "partners/rotasul";
const THERE = "partners/outro";

const TEAM_01 = "rotasul01@monamienet.org";
const TEAM_02 = "rotasul02@monamienet.org";
const OTHER_TEAM = "outro01@monamienet.org";

const LONG_AGO = Timestamp.fromMillis(1_700_000_000_000);

/** A live position document as stored (seeded with rules disabled). */
function stored(email, grupoAtivo) {
  return {
    email,
    nome: email.split("@")[0],
    lat: -22.9,
    lng: -43.1,
    timestamp: LONG_AGO,
    positionAt: LONG_AGO,
    isTracked: true,
    grupo_ativo: grupoAtivo,
  };
}

/** A new live position, as the tracking service writes it. */
function position(email, grupoAtivo) {
  return {
    email,
    nome: email.split("@")[0],
    lat: -22.9,
    lng: -43.1,
    timestamp: Timestamp.now(),
    positionAt: serverTimestamp(),
    isTracked: true,
    grupo_ativo: grupoAtivo,
  };
}

/** The document written at sign-in, before any position. */
function signIn(email, grupoAtivo) {
  return { email, nome: email.split("@")[0], isTracked: false, grupo_ativo: grupoAtivo };
}

/** A position move of an existing document. */
const moved = { lat: -23.0, lng: -43.2, positionAt: serverTimestamp() };

/** A trail point as the app writes it. */
function point(grupoAtivo) {
  const data = { lat: -23.0, lng: -43.2, timestamp: serverTimestamp() };
  if (grupoAtivo !== undefined) data.grupo_ativo = grupoAtivo;
  return data;
}

/** A trail point as stored (seeded). */
function storedPoint(grupoAtivo) {
  return { lat: -22.9, lng: -43.1, timestamp: LONG_AGO, grupo_ativo: grupoAtivo };
}

/** People and their claims. */
const people = {
  // Field person of rotasul01: shares only.
  ana: { email: "ana@example.com", share: ["rotasul01"], partners: ["rotasul"] },
  // Field person of rotasul02.
  bia: { email: "bia@example.com", share: ["rotasul02"], partners: ["rotasul"] },
  // Watches rotasul01's map only.
  vera: { email: "vera@example.com", watch: ["rotasul01"], partners: ["rotasul"] },
  // Watches rotasul02's map only.
  walter: { email: "walter@example.com", watch: ["rotasul02"], partners: ["rotasul"] },
  // Shares and watches in rotasul01.
  duda: {
    email: "duda@example.com",
    share: ["rotasul01"],
    watch: ["rotasul01"],
    partners: ["rotasul"],
  },
  // Owner of rotasul.
  olga: { email: "olga@example.com", owns: ["rotasul"], partners: ["rotasul"] },
  // Watcher and owner of another partner.
  otto: { email: "otto@example.com", watch: ["outro01"], owns: ["outro"], partners: ["outro"] },
  // Every capability in rotasul, none in outro.
  zack: {
    email: "zack@example.com",
    share: ["rotasul01"],
    watch: ["rotasul01"],
    owns: ["rotasul"],
    partners: ["rotasul"],
  },
  // Shares in a team of each partner.
  mia: {
    email: "mia@example.com",
    share: ["outro01", "rotasul01"],
    partners: ["outro", "rotasul"],
  },
  // Shares in rotasul01 but has no `partners` claim (claims of before #94).
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
    projectId: "demo-partner",
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
    await setDoc(doc(db, `${HERE}/usuarios/ana@example.com`), stored("ana@example.com", TEAM_01));
    await setDoc(doc(db, `${HERE}/usuarios/bia@example.com`), stored("bia@example.com", TEAM_02));
    await setDoc(doc(db, `${HERE}/usuarios/caio@example.com`), stored("caio@example.com", TEAM_01));
    // A document of partner A naming a team of another partner.
    await setDoc(doc(db, `${HERE}/usuarios/zeca@example.com`), stored("zeca@example.com", OTHER_TEAM));
    await setDoc(doc(db, `${HERE}/usuarios/ana@example.com/historico_posicoes/p1`), storedPoint(TEAM_01));
    await setDoc(doc(db, `${HERE}/usuarios/bia@example.com/historico_posicoes/p1`), storedPoint(TEAM_02));
    await setDoc(doc(db, `${HERE}/users/ana`), { name: "Ana", email: "ana@example.com" });
    await setDoc(doc(db, `${HERE}/config/branding`), { name: "Rota Sul" });

    await setDoc(doc(db, `${THERE}/usuarios/oscar@example.com`), stored("oscar@example.com", OTHER_TEAM));
    await setDoc(doc(db, `${THERE}/usuarios/zack@example.com`), stored("zack@example.com", OTHER_TEAM));
    await setDoc(doc(db, `${THERE}/usuarios/oscar@example.com/historico_posicoes/p1`), storedPoint(OTHER_TEAM));
    await setDoc(doc(db, `${THERE}/usuarios/zack@example.com/historico_posicoes/p1`), storedPoint(OTHER_TEAM));
    await setDoc(doc(db, `${THERE}/users/oscar`), { name: "Oscar", email: "oscar@example.com" });
    await setDoc(doc(db, `${THERE}/config/plan`), { minIntervalMinutes: 15 });
    await setDoc(doc(db, `${THERE}/config/branding`), { name: "Outro" });

    // The layout before #94, at the root.
    await setDoc(doc(db, "usuarios/ana@example.com"), stored("ana@example.com", TEAM_01));
    await setDoc(doc(db, "users/ana"), { name: "Ana", email: "ana@example.com" });
    await setDoc(doc(db, "config/branding"), { name: "Rota Sul" });
  });
});

after(async () => {
  await env.cleanup();
});

describe("partner rules: read usuarios/{email} - Rules Test Suite", () => {
  const allowed = [
    ["Happy Path: the person reads their own document", "ana", "ana@example.com"],
    ["Happy Path: a watcher of the team reads a member", "vera", "ana@example.com"],
    ["Happy Path: the owner reads a member of team 01", "olga", "ana@example.com"],
    ["Happy Path: the owner reads a member of team 02", "olga", "bia@example.com"],
    ["Edge Case: a person who shares and watches reads a teammate", "duda", "ana@example.com"],
  ];
  for (const [label, who, target] of allowed) {
    test(`${label} (${who} → ${target})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDoc(doc(db, `${HERE}/usuarios/${target}`));

      // 3. Assert
      await assertSucceeds(read);
    });
  }

  const denied = [
    ["a field-only person reading a teammate", "ana", "caio@example.com"],
    ["a field-only person reading someone of another team", "ana", "bia@example.com"],
    ["a watcher of another team", "walter", "ana@example.com"],
    ["a watcher of another partner", "otto", "ana@example.com"],
    ["the owner of another partner", "otto", "bia@example.com"],
    ["the owner of rotasul reading a document naming another partner's team", "olga", "zeca@example.com"],
    ["the watcher of outro01 reading a document of rotasul naming outro01", "otto", "zeca@example.com"],
  ];
  for (const [label, who, target] of denied) {
    test(`Sad Path: ${label} is denied (${who} → ${target})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDoc(doc(db, `${HERE}/usuarios/${target}`));

      // 3. Assert
      await assertFails(read);
    });
  }

  test("Sad Path: an unauthenticated client is denied", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/usuarios/ana@example.com`));

    // 3. Assert
    await assertFails(read);
  });
});

describe("partner rules: write usuarios/{email} - Rules Test Suite", () => {
  test("Happy Path: a field person creates their own document with a position", async () => {
    // 1. Arrange
    const db = dbOf("duda");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/usuarios/duda@example.com`), position("duda@example.com", TEAM_01));

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Happy Path: a field person updates their own position", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/usuarios/ana@example.com`), moved);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: creating the document without a position at sign-in is accepted", async () => {
    // 1. Arrange
    const db = dbOf("duda");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/usuarios/duda@example.com`), signIn("duda@example.com", TEAM_01));

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a document without grupo_ativo is accepted", async () => {
    // 1. Arrange
    const db = dbOf("duda");
    const { grupo_ativo: _ignored, ...data } = position("duda@example.com", TEAM_01);

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/usuarios/duda@example.com`), data);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: grupo_ativo null is accepted", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/usuarios/ana@example.com`), { grupo_ativo: null });

    // 3. Assert
    await assertSucceeds(write);
  });

  const denied = [
    ["a watch-only person writing their own document", "vera", "vera@example.com", () => position("vera@example.com", TEAM_01)],
    ["the owner writing their own document", "olga", "olga@example.com", () => position("olga@example.com", TEAM_01)],
    ["a field person writing someone else's document", "duda", "ana@example.com", () => position("ana@example.com", TEAM_01)],
    ["a field person without the partners claim", "lia", "lia@example.com", () => position("lia@example.com", TEAM_01)],
    ["an e-mail field that is not their own", "duda", "duda@example.com", () => ({ ...position("duda@example.com", TEAM_01), email: "ana@example.com" })],
    ["an extra field", "duda", "duda@example.com", () => ({ ...position("duda@example.com", TEAM_01), role: "admin" })],
    ["grupo_ativo of a team where they do not share", "duda", "duda@example.com", () => position("duda@example.com", TEAM_02)],
    ["grupo_ativo of another partner's team where they share", "mia", "mia@example.com", () => position("mia@example.com", OTHER_TEAM)],
  ];
  for (const [label, who, target, data] of denied) {
    test(`Sad Path: ${label} is denied (${who} → ${target})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const write = setDoc(doc(db, `${HERE}/usuarios/${target}`), data());

      // 3. Assert
      await assertFails(write);
    });
  }

  test("Sad Path: deleting their own document is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = deleteDoc(doc(db, `${HERE}/usuarios/ana@example.com`));

    // 3. Assert
    await assertFails(write);
  });
});

describe("partner rules: position timing of usuarios/{email} - Rules Test Suite", () => {
  test("Happy Path: a heartbeat that does not move the position is accepted", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/usuarios/ana@example.com`), { timestamp: new Date() });

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Happy Path: without a plan (Standard) a second position right away is accepted", async () => {
    // 1. Arrange
    const db = dbOf("ana");
    const ref = doc(db, `${HERE}/usuarios/ana@example.com`);
    await assertSucceeds(updateDoc(ref, moved));

    // 2. Act
    const write = updateDoc(ref, { lat: -23.5, lng: -43.5, positionAt: serverTimestamp() });

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: with a 15-minute plan the first position after a long pause is accepted", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/config/plan`), { minIntervalMinutes: 15 }));
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/usuarios/ana@example.com`), moved);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Sad Path: with a 15-minute plan a second position right after the first is denied", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/config/plan`), { minIntervalMinutes: 15 }));
    const db = dbOf("ana");
    const ref = doc(db, `${HERE}/usuarios/ana@example.com`);
    await assertSucceeds(updateDoc(ref, moved));

    // 2. Act
    const write = updateDoc(ref, { lat: -23.5, lng: -43.5, positionAt: serverTimestamp() });

    // 3. Assert
    await assertFails(write);
  });

  const denied = [
    ["moving the position without positionAt", { lat: -23.0, lng: -43.2 }],
    ["moving only the latitude without positionAt", { lat: -23.0 }],
    ["moving the position with a client positionAt", { lat: -23.0, lng: -43.2, positionAt: Timestamp.now() }],
    ["a heartbeat that changes positionAt", { timestamp: new Date(), positionAt: serverTimestamp() }],
    ["a heartbeat that removes positionAt", { timestamp: new Date(), positionAt: null }],
  ];
  for (const [label, data] of denied) {
    test(`Sad Path: ${label} is denied`, async () => {
      // 1. Arrange
      const db = dbOf("ana");

      // 2. Act
      const write = updateDoc(doc(db, `${HERE}/usuarios/ana@example.com`), data);

      // 3. Assert
      await assertFails(write);
    });
  }

  const deniedCreates = [
    ["creating with a position but no positionAt", () => {
      const { positionAt: _ignored, ...data } = position("duda@example.com", TEAM_01);
      return data;
    }],
    ["creating with a position and a client positionAt", () => ({ ...position("duda@example.com", TEAM_01), positionAt: Timestamp.now() })],
    ["creating without a position but with positionAt", () => ({ ...signIn("duda@example.com", TEAM_01), positionAt: serverTimestamp() })],
  ];
  for (const [label, data] of deniedCreates) {
    test(`Sad Path: ${label} is denied`, async () => {
      // 1. Arrange
      const db = dbOf("duda");

      // 2. Act
      const write = setDoc(doc(db, `${HERE}/usuarios/duda@example.com`), data());

      // 3. Assert
      await assertFails(write);
    });
  }
});

describe("partner rules: usuarios/{email}/historico_posicoes - Rules Test Suite", () => {
  /** A batch with `who`'s position update and a point in `owner`'s trail. */
  function batchWithPoint(who, owner, data, { withPosition = true } = {}) {
    const db = dbOf(who);
    const batch = writeBatch(db);
    if (withPosition) {
      batch.update(doc(db, `${HERE}/usuarios/${people[who].email}`), moved);
    }
    batch.set(doc(collection(db, `${HERE}/usuarios/${owner}/historico_posicoes`)), data);
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

  test("Edge Case: a point without grupo_ativo is accepted", async () => {
    // 1. Arrange
    const batch = batchWithPoint("ana", "ana@example.com", point());

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a point with grupo_ativo null is accepted", async () => {
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
    const write = addDoc(collection(db, `${HERE}/usuarios/ana@example.com/historico_posicoes`), point(TEAM_01));

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a point batched with a heartbeat (no new position) is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");
    const batch = writeBatch(db);
    batch.update(doc(db, `${HERE}/usuarios/ana@example.com`), { timestamp: new Date() });
    batch.set(doc(collection(db, `${HERE}/usuarios/ana@example.com/historico_posicoes`)), point(TEAM_01));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertFails(write);
  });

  const deniedWrites = [
    ["a watch-only person", "vera", "vera@example.com", point(TEAM_01)],
    ["someone else's trail", "duda", "ana@example.com", point(TEAM_01)],
    ["a team where they do not share", "ana", "ana@example.com", point(TEAM_02)],
    ["another partner's team where they share", "mia", "mia@example.com", point(OTHER_TEAM)],
    ["a latitude that is not a number", "ana", "ana@example.com", { ...point(TEAM_01), lat: "-22.9" }],
    ["a longitude that is not a number", "ana", "ana@example.com", { ...point(TEAM_01), lng: null }],
    ["a client timestamp", "ana", "ana@example.com", { ...point(TEAM_01), timestamp: Timestamp.now() }],
    ["a timestamp that is not a timestamp", "ana", "ana@example.com", { ...point(TEAM_01), timestamp: 1700000000000 }],
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

  test("Sad Path: mia's own position with a point of another partner's team is denied", async () => {
    // 1. Arrange: mia's document exists in rotasul, sharing in rotasul01.
    await seed((admin) => setDoc(doc(admin, `${HERE}/usuarios/mia@example.com`), stored("mia@example.com", TEAM_01)));
    const batch = batchWithPoint("mia", "mia@example.com", point(OTHER_TEAM));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertFails(write);
  });

  const allowedReads = [
    ["Happy Path: the person reads their own trail", "ana", "ana@example.com"],
    ["Happy Path: a watcher of the current team reads the trail", "vera", "ana@example.com"],
    ["Happy Path: the owner reads the trail", "olga", "bia@example.com"],
  ];
  for (const [label, who, owner] of allowedReads) {
    test(`${label} (${who} → ${owner})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDocs(collection(db, `${HERE}/usuarios/${owner}/historico_posicoes`));

      // 3. Assert
      await assertSucceeds(read);
    });
  }

  const deniedReads = [
    ["a field-only person reading someone else's trail", "duda", "bia@example.com"],
    ["a watcher of another team", "walter", "ana@example.com"],
    ["the owner of another partner", "otto", "ana@example.com"],
    ["the owner of rotasul reading a trail whose team is another partner's", "olga", "zeca@example.com"],
  ];
  for (const [label, who, owner] of deniedReads) {
    test(`Sad Path: reading the trail is denied for ${label}`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDocs(collection(db, `${HERE}/usuarios/${owner}/historico_posicoes`));

      // 3. Assert
      await assertFails(read);
    });
  }

  // The trail follows the person's CURRENT team, not the team of each point.
  test("Edge Case: a watcher of the current team reads points of an old team", async () => {
    // 1. Arrange
    await seed((admin) =>
      setDoc(doc(admin, `${HERE}/usuarios/bia@example.com/historico_posicoes/p0`), storedPoint(TEAM_01))
    );
    const db = dbOf("walter");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/usuarios/bia@example.com/historico_posicoes/p0`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: a watcher of a former team cannot read the trail", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/usuarios/bia@example.com/historico_posicoes/p1`));

    // 3. Assert
    await assertFails(read);
  });

  for (const [label, write] of [
    ["updating", (db) => updateDoc(doc(db, `${HERE}/usuarios/ana@example.com/historico_posicoes/p1`), { lat: 0 })],
    ["deleting", (db) => deleteDoc(doc(db, `${HERE}/usuarios/ana@example.com/historico_posicoes/p1`))],
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

describe("partner rules: users/{uid} - Rules Test Suite", () => {
  const profile = {
    name: "Duda",
    email: "duda@example.com",
    urlImage: "https://example.com/duda.png",
    createdAt: Timestamp.now(),
    avatarBase64: "AAAA",
  };

  for (const [label, who] of [
    ["Happy Path: a field person of the partner reads a profile", "ana"],
    ["Edge Case: a watch-only member reads a profile", "vera"],
  ]) {
    test(`${label} (${who})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDoc(doc(db, `${HERE}/users/ana`));

      // 3. Assert
      await assertSucceeds(read);
    });
  }

  test("Sad Path: a member of another partner cannot read a profile", async () => {
    // 1. Arrange
    const db = dbOf("otto");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/users/ana`));

    // 3. Assert
    await assertFails(read);
  });

  test("Sad Path: an unauthenticated client cannot read a profile", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/users/ana`));

    // 3. Assert
    await assertFails(read);
  });

  test("Happy Path: a member creates their own profile", async () => {
    // 1. Arrange
    const db = dbOf("duda");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/users/duda`), profile);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a member updates their own profile", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/users/duda`), profile));
    const db = dbOf("duda");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/users/duda`), { name: "Duda S." });

    // 3. Assert
    await assertSucceeds(write);
  });

  const denied = [
    ["someone else's profile", "duda", "ana", profile],
    ["an extra field", "duda", "duda", { ...profile, role: "admin" }],
    ["a person without the partners claim", "lia", "lia", { ...profile, email: "lia@example.com" }],
    ["a member of another partner", "otto", "otto", { ...profile, email: "otto@example.com" }],
  ];
  for (const [label, who, uid, data] of denied) {
    test(`Sad Path: writing ${label} is denied (${who} → users/${uid})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const write = setDoc(doc(db, `${HERE}/users/${uid}`), data);

      // 3. Assert
      await assertFails(write);
    });
  }

  test("Sad Path: deleting their own profile is denied", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/users/duda`), profile));
    const db = dbOf("duda");

    // 2. Act
    const write = deleteDoc(doc(db, `${HERE}/users/duda`));

    // 3. Assert
    await assertFails(write);
  });
});

describe("partner rules: config/branding - Rules Test Suite", () => {
  test("Happy Path: an unauthenticated client reads the branding", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/config/branding`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Edge Case: a member of another partner reads the branding", async () => {
    // 1. Arrange
    const db = dbOf("otto");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/config/branding`));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: even the owner cannot write the branding", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/config/branding`), { name: "Outro" });

    // 3. Assert
    await assertFails(write);
  });
});

describe("partner rules: config/plan - Rules Test Suite", () => {
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

  test("Sad Path: even the owner cannot write the plan", async () => {
    // 1. Arrange
    const db = dbOf("otto");

    // 2. Act
    const write = setDoc(doc(db, `${THERE}/config/plan`), { minIntervalMinutes: 0 });

    // 3. Assert
    await assertFails(write);
  });
});

// zack has every capability in rotasul (share, watch, owns) and none in
// outro; nothing under partners/outro is his, whatever his claims allow in
// rotasul.
describe("partner rules: cross-partner isolation - Rules Test Suite", () => {
  test("Happy Path: zack reads a member of his own partner", async () => {
    // 1. Arrange
    const db = dbOf("zack");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/usuarios/ana@example.com`));

    // 3. Assert
    await assertSucceeds(read);
  });

  const deniedReads = [
    ["another partner's member", `${THERE}/usuarios/oscar@example.com`],
    ["his own document left in another partner", `${THERE}/usuarios/zack@example.com`],
    ["another partner's trail point", `${THERE}/usuarios/oscar@example.com/historico_posicoes/p1`],
    ["his own trail point left in another partner", `${THERE}/usuarios/zack@example.com/historico_posicoes/p1`],
    ["another partner's profile", `${THERE}/users/oscar`],
    ["another partner's plan", `${THERE}/config/plan`],
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

  test("Sad Path: listing another partner's trail is denied", async () => {
    // 1. Arrange
    const db = dbOf("zack");

    // 2. Act
    const read = getDocs(collection(db, `${THERE}/usuarios/oscar@example.com/historico_posicoes`));

    // 3. Assert
    await assertFails(read);
  });

  test("Sad Path: creating his own document in another partner is denied", async () => {
    // 1. Arrange
    await seed((admin) => deleteDoc(doc(admin, `${THERE}/usuarios/zack@example.com`)));
    const db = dbOf("zack");

    // 2. Act
    const write = setDoc(doc(db, `${THERE}/usuarios/zack@example.com`), signIn("zack@example.com", null));

    // 3. Assert
    await assertFails(write);
  });

  const deniedWrites = [
    ["his own profile", `${THERE}/users/zack`, { name: "Zack", email: "zack@example.com" }],
    ["another partner's plan", `${THERE}/config/plan`, { minIntervalMinutes: 0 }],
    ["another partner's branding", `${THERE}/config/branding`, { name: "Zack" }],
  ];
  for (const [label, target, data] of deniedWrites) {
    test(`Sad Path: writing ${label} in another partner is denied (${target})`, async () => {
      // 1. Arrange
      const db = dbOf("zack");

      // 2. Act
      const write = setDoc(doc(db, target), data);

      // 3. Assert
      await assertFails(write);
    });
  }

  test("Sad Path: moving his own position in another partner is denied", async () => {
    // 1. Arrange
    const db = dbOf("zack");

    // 2. Act
    const write = updateDoc(doc(db, `${THERE}/usuarios/zack@example.com`), moved);

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a position and point batch in another partner is denied", async () => {
    // 1. Arrange
    const db = dbOf("zack");
    const batch = writeBatch(db);
    batch.update(doc(db, `${THERE}/usuarios/zack@example.com`), moved);
    batch.set(doc(collection(db, `${THERE}/usuarios/zack@example.com/historico_posicoes`)), point(null));

    // 2. Act
    const write = batch.commit();

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a member of another partner cannot write in rotasul with outro's team", async () => {
    // 1. Arrange
    const db = dbOf("otto");

    // 2. Act
    const write = setDoc(doc(db, `${HERE}/usuarios/otto@example.com`), signIn("otto@example.com", OTHER_TEAM));

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: grupo_ativo of another partner's team under rotasul is denied", async () => {
    // 1. Arrange
    await seed((admin) => setDoc(doc(admin, `${HERE}/usuarios/mia@example.com`), stored("mia@example.com", TEAM_01)));
    const db = dbOf("mia");

    // 2. Act
    const write = updateDoc(doc(db, `${HERE}/usuarios/mia@example.com`), { grupo_ativo: OTHER_TEAM });

    // 3. Assert
    await assertFails(write);
  });
});

describe("partner rules: root paths of the old layout - Rules Test Suite", () => {
  test("Happy Path: the same document under the partner is readable", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const read = getDoc(doc(db, `${HERE}/usuarios/ana@example.com`));

    // 3. Assert
    await assertSucceeds(read);
  });

  const deniedReads = [
    ["the owner reading usuarios", "olga", "usuarios/ana@example.com"],
    ["the person reading their own root document", "ana", "usuarios/ana@example.com"],
    ["a member reading users", "ana", "users/ana"],
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
    const write = updateDoc(doc(db, "usuarios/ana@example.com"), moved);

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a member cannot write their profile at the root", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = setDoc(doc(db, "users/ana"), { name: "Ana", email: "ana@example.com" });

    // 3. Assert
    await assertFails(write);
  });
});
