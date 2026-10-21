const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  partnerIdFromGroupEmail,
  partnerIdsFromGroups,
} = require("../partner_groups");

describe("partnerIdFromGroupEmail - Unit Test Suite", () => {
  const cases = [
    ["Happy Path: a subgroup gives its partner id", "aquariustur01@monamienet.org", "aquariustur"],
    ["Happy Path: the root group gives its partner id", "aquariustur00@monamienet.org", "aquariustur"],
    ["Edge Case: upper case letters are normalized", "AquariusTur01@MonAmieNet.ORG", "aquariustur"],
    ["Edge Case: surrounding whitespace is ignored", "  aquariustur01@monamienet.org\n", "aquariustur"],
    ["Edge Case: only the last two digits are the suffix", "tur201@monamienet.org", "tur2"],
    ["Edge Case: the shortest valid local part", "x01@monamienet.org", "x"],
    ["Sad Path: the reserved id app gives null", "app01@monamienet.org", null],
    ["Sad Path: another domain gives null", "aquariustur01@gmail.com", null],
    ["Sad Path: a subdomain gives null", "aquariustur01@sub.monamienet.org", null],
    ["Sad Path: no two-digit suffix gives null", "aquariustur@monamienet.org", null],
    ["Sad Path: a one-digit suffix gives null", "aquariustur1@monamienet.org", null],
    ["Sad Path: a local part shorter than 3 characters gives null", "01@monamienet.org", null],
    ["Sad Path: an id starting with a digit gives null", "2tur01@monamienet.org", null],
    ["Sad Path: an id with a hyphen gives null", "ti-suporte01@monamienet.org", null],
    ["Sad Path: a text without @ gives null", "aquariustur01", null],
  ];
  for (const [label, email, expected] of cases) {
    test(`${label} (${JSON.stringify(email.trim())})`, () => {
      // 1. Arrange
      const input = email;

      // 2. Act
      const id = partnerIdFromGroupEmail(input);

      // 3. Assert
      assert.equal(id, expected);
    });
  }

  const nonStrings = [
    ["undefined", undefined],
    ["null", null],
    ["a number", 42],
    ["an object", { email: "aquariustur01@monamienet.org" }],
  ];
  for (const [label, value] of nonStrings) {
    test(`Sad Path: ${label} gives null`, () => {
      // 1. Arrange
      const input = value;

      // 2. Act
      const id = partnerIdFromGroupEmail(input);

      // 3. Assert
      assert.equal(id, null);
    });
  }
});

describe("partnerIdsFromGroups - Unit Test Suite", () => {
  test("Happy Path: returns the distinct partner ids, sorted", () => {
    // 1. Arrange
    const groups = [
      { email: "zeta01@monamienet.org" },
      { email: "aquariustur02@monamienet.org" },
      { email: "aquariustur01@monamienet.org" },
      { email: "beta00@monamienet.org" },
    ];

    // 2. Act
    const ids = partnerIdsFromGroups(groups);

    // 3. Assert
    assert.deepEqual(ids, ["aquariustur", "beta", "zeta"]);
  });

  test("Edge Case: the same partner in different cases appears once", () => {
    // 1. Arrange
    const groups = [
      { email: "AquariusTur01@monamienet.org" },
      { email: "aquariustur01@monamienet.org" },
    ];

    // 2. Act
    const ids = partnerIdsFromGroups(groups);

    // 3. Assert
    assert.deepEqual(ids, ["aquariustur"]);
  });

  test("Edge Case: an empty list gives no ids", () => {
    // 1. Arrange
    const groups = [];

    // 2. Act
    const ids = partnerIdsFromGroups(groups);

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
      const ids = partnerIdsFromGroups(groups);

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
      { email: "app01@monamienet.org" },
      { email: "beta01@gmail.com" },
      { email: "acme01@monamienet.org" },
    ];

    // 2. Act
    const ids = partnerIdsFromGroups(groups);

    // 3. Assert
    assert.deepEqual(ids, ["acme"]);
  });
});
