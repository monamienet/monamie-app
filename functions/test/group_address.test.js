const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { isValidPartnerId, parseGroupAddress } = require("../group_address");

describe("isValidPartnerId - Unit Test Suite", () => {
  const cases = [
    ["Happy Path: lowercase letters are valid", "rotasul", true],
    ["Edge Case: three letters (the minimum) are valid", "abc", true],
    ["Edge Case: an id that contains a reserved word is valid", "apps", true],
    ["Sad Path: two letters are too short", "ab", false],
    ["Sad Path: a digit makes the id invalid", "tur2", false],
    ["Sad Path: upper case letters are invalid", "RotaSul", false],
    ["Sad Path: a hyphen is invalid", "rota-sul", false],
    ["Sad Path: the reserved id app is invalid", "app", false],
    ["Sad Path: the reserved id community is invalid", "community", false],
    ["Sad Path: an empty text is invalid", "", false],
    ["Sad Path: a non-string is invalid", 42, false],
    ["Sad Path: null is invalid", null, false],
  ];
  for (const [label, id, expected] of cases) {
    test(`${label} (${JSON.stringify(id)})`, () => {
      // 1. Arrange
      const input = id;

      // 2. Act
      const valid = isValidPartnerId(input);

      // 3. Assert
      assert.equal(valid, expected);
    });
  }
});

describe("parseGroupAddress - Unit Test Suite", () => {
  const parsed = [
    [
      "Happy Path: the root group is level 0",
      "rotasul00@monamienet.org",
      { partnerId: "rotasul", team: "00", teamKey: "rotasul00", leaf: null, level: 0 },
    ],
    [
      "Happy Path: a team group is level 1",
      "rotasul01@monamienet.org",
      { partnerId: "rotasul", team: "01", teamKey: "rotasul01", leaf: null, level: 1 },
    ],
    [
      "Happy Path: a watch leaf is level 2 with leaf r",
      "rotasul01r@monamienet.org",
      { partnerId: "rotasul", team: "01", teamKey: "rotasul01", leaf: "r", level: 2 },
    ],
    [
      "Happy Path: a share leaf is level 2 with leaf w",
      "rotasul01w@monamienet.org",
      { partnerId: "rotasul", team: "01", teamKey: "rotasul01", leaf: "w", level: 2 },
    ],
    [
      "Edge Case: the last team number 99 is a team",
      "rotasul99@monamienet.org",
      { partnerId: "rotasul", team: "99", teamKey: "rotasul99", leaf: null, level: 1 },
    ],
    [
      "Edge Case: upper case letters are normalized",
      "RotaSul02W@MonAmieNet.ORG",
      { partnerId: "rotasul", team: "02", teamKey: "rotasul02", leaf: "w", level: 2 },
    ],
    [
      "Edge Case: surrounding whitespace is ignored",
      "  rotasul03r@monamienet.org\n",
      { partnerId: "rotasul", team: "03", teamKey: "rotasul03", leaf: "r", level: 2 },
    ],
    [
      "Edge Case: a three-letter partner id is accepted",
      "abc01@monamienet.org",
      { partnerId: "abc", team: "01", teamKey: "abc01", leaf: null, level: 1 },
    ],
  ];
  for (const [label, email, expected] of parsed) {
    test(`${label} (${JSON.stringify(email.trim())})`, () => {
      // 1. Arrange
      const input = email;

      // 2. Act
      const address = parseGroupAddress(input);

      // 3. Assert
      assert.deepEqual(address, expected);
    });
  }

  const invalid = [
    ["a watch leaf of the root group", "rotasul00r@monamienet.org"],
    ["a share leaf of the root group", "rotasul00w@monamienet.org"],
    ["an unknown leaf letter", "rotasul01x@monamienet.org"],
    ["a partner id with digits", "tur201@monamienet.org"],
    ["a partner id shorter than 3 letters", "ab01@monamienet.org"],
    ["the reserved id app", "app01w@monamienet.org"],
    ["the reserved id community", "community00@monamienet.org"],
    ["no team number", "rotasul@monamienet.org"],
    ["a one-digit team number", "rotasul1@monamienet.org"],
    ["a three-digit team number", "rotasul001@monamienet.org"],
    ["another domain", "rotasul01w@gmail.com"],
    ["a subdomain", "rotasul01w@sub.monamienet.org"],
    ["a hyphen in the partner id", "rota-sul01@monamienet.org"],
    ["a text without @", "rotasul01w"],
    ["an empty text", ""],
  ];
  for (const [label, email] of invalid) {
    test(`Sad Path: ${label} gives null (${JSON.stringify(email)})`, () => {
      // 1. Arrange
      const input = email;

      // 2. Act
      const address = parseGroupAddress(input);

      // 3. Assert
      assert.equal(address, null);
    });
  }

  for (const [label, value] of [
    ["undefined", undefined],
    ["null", null],
    ["a number", 42],
    ["an object", { email: "rotasul01w@monamienet.org" }],
  ]) {
    test(`Sad Path: ${label} gives null`, () => {
      // 1. Arrange
      const input = value;

      // 2. Act
      const address = parseGroupAddress(input);

      // 3. Assert
      assert.equal(address, null);
    });
  }
});
