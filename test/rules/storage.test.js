// Security rules of a partner project's Storage (storage.rules), against
// the Storage emulator. The only file is partners/{partnerId}/logo.png:
// public to read, written and deleted only by the partner's administrators (the
// `admin` claim that syncClaims sets), as a PNG of at most 1 MiB.
const { after, before, beforeEach, describe, test } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { deleteObject, getBytes, getMetadata, ref, uploadBytes } = require("firebase/storage");

const rulesPath = path.join(__dirname, "..", "..", "storage.rules");

const LOGO = "partners/rotasul/logo.png";
const MiB = 1024 * 1024;
const PNG = { contentType: "image/png" };

/** [size] bytes starting with the PNG signature. */
function pngBytes(size = 64) {
  const bytes = new Uint8Array(size);
  bytes.set([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  return bytes;
}

let env;

/** Storage as a signed-in user with [claims]. */
function storageAs(claims) {
  return env.authenticatedContext("user", { email: "user@monamienet.org", ...claims }).storage();
}

const administrator = () => storageAs({ admin: ["rotasul"] });

/** Puts the logo in place, bypassing the rules. */
async function seedLogo() {
  await env.withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), LOGO), pngBytes(), PNG);
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-storage",
    storage: {
      rules: fs.readFileSync(rulesPath, "utf8"),
      host: "127.0.0.1",
      port: 9199,
    },
  });
});

beforeEach(async () => {
  await env.clearStorage();
});

after(async () => {
  await env.cleanup();
});

describe("storage.rules read - Unit Test Suite", () => {
  test("Happy Path: anyone, even signed out, reads the logo bytes", async () => {
    // 1. Arrange
    await seedLogo();
    const storage = env.unauthenticatedContext().storage();

    // 2. Act
    const read = getBytes(ref(storage, LOGO));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Edge Case: a signed-in non-administrator reads the logo metadata", async () => {
    // 1. Arrange
    await seedLogo();
    const storage = storageAs({ watch: ["rotasul01"] });

    // 2. Act
    const read = getMetadata(ref(storage, LOGO));

    // 3. Assert
    await assertSucceeds(read);
  });

  test("Sad Path: another file of the partner cannot be read", async () => {
    // 1. Arrange
    await env.withSecurityRulesDisabled(async (context) => {
      await uploadBytes(ref(context.storage(), "partners/rotasul/other.png"), pngBytes(), PNG);
    });
    const storage = administrator();

    // 2. Act
    const read = getBytes(ref(storage, "partners/rotasul/other.png"));

    // 3. Assert
    await assertFails(read);
  });
});

describe("storage.rules write - Unit Test Suite", () => {
  test("Happy Path: an administrator uploads a PNG logo", async () => {
    // 1. Arrange
    const storage = administrator();

    // 2. Act
    const write = uploadBytes(ref(storage, LOGO), pngBytes(), PNG);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Happy Path: an administrator overwrites an existing logo", async () => {
    // 1. Arrange
    await seedLogo();
    const storage = administrator();

    // 2. Act
    const write = uploadBytes(ref(storage, LOGO), pngBytes(128), PNG);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: an administrator of several partners uploads this one's logo", async () => {
    // 1. Arrange
    const storage = storageAs({ admin: ["outro", "rotasul"] });

    // 2. Act
    const write = uploadBytes(ref(storage, LOGO), pngBytes(), PNG);

    // 3. Assert
    await assertSucceeds(write);
  });

  test("Edge Case: a PNG of exactly 1 MiB is accepted", async () => {
    // 1. Arrange
    const storage = administrator();

    // 2. Act
    const write = uploadBytes(ref(storage, LOGO), pngBytes(MiB), PNG);

    // 3. Assert
    await assertSucceeds(write);
  });

  const deniedUsers = [
    ["Sad Path: a signed-out user", () => env.unauthenticatedContext().storage()],
    ["Sad Path: an administrator of another partner", () => storageAs({ admin: ["outro"] })],
    [
      "Sad Path: a user who only shares and watches in the partner",
      () => storageAs({ share: ["rotasul01"], watch: ["rotasul02"], partners: ["rotasul"] }),
    ],
    ["Sad Path: a user without claims", () => storageAs({})],
    ["Sad Path: admin as a string instead of a list", () => storageAs({ admin: "rotasul" })],
  ];
  for (const [label, storageOf] of deniedUsers) {
    test(`${label} cannot upload the logo`, async () => {
      // 1. Arrange
      const storage = storageOf();

      // 2. Act
      const write = uploadBytes(ref(storage, LOGO), pngBytes(), PNG);

      // 3. Assert
      await assertFails(write);
    });
  }

  for (const contentType of ["image/svg+xml", "image/jpeg"]) {
    test(`Sad Path: an administrator cannot upload ${contentType} as the logo`, async () => {
      // 1. Arrange
      const storage = administrator();

      // 2. Act
      const write = uploadBytes(ref(storage, LOGO), pngBytes(), { contentType });

      // 3. Assert
      await assertFails(write);
    });
  }

  test("Sad Path: an administrator cannot upload a PNG larger than 1 MiB", async () => {
    // 1. Arrange
    const storage = administrator();

    // 2. Act
    const write = uploadBytes(ref(storage, LOGO), pngBytes(MiB + 1), PNG);

    // 3. Assert
    await assertFails(write);
  });

  for (const other of ["partners/rotasul/other.png", "logo.png", "partners/rotasul/logo.png/x.png"]) {
    test(`Sad Path: an administrator cannot upload to ${other}`, async () => {
      // 1. Arrange
      const storage = administrator();

      // 2. Act
      const write = uploadBytes(ref(storage, other), pngBytes(), PNG);

      // 3. Assert
      await assertFails(write);
    });
  }
});

describe("storage.rules delete - Unit Test Suite", () => {
  test("Happy Path: an administrator deletes the logo", async () => {
    // 1. Arrange
    await seedLogo();
    const storage = administrator();

    // 2. Act
    const remove = deleteObject(ref(storage, LOGO));

    // 3. Assert
    await assertSucceeds(remove);
  });

  test("Edge Case: a signed-out user cannot delete the logo", async () => {
    // 1. Arrange
    await seedLogo();
    const storage = env.unauthenticatedContext().storage();

    // 2. Act
    const remove = deleteObject(ref(storage, LOGO));

    // 3. Assert
    await assertFails(remove);
  });

  test("Sad Path: an administrator of another partner cannot delete the logo", async () => {
    // 1. Arrange
    await seedLogo();
    const storage = storageAs({ admin: ["outro"] });

    // 2. Act
    const remove = deleteObject(ref(storage, LOGO));

    // 3. Assert
    await assertFails(remove);
  });
});
