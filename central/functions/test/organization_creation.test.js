const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  CreationError,
  organizationIdFormatProblem,
  suggestOrganizationId,
  validateCreation,
} = require("../organization_creation");

const ACTIVE_THEMES = new Set(["grafite", "oceano"]);

/** A valid Community creation request for Rota Sul. */
function request(overrides = {}) {
  return { id: "rotasul", name: "Rota Sul", themeId: "oceano", plan: "community", ...overrides };
}

/** Runs `act` and returns the CreationError it throws. */
function creationErrorOf(act) {
  try {
    act();
  } catch (error) {
    assert.ok(error instanceof CreationError, `expected CreationError, got ${error}`);
    return error;
  }
  assert.fail("expected a CreationError");
}

describe("suggestOrganizationId - Unit Test Suite", () => {
  test("Happy Path: keeps the letters of the name, lower case", () => {
    // 1. Arrange
    const name = "Rota Sul Turismo";

    // 2. Act
    const id = suggestOrganizationId(name);

    // 3. Assert
    assert.equal(id, "rotasulturismo");
  });

  test("Edge Case: removes accents and drops digits", () => {
    // 1. Arrange
    const name = "São João 2";

    // 2. Act
    const id = suggestOrganizationId(name);

    // 3. Assert
    assert.equal(id, "saojoao");
  });

  test("Edge Case: 25 letters keep only the first 20", () => {
    // 1. Arrange
    const name = "abcdefghij klmnopqrst uvwxy";

    // 2. Act
    const id = suggestOrganizationId(name);

    // 3. Assert
    assert.equal(id, "abcdefghijklmnopqrst");
  });

  test("Sad Path: a name with no letters suggests an empty id", () => {
    // 1. Arrange
    const name = "123 - !!";

    // 2. Act
    const id = suggestOrganizationId(name);

    // 3. Assert
    assert.equal(id, "");
  });
});

describe("organizationIdFormatProblem - Unit Test Suite", () => {
  const valid = [
    ["Happy Path", "rotasul"],
    ["Edge Case", "abc"],
    ["Edge Case", "abcdefghijklmnopqrst"],
  ];
  for (const [label, id] of valid) {
    test(`${label}: '${id}' has no format problem`, () => {
      // 1. Arrange
      const candidate = id;

      // 2. Act
      const problem = organizationIdFormatProblem(candidate);

      // 3. Assert
      assert.equal(problem, null);
    });
  }

  const invalid = [
    ["not a string", 42],
    ["undefined", undefined],
    ["a digit", "rotasul1"],
    ["upper case", "RotaSul"],
    ["an accent", "rotaçul"],
    ["a space", "rota sul"],
    ["a hyphen", "rota-sul"],
    ["empty", ""],
    ["two letters", "ab"],
    ["21 letters", "abcdefghijklmnopqrstu"],
    ["reserved 'app'", "app"],
    ["reserved 'community'", "community"],
  ];
  for (const [why, id] of invalid) {
    test(`Sad Path: ${why} has a problem`, () => {
      // 1. Arrange
      const candidate = id;

      // 2. Act
      const problem = organizationIdFormatProblem(candidate);

      // 3. Assert
      assert.equal(typeof problem, "string");
      assert.ok(problem.length > 0);
    });
  }
});

describe("validateCreation - Unit Test Suite", () => {
  test("Happy Path: a valid request comes back as given", () => {
    // 1. Arrange
    const input = request();

    // 2. Act
    const result = validateCreation(input, ACTIVE_THEMES);

    // 3. Assert
    assert.deepEqual(result, { id: "rotasul", name: "Rota Sul", themeId: "oceano", plan: "community" });
  });

  test("Happy Path: the standard plan is accepted", () => {
    // 1. Arrange
    const input = request({ plan: "standard" });

    // 2. Act
    const result = validateCreation(input, ACTIVE_THEMES);

    // 3. Assert
    assert.equal(result.plan, "standard");
  });

  test("Edge Case: the name is trimmed and its spaces collapsed", () => {
    // 1. Arrange
    const input = request({ name: "  Rota    Sul \t Turismo  " });

    // 2. Act
    const result = validateCreation(input, ACTIVE_THEMES);

    // 3. Assert
    assert.equal(result.name, "Rota Sul Turismo");
  });

  test("Edge Case: 40 characters after cleaning is accepted", () => {
    // 1. Arrange
    const input = request({ name: `  ${"a".repeat(40)}  ` });

    // 2. Act
    const result = validateCreation(input, ACTIVE_THEMES);

    // 3. Assert
    assert.equal(result.name, "a".repeat(40));
  });

  test("Edge Case: 2 characters is accepted", () => {
    // 1. Arrange
    const input = request({ name: "Ri" });

    // 2. Act
    const result = validateCreation(input, ACTIVE_THEMES);

    // 3. Assert
    assert.equal(result.name, "Ri");
  });

  test("Edge Case: 'MonAmieSul' (no space) is accepted", () => {
    // 1. Arrange
    const input = request({ name: "MonAmieSul" });

    // 2. Act
    const result = validateCreation(input, ACTIVE_THEMES);

    // 3. Assert
    assert.equal(result.name, "MonAmieSul");
  });

  const rejected = [
    ["a bad id", { id: "Rota Sul" }, "id"],
    ["a reserved id", { id: "community" }, "id"],
    ["a 1-character name", { name: "R" }, "name"],
    ["a name of spaces around 1 character", { name: "   R   " }, "name"],
    ["a 41-character name", { name: "a".repeat(41) }, "name"],
    ["a missing name", { name: undefined }, "name"],
    ["a name starting with 'MonAmie '", { name: "MonAmie Sul" }, "name"],
    ["a name starting with 'monamie ' (lower case)", { name: "monamie sul" }, "name"],
    ["a name starting with 'MONAMIE ' (upper case)", { name: "MONAMIE SUL" }, "name"],
    ["an inactive theme", { themeId: "lava" }, "themeId"],
    ["a missing theme", { themeId: undefined }, "themeId"],
    ["an unknown plan", { plan: "premium" }, "plan"],
    ["a missing plan", { plan: undefined }, "plan"],
  ];
  for (const [why, overrides, code] of rejected) {
    test(`Sad Path: ${why} throws CreationError '${code}'`, () => {
      // 1. Arrange
      const input = request(overrides);

      // 2. Act
      const error = creationErrorOf(() => validateCreation(input, ACTIVE_THEMES));

      // 3. Assert
      assert.equal(error.code, code);
    });
  }
});
