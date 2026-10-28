// Security rules of the central MonAmie project (central/firestore.rules),
// against the Firestore emulator.
const { after, before, beforeEach, describe, test } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} = require("firebase/firestore");

const rulesPath = path.join(__dirname, "..", "..", "central", "firestore.rules");

/** A theme of the catalog, as `tool/partner.dart themes` writes it. */
const grafite = {
  name: "Grafite",
  primary: "#3F4754",
  dark: "#1F2128",
  light: "#DCDEE2",
  onPrimary: "#FFFFFF",
  onDark: "#FFFFFF",
  order: 8,
  active: true,
};

/** Who reaches the database: nobody signed in, or a signed-in user. */
const clients = {
  "an unauthenticated client": (env) => env.unauthenticatedContext().firestore(),
  "a signed-in client": (env) =>
    env.authenticatedContext("alice", { email: "alice@monamienet.org" }).firestore(),
};

/** Private documents of the central registry. */
const privatePaths = ["partners/acme", "retiredPartnerIds/acme"];

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-central",
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
    await setDoc(doc(db, "themes/grafite"), grafite);
    await setDoc(doc(db, "partners/acme"), { status: "active" });
    await setDoc(doc(db, "retiredPartnerIds/acme"), { retiredAt: 1 });
  });
});

after(async () => {
  await env.cleanup();
});

describe("central rules: themes/{themeId} - Rules Test Suite", () => {
  for (const [who, dbOf] of Object.entries(clients)) {
    test(`Happy Path: ${who} reads a theme`, async () => {
      // 1. Arrange
      const db = dbOf(env);

      // 2. Act
      const read = getDoc(doc(db, "themes/grafite"));

      // 3. Assert
      await assertSucceeds(read);
    });

    test(`Edge Case: ${who} lists the whole catalog`, async () => {
      // 1. Arrange
      const db = dbOf(env);

      // 2. Act
      const list = getDocs(collection(db, "themes"));

      // 3. Assert
      await assertSucceeds(list);
    });

    test(`Edge Case: ${who} reads a theme that does not exist`, async () => {
      // 1. Arrange
      const db = dbOf(env);

      // 2. Act
      const read = getDoc(doc(db, "themes/unknown"));

      // 3. Assert
      await assertSucceeds(read);
    });

    test(`Sad Path: ${who} cannot create a theme`, async () => {
      // 1. Arrange
      const db = dbOf(env);

      // 2. Act
      const write = setDoc(doc(db, "themes/neon"), { ...grafite, name: "Neon" });

      // 3. Assert
      await assertFails(write);
    });

    test(`Sad Path: ${who} cannot update a theme`, async () => {
      // 1. Arrange
      const db = dbOf(env);

      // 2. Act
      const write = updateDoc(doc(db, "themes/grafite"), { primary: "#FF0000" });

      // 3. Assert
      await assertFails(write);
    });

    test(`Sad Path: ${who} cannot delete a theme`, async () => {
      // 1. Arrange
      const db = dbOf(env);

      // 2. Act
      const write = deleteDoc(doc(db, "themes/grafite"));

      // 3. Assert
      await assertFails(write);
    });
  }
});

describe("central rules: every other path - Rules Test Suite", () => {
  for (const [who, dbOf] of Object.entries(clients)) {
    for (const docPath of privatePaths) {
      test(`Sad Path: ${who} cannot read ${docPath}`, async () => {
        // 1. Arrange
        const db = dbOf(env);

        // 2. Act
        const read = getDoc(doc(db, docPath));

        // 3. Assert
        await assertFails(read);
      });

      test(`Sad Path: ${who} cannot write ${docPath}`, async () => {
        // 1. Arrange
        const db = dbOf(env);

        // 2. Act
        const write = setDoc(doc(db, docPath), { status: "active" });

        // 3. Assert
        await assertFails(write);
      });
    }

    test(`Sad Path: ${who} cannot list the partner registry`, async () => {
      // 1. Arrange
      const db = dbOf(env);

      // 2. Act
      const list = getDocs(collection(db, "partners"));

      // 3. Assert
      await assertFails(list);
    });

    test(`Edge Case: ${who} cannot read a subcollection under a theme`, async () => {
      // 1. Arrange
      const db = dbOf(env);

      // 2. Act
      const read = getDoc(doc(db, "themes/grafite/private/notes"));

      // 3. Assert
      await assertFails(read);
    });
  }
});
