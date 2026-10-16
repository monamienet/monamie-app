const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { normalizeGroupEmail } = require("../group_email");

describe("normalizeGroupEmail - Unit Test Suite", () => {
  // -------------------------------------------------------------
  // HAPPY PATH
  // -------------------------------------------------------------
  test("Happy Path: returns an already canonical email unchanged", () => {
    // 1. Arrange
    const email = "aquariustur01@monamienet.org";

    // 2. Act
    const result = normalizeGroupEmail(email);

    // 3. Assert
    assert.equal(result, "aquariustur01@monamienet.org");
  });

  test("Happy Path: lowercases a display-name-cased group email", () => {
    // 1. Arrange
    const email = "AquariusTur01@MonAmieNet.org";

    // 2. Act
    const result = normalizeGroupEmail(email);

    // 3. Assert
    assert.equal(result, "aquariustur01@monamienet.org");
  });

  test("Happy Path: mixed-case input maps to the same key as its lowercase form", () => {
    // 1. Arrange
    const canonicalKey = normalizeGroupEmail("ti-suporte@monamienet.org");
    const mixedCaseEmail = "TI-Suporte@MonAmieNet.ORG";

    // 2. Act
    const result = normalizeGroupEmail(mixedCaseEmail);

    // 3. Assert
    assert.equal(result, canonicalKey);
  });

  // -------------------------------------------------------------
  // EDGE CASES
  // -------------------------------------------------------------
  test("Edge Case: trims leading and trailing spaces", () => {
    // 1. Arrange
    const email = "   aquariustur01@monamienet.org   ";

    // 2. Act
    const result = normalizeGroupEmail(email);

    // 3. Assert
    assert.equal(result, "aquariustur01@monamienet.org");
  });

  test("Edge Case: trims tabs and newlines and lowercases at the same time", () => {
    // 1. Arrange
    const email = "\t\n AquariusTur01@MonAmieNet.org \r\n";

    // 2. Act
    const result = normalizeGroupEmail(email);

    // 3. Assert
    assert.equal(result, "aquariustur01@monamienet.org");
  });

  test("Edge Case: returns an empty string for an empty input", () => {
    // 1. Arrange
    const email = "";

    // 2. Act
    const result = normalizeGroupEmail(email);

    // 3. Assert
    assert.equal(result, "");
  });

  test("Edge Case: returns an empty string for a whitespace-only input", () => {
    // 1. Arrange
    const email = "   \t  ";

    // 2. Act
    const result = normalizeGroupEmail(email);

    // 3. Assert
    assert.equal(result, "");
  });

  test("Edge Case: preserves inner whitespace (only peripheral whitespace is trimmed)", () => {
    // 1. Arrange
    const email = " Group Name@MonAmieNet.org ";

    // 2. Act
    const result = normalizeGroupEmail(email);

    // 3. Assert
    assert.equal(result, "group name@monamienet.org");
  });

  test("Edge Case: is idempotent when applied to an already normalized value", () => {
    // 1. Arrange
    const alreadyNormalized = normalizeGroupEmail("  AquariusTur01@MonAmieNet.org ");

    // 2. Act
    const result = normalizeGroupEmail(alreadyNormalized);

    // 3. Assert
    assert.equal(result, alreadyNormalized);
  });

  // -------------------------------------------------------------
  // SAD PATH
  // -------------------------------------------------------------
  test("Sad Path: throws TypeError when email is null", () => {
    // 1. Arrange
    const email = null;

    // 2. Act
    const action = () => normalizeGroupEmail(email);

    // 3. Assert
    assert.throws(action, {
      name: "TypeError",
      message: "Group email must be a string.",
    });
  });

  test("Sad Path: throws TypeError when email is undefined", () => {
    // 1. Arrange
    const email = undefined;

    // 2. Act
    const action = () => normalizeGroupEmail(email);

    // 3. Assert
    assert.throws(action, TypeError);
  });

  test("Sad Path: throws TypeError when email is a number", () => {
    // 1. Arrange
    const email = 12345;

    // 2. Act
    const action = () => normalizeGroupEmail(email);

    // 3. Assert
    assert.throws(action, TypeError);
  });

  test("Sad Path: throws TypeError when email is an object", () => {
    // 1. Arrange
    const email = { email: "aquariustur01@monamienet.org" };

    // 2. Act
    const action = () => normalizeGroupEmail(email);

    // 3. Assert
    assert.throws(action, TypeError);
  });

  test("Sad Path: does not validate format and only normalizes a malformed email", () => {
    // 1. Arrange
    const email = " Not-An-Email ";

    // 2. Act
    const result = normalizeGroupEmail(email);

    // 3. Assert
    assert.equal(result, "not-an-email");
  });
});
