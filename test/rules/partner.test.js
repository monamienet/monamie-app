// Security rules of a partner project (firestore.rules), against the
// Firestore emulator. Capabilities come from the custom claims share, watch
// (team keys) and owns (partner ids) that syncClaims sets.
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
  setDoc,
  updateDoc,
} = require("firebase/firestore");

const rulesPath = path.join(__dirname, "..", "..", "firestore.rules");

const TEAM_01 = "rotasul01@monamienet.org";
const TEAM_02 = "rotasul02@monamienet.org";
const OTHER_TEAM = "outro01@monamienet.org";

/** A live position document, as the tracking service writes it. */
function position(email, grupoAtivo) {
  return {
    email,
    nome: email.split("@")[0],
    lat: -22.9,
    lng: -43.1,
    timestamp: Timestamp.fromMillis(1_700_000_000_000),
    isTracked: true,
    grupo_ativo: grupoAtivo,
  };
}

/** A trail point. */
function point(grupoAtivo) {
  const data = {
    lat: -22.9,
    lng: -43.1,
    timestamp: Timestamp.fromMillis(1_700_000_000_000),
  };
  if (grupoAtivo !== undefined) data.grupo_ativo = grupoAtivo;
  return data;
}

/** People and their claims. */
const people = {
  // Field person of rotasul01: shares only.
  ana: { email: "ana@example.com", share: ["rotasul01"] },
  // Field person of rotasul02.
  bia: { email: "bia@example.com", share: ["rotasul02"] },
  // Watches rotasul01's map only.
  vera: { email: "vera@example.com", watch: ["rotasul01"] },
  // Watches rotasul02's map only.
  walter: { email: "walter@example.com", watch: ["rotasul02"] },
  // Shares and watches in rotasul01.
  duda: { email: "duda@example.com", share: ["rotasul01"], watch: ["rotasul01"] },
  // Owner of rotasul.
  olga: { email: "olga@example.com", owns: ["rotasul"] },
  // Watcher and owner of another partner.
  otto: { email: "otto@example.com", watch: ["outro01"], owns: ["outro"] },
};

let env;

function dbOf(name) {
  const { email, ...claims } = people[name];
  return env.authenticatedContext(name, { email, ...claims }).firestore();
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
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "usuarios/ana@example.com"), position("ana@example.com", TEAM_01));
    await setDoc(doc(db, "usuarios/bia@example.com"), position("bia@example.com", TEAM_02));
    await setDoc(doc(db, "usuarios/caio@example.com"), position("caio@example.com", TEAM_01));
    await setDoc(doc(db, "usuarios/zeca@example.com"), position("zeca@example.com", OTHER_TEAM));
    await setDoc(doc(db, "usuarios/ana@example.com/historico_posicoes/p1"), point(TEAM_01));
    await setDoc(doc(db, "usuarios/bia@example.com/historico_posicoes/p1"), point(TEAM_02));
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
      const read = getDoc(doc(db, `usuarios/${target}`));

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
    ["the owner of rotasul reading another partner's member", "olga", "zeca@example.com"],
  ];
  for (const [label, who, target] of denied) {
    test(`Sad Path: ${label} is denied (${who} → ${target})`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDoc(doc(db, `usuarios/${target}`));

      // 3. Assert
      await assertFails(read);
    });
  }

  test("Sad Path: an unauthenticated client is denied", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, "usuarios/ana@example.com"));

    // 3. Assert
    await assertFails(read);
  });
});

describe("partner rules: write usuarios/{email} - Rules Test Suite", () => {
  test("Happy Path: a field person creates their own document", async () => {
    // 1. Arrange
    const db = dbOf("duda");

    // 2. Act
    const write = setDoc(doc(db, "usuarios/duda@example.com"), position("duda@example.com", TEAM_01));

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Happy Path: a field person updates their own position", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, "usuarios/ana@example.com"), { lat: -23.0, lng: -43.2 });

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a document without grupo_ativo is accepted", async () => {
    // 1. Arrange
    const db = dbOf("duda");
    const { grupo_ativo: _ignored, ...data } = position("duda@example.com", TEAM_01);

    // 2. Act
    const write = setDoc(doc(db, "usuarios/duda@example.com"), data);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Sad Path: a watch-only person cannot write their own document", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const write = setDoc(doc(db, "usuarios/vera@example.com"), position("vera@example.com", TEAM_01));

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: the owner cannot write their own document", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const write = setDoc(doc(db, "usuarios/olga@example.com"), position("olga@example.com", TEAM_01));

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: a field person cannot write someone else's document", async () => {
    // 1. Arrange
    const db = dbOf("duda");

    // 2. Act
    const write = setDoc(doc(db, "usuarios/ana@example.com"), position("ana@example.com", TEAM_01));

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: grupo_ativo of a team where they do not share is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = updateDoc(doc(db, "usuarios/ana@example.com"), { grupo_ativo: TEAM_02 });

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: an extra field is denied", async () => {
    // 1. Arrange
    const db = dbOf("duda");
    const data = { ...position("duda@example.com", TEAM_01), role: "admin" };

    // 2. Act
    const write = setDoc(doc(db, "usuarios/duda@example.com"), data);

    // 3. Assert
    await assertFails(write);
  });

  test("Sad Path: deleting their own document is denied", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = deleteDoc(doc(db, "usuarios/ana@example.com"));

    // 3. Assert
    await assertFails(write);
  });
});

describe("partner rules: usuarios/{email}/historico_posicoes - Rules Test Suite", () => {
  test("Happy Path: a field person adds a point to their own trail", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = addDoc(collection(db, "usuarios/ana@example.com/historico_posicoes"), point(TEAM_01));

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a point without grupo_ativo is accepted", async () => {
    // 1. Arrange
    const db = dbOf("ana");

    // 2. Act
    const write = addDoc(collection(db, "usuarios/ana@example.com/historico_posicoes"), point());

    // 3. Assert
    await assertSucceeds(write);
  });

  const deniedWrites = [
    ["a watch-only person", "vera", "vera@example.com", point(TEAM_01)],
    ["someone else's trail", "duda", "ana@example.com", point(TEAM_01)],
    ["a team where they do not share", "ana", "ana@example.com", point(TEAM_02)],
    ["a latitude that is not a number", "ana", "ana@example.com", { ...point(TEAM_01), lat: "-22.9" }],
    ["a timestamp that is not a timestamp", "ana", "ana@example.com", { ...point(TEAM_01), timestamp: 1700000000000 }],
    ["an extra field", "ana", "ana@example.com", { ...point(TEAM_01), speed: 3 }],
  ];
  for (const [label, who, owner, data] of deniedWrites) {
    test(`Sad Path: creating a point is denied for ${label}`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const write = addDoc(collection(db, `usuarios/${owner}/historico_posicoes`), data);

      // 3. Assert
      await assertFails(write);
    });
  }

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
      const read = getDocs(collection(db, `usuarios/${owner}/historico_posicoes`));

      // 3. Assert
      await assertSucceeds(read);
    });
  }

  const deniedReads = [
    ["a field-only person reading someone else's trail", "duda", "bia@example.com"],
    ["a watcher of another team", "walter", "ana@example.com"],
    ["the owner of another partner", "otto", "ana@example.com"],
  ];
  for (const [label, who, owner] of deniedReads) {
    test(`Sad Path: reading the trail is denied for ${label}`, async () => {
      // 1. Arrange
      const db = dbOf(who);

      // 2. Act
      const read = getDocs(collection(db, `usuarios/${owner}/historico_posicoes`));

      // 3. Assert
      await assertFails(read);
    });
  }

  // The trail follows the person's CURRENT team, not the team of each point.
  test("Edge Case: a watcher of the current team reads points of an old team", async () => {
    // 1. Arrange
    await env.withSecurityRulesDisabled(async (context) => {
      const admin = context.firestore();
      await setDoc(doc(admin, "usuarios/bia@example.com/historico_posicoes/p0"), point(TEAM_01));
    });
    const db = dbOf("walter");

    // 2. Act
    const read = getDoc(doc(db, "usuarios/bia@example.com/historico_posicoes/p0"));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: a watcher of a former team cannot read the trail", async () => {
    // 1. Arrange
    const db = dbOf("vera");

    // 2. Act
    const read = getDoc(doc(db, "usuarios/bia@example.com/historico_posicoes/p1"));

    // 3. Assert
    await assertFails(read);
  });

  for (const [label, write] of [
    ["updating", (db) => updateDoc(doc(db, "usuarios/ana@example.com/historico_posicoes/p1"), { lat: 0 })],
    ["deleting", (db) => deleteDoc(doc(db, "usuarios/ana@example.com/historico_posicoes/p1"))],
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

describe("partner rules: config/branding - Rules Test Suite", () => {
  test("Happy Path: an unauthenticated client reads the branding", async () => {
    // 1. Arrange
    const db = env.unauthenticatedContext().firestore();

    // 2. Act
    const read = getDoc(doc(db, "config/branding"));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Edge Case: the owner reads the branding", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const read = getDoc(doc(db, "config/branding"));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: even the owner cannot write the branding", async () => {
    // 1. Arrange
    const db = dbOf("olga");

    // 2. Act
    const write = setDoc(doc(db, "config/branding"), { name: "Outro" });

    // 3. Assert
    await assertFails(write);
  });
});
