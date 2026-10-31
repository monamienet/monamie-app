const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  organizationIdFromGroupEmail,
  organizationIdsFromGroups,
} = require("../organization_groups");

describe("organizationIdFromGroupEmail - Unit Test Suite", () => {
  const cases = [
    ["Happy Path: the root group gives its organization id", "rotasul00@monamienet.org", "rotasul"],
    ["Happy Path: a share leaf gives its organization id", "rotasul01w@monamienet.org", "rotasul"],
    ["Happy Path: a watch leaf gives its organization id", "rotasul01r@monamienet.org", "rotasul"],
    ["Edge Case: upper case letters are normalized", "RotaSul02W@MonAmieNet.ORG", "rotasul"],
    ["Edge Case: surrounding whitespace is ignored", "  rotasul01r@monamienet.org\n", "rotasul"],
    ["Edge Case: the last team number 99 counts", "rotasul99w@monamienet.org", "rotasul"],
    ["Edge Case: a team group also points to its organization", "rotasul01@monamienet.org", "rotasul"],
    ["Sad Path: a leaf of the root group gives null", "rotasul00w@monamienet.org", null],
    ["Sad Path: digits in the organization id give null", "tur201w@monamienet.org", null],
    ["Sad Path: an organization id shorter than 3 letters gives null", "ab00@monamienet.org", null],
    ["Sad Path: the reserved id app gives null", "app01w@monamienet.org", null],
    ["Sad Path: the reserved id community gives null", "community00@monamienet.org", null],
    ["Sad Path: another domain gives null", "rotasul01w@gmail.com", null],
    ["Sad Path: a subdomain gives null", "rotasul01w@sub.monamienet.org", null],
    ["Sad Path: no team number gives null", "rotasul@monamienet.org", null],
    ["Sad Path: a one-digit team number gives null", "rotasul1w@monamienet.org", null],
    ["Sad Path: an id with a hyphen gives null", "ti-suporte01w@monamienet.org", null],
    ["Sad Path: a text without @ gives null", "rotasul01w", null],
  ];
  for (const [label, email, expected] of cases) {
    test(`${label} (${JSON.stringify(email.trim())})`, () => {
      // 1. Arrange
      const input = email;

      // 2. Act
      const id = organizationIdFromGroupEmail(input);

      // 3. Assert
      assert.equal(id, expected);
    });
  }

  const nonStrings = [
    ["undefined", undefined],
    ["null", null],
    ["a number", 42],
    ["an object", { email: "rotasul01w@monamienet.org" }],
  ];
  for (const [label, value] of nonStrings) {
    test(`Sad Path: ${label} gives null`, () => {
      // 1. Arrange
      const input = value;

      // 2. Act
      const id = organizationIdFromGroupEmail(input);

      // 3. Assert
      assert.equal(id, null);
    });
  }
});

describe("organizationIdsFromGroups - Unit Test Suite", () => {
  test("Happy Path: returns the distinct organization ids, sorted", () => {
    // 1. Arrange
    const groups = [
      { email: "zeta01w@monamienet.org" },
      { email: "rotasul02r@monamienet.org" },
      { email: "rotasul01w@monamienet.org" },
      { email: "beta00@monamienet.org" },
    ];

    // 2. Act
    const ids = organizationIdsFromGroups(groups);

    // 3. Assert
    assert.deepEqual(ids, ["beta", "rotasul", "zeta"]);
  });

  test("Edge Case: the same organization in different cases appears once", () => {
    // 1. Arrange
    const groups = [
      { email: "RotaSul01W@monamienet.org" },
      { email: "rotasul01w@monamienet.org" },
    ];

    // 2. Act
    const ids = organizationIdsFromGroups(groups);

    // 3. Assert
    assert.deepEqual(ids, ["rotasul"]);
  });

  // An organization made before the three-level model (people directly in
  // <id>NN) must stay reachable until it is migrated.
  test("Edge Case: an organization reached only through a team group is kept", () => {
    // 1. Arrange
    const groups = [
      { email: "acme01@monamienet.org" },
      { email: "rotasul01w@monamienet.org" },
    ];

    // 2. Act
    const ids = organizationIdsFromGroups(groups);

    // 3. Assert
    assert.deepEqual(ids, ["acme", "rotasul"]);
  });

  test("Edge Case: an empty list gives no ids", () => {
    // 1. Arrange
    const groups = [];

    // 2. Act
    const ids = organizationIdsFromGroups(groups);

    // 3. Assert
    assert.deepEqual(ids, []);
  });

  for (const [label, value] of [
    ["null", null],
    ["undefined", undefined],
  ]) {
    test(`Edge Case: ${label} groups give no ids`, () => {
      // 1. Arrange
      const groups = value;

      // 2. Act
      const ids = organizationIdsFromGroups(groups);

      // 3. Assert
      assert.deepEqual(ids, []);
    });
  }

  test("Sad Path: groups that do not follow the convention are skipped", () => {
    // 1. Arrange
    const groups = [
      null,
      {},
      { email: 42 },
      { email: "ti-suporte@monamienet.org" },
      { email: "app01w@monamienet.org" },
      { email: "beta01w@gmail.com" },
      { email: "tur201w@monamienet.org" },
      { email: "acme01r@monamienet.org" },
    ];

    // 2. Act
    const ids = organizationIdsFromGroups(groups);

    // 3. Assert
    assert.deepEqual(ids, ["acme"]);
  });
});
