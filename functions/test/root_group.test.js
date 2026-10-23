const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { rootGroupEmailFor } = require("../root_group");

describe("rootGroupEmailFor - Unit Test Suite", () => {
  // -------------------------------------------------------------
  // HAPPY PATH
  // -------------------------------------------------------------
  test("Happy Path: derives <id>00@monamienet.org from monamienet-<id>", () => {
    // 1. Arrange
    const projectId = "monamienet-aquariustur";

    // 2. Act
    const email = rootGroupEmailFor(projectId);

    // 3. Assert
    assert.equal(email, "aquariustur00@monamienet.org");
  });

  test("Happy Path: keeps digits that are part of the partner id", () => {
    // 1. Arrange
    const projectId = "monamienet-tur2";

    // 2. Act
    const email = rootGroupEmailFor(projectId);

    // 3. Assert
    assert.equal(email, "tur200@monamienet.org");
  });

  // -------------------------------------------------------------
  // EDGE CASES
  // -------------------------------------------------------------
  test("Edge Case: a one-letter partner id is accepted", () => {
    // 1. Arrange
    const projectId = "monamienet-x";

    // 2. Act
    const email = rootGroupEmailFor(projectId);

    // 3. Assert
    assert.equal(email, "x00@monamienet.org");
  });

  test("Edge Case: only the first prefix is removed", () => {
    // 1. Arrange
    const projectId = "monamienet-monamienet";

    // 2. Act
    const email = rootGroupEmailFor(projectId);

    // 3. Assert
    assert.equal(email, "monamienet00@monamienet.org");
  });

  // -------------------------------------------------------------
  // SAD PATH
  // -------------------------------------------------------------
  const invalidProjects = [
    ["a project without the prefix", "aquariustur"],
    ["another prefix", "other-aquariustur"],
    ["the prefix in upper case", "MonAmieNet-aquariustur"],
    ["the bare prefix", "monamienet-"],
    ["an id with upper case letters", "monamienet-AquariusTur"],
    ["an id starting with a digit", "monamienet-2tur"],
    ["an id with a hyphen", "monamienet-aquarius-tur"],
  ];
  for (const [label, projectId] of invalidProjects) {
    test(`Sad Path: ${label} ("${projectId}") throws`, () => {
      // 1. Arrange
      const input = projectId;

      // 2. Act
      const action = () => rootGroupEmailFor(input);

      // 3. Assert
      assert.throws(action, Error);
    });
  }

  // Regression: "app" is reserved for the central project monamienet-app.
  test("Sad Path: the central project monamienet-app throws (reserved id)", () => {
    // 1. Arrange
    const projectId = "monamienet-app";

    // 2. Act
    const action = () => rootGroupEmailFor(projectId);

    // 3. Assert
    assert.throws(action, /invalid partner id/);
  });

  const nonStrings = [
    ["undefined", undefined],
    ["null", null],
    ["a number", 42],
  ];
  for (const [label, value] of nonStrings) {
    test(`Sad Path: ${label} throws`, () => {
      // 1. Arrange
      const input = value;

      // 2. Act
      const action = () => rootGroupEmailFor(input);

      // 3. Assert
      assert.throws(action, /does not start with "monamienet-"/);
    });
  }
});
