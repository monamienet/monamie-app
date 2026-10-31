const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { organizationIdForProject, rootGroupEmailFor } = require("../root_group");

/** Project ids that do not follow `monamienet-<valid id>`. */
const invalidProjects = [
  ["a project without the prefix", "aquariustur"],
  ["another prefix", "other-aquariustur"],
  ["the prefix in upper case", "MonAmieNet-aquariustur"],
  ["the bare prefix", "monamienet-"],
  ["an id with upper case letters", "monamienet-AquariusTur"],
  ["an id with digits", "monamienet-tur2"],
  ["an id starting with a digit", "monamienet-2tur"],
  ["an id with a hyphen", "monamienet-aquarius-tur"],
  ["an id shorter than 3 letters", "monamienet-ab"],
  ["the reserved id community", "monamienet-community"],
];

describe("organizationIdForProject - Unit Test Suite", () => {
  test("Happy Path: monamienet-<id> gives <id>", () => {
    // 1. Arrange
    const projectId = "monamienet-rotasul";

    // 2. Act
    const id = organizationIdForProject(projectId);

    // 3. Assert
    assert.equal(id, "rotasul");
  });

  test("Edge Case: a three-letter organization id is accepted", () => {
    // 1. Arrange
    const projectId = "monamienet-abc";

    // 2. Act
    const id = organizationIdForProject(projectId);

    // 3. Assert
    assert.equal(id, "abc");
  });

  for (const [label, projectId] of invalidProjects) {
    test(`Sad Path: ${label} ("${projectId}") throws`, () => {
      // 1. Arrange
      const input = projectId;

      // 2. Act
      const action = () => organizationIdForProject(input);

      // 3. Assert
      assert.throws(action, Error);
    });
  }
});

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

  // -------------------------------------------------------------
  // EDGE CASES
  // -------------------------------------------------------------
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
  // Organization ids are letters only now: digits would make the team number
  // ambiguous in a group address.
  test("Sad Path: digits in the organization id throw", () => {
    // 1. Arrange
    const projectId = "monamienet-tur2";

    // 2. Act
    const action = () => rootGroupEmailFor(projectId);

    // 3. Assert
    assert.throws(action, /invalid organization id/);
  });

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
    assert.throws(action, /invalid organization id/);
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
