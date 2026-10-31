const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  TeamError,
  nextTeamNumber,
  normalizeTeamName,
  roleChanges,
  teamGroupEmails,
  validateRoles,
  validateTeamName,
  whoLosesAccess,
} = require("../teams");

/** Runs `act` and returns the TeamError it throws (fails if none). */
function teamErrorOf(act) {
  try {
    act();
  } catch (error) {
    assert.ok(error instanceof TeamError, `expected TeamError, got ${error}`);
    return error;
  }
  assert.fail("expected a TeamError");
}

/** The 99 team numbers "01" to "99". */
const ALL_NUMBERS = Array.from({ length: 99 }, (_, i) => String(i + 1).padStart(2, "0"));

describe("normalizeTeamName - Unit Test Suite", () => {
  const cases = [
    ["Happy Path: accents, case and spaces are normalized", "  Equipe   Léste ", "equipe leste"],
    ["Happy Path: a plain lower case name stays the same", "equipe norte", "equipe norte"],
    ["Edge Case: cedilla and tilde are stripped", "Ação Conceição", "acao conceicao"],
    ["Edge Case: tabs and new lines collapse to one space", "Equipe\t\nSul", "equipe sul"],
    ["Edge Case: an empty name stays empty", "   ", ""],
  ];
  for (const [label, input, expected] of cases) {
    test(`${label} (${JSON.stringify(input)})`, () => {
      // 1. Arrange
      const name = input;

      // 2. Act
      const normalized = normalizeTeamName(name);

      // 3. Assert
      assert.equal(normalized, expected);
    });
  }
});

describe("validateTeamName - Unit Test Suite", () => {
  const valid = [
    ["Happy Path: a plain name is kept", "Equipe Serra", "Equipe Serra"],
    ["Edge Case: the name is trimmed and inner spaces collapse", "  Equipe   Serra  ", "Equipe Serra"],
    ["Edge Case: two accented letters are enough", "Zé", "Zé"],
    ["Edge Case: exactly 40 characters are allowed", "a".repeat(40), "a".repeat(40)],
    ["Edge Case: 40 characters after collapsing spaces are allowed", `  ${"a".repeat(20)}     ${"b".repeat(19)}  `, `${"a".repeat(20)} ${"b".repeat(19)}`],
  ];
  for (const [label, input, expected] of valid) {
    test(`${label} (${JSON.stringify(input)})`, () => {
      // 1. Arrange
      const existing = ["Equipe Norte"];

      // 2. Act
      const stored = validateTeamName(input, existing);

      // 3. Assert
      assert.equal(stored, expected);
    });
  }

  const invalidNames = [
    ["Sad Path: a number is not a name", 42],
    ["Sad Path: null is not a name", null],
    ["Sad Path: undefined is not a name", undefined],
    ["Sad Path: one letter and a digit are too few letters", "A1"],
    ["Sad Path: digits only have no letters", "1 2"],
    ["Sad Path: blank text has no letters", "    "],
    ["Sad Path: 41 characters are too many", "a".repeat(41)],
  ];
  for (const [label, input] of invalidNames) {
    test(`${label} (${JSON.stringify(input)})`, () => {
      // 1. Arrange
      const existing = [];

      // 2. Act
      const error = teamErrorOf(() => validateTeamName(input, existing));

      // 3. Assert
      assert.equal(error.code, "name");
    });
  }

  const duplicates = [
    ["Sad Path: same name in another case is a duplicate", "equipe leste"],
    ["Sad Path: same name without the accent is a duplicate", "EQUIPE LESTE"],
    ["Sad Path: same name with extra spaces is a duplicate", "  equipe    léste "],
  ];
  for (const [label, input] of duplicates) {
    test(`${label} (${JSON.stringify(input)})`, () => {
      // 1. Arrange
      const existing = ["Equipe Norte", "Equipe Léste"];

      // 2. Act
      const error = teamErrorOf(() => validateTeamName(input, existing));

      // 3. Assert
      assert.equal(error.code, "duplicate");
      assert.match(error.message, /Equipe Léste/);
    });
  }
});

describe("nextTeamNumber - Unit Test Suite", () => {
  const cases = [
    ["Happy Path: no teams gives 01", [], "01"],
    ["Happy Path: a gap is filled first", ["01", "03"], "02"],
    ["Edge Case: unordered numbers still give the lowest free", ["02", "01", "04"], "03"],
    ["Edge Case: only 99 free gives 99", ALL_NUMBERS.slice(0, 98), "99"],
  ];
  for (const [label, used, expected] of cases) {
    test(label, () => {
      // 1. Arrange
      const taken = used;

      // 2. Act
      const next = nextTeamNumber(taken);

      // 3. Assert
      assert.equal(next, expected);
    });
  }

  test("Sad Path: all 99 numbers taken throws full", () => {
    // 1. Arrange
    const taken = ALL_NUMBERS;

    // 2. Act
    const error = teamErrorOf(() => nextTeamNumber(taken));

    // 3. Assert
    assert.equal(error.code, "full");
  });
});

describe("teamGroupEmails - Unit Test Suite", () => {
  test("Happy Path: team 07 gives the team, watch and share groups", () => {
    // 1. Arrange
    const organizationId = "rotasul";

    // 2. Act
    const emails = teamGroupEmails(organizationId, "07");

    // 3. Assert
    assert.deepEqual(emails, {
      team: "rotasul07@monamienet.org",
      watch: "rotasul07r@monamienet.org",
      share: "rotasul07w@monamienet.org",
    });
  });

  test("Edge Case: team 99 gives the last groups", () => {
    // 1. Arrange
    const organizationId = "rotasul";

    // 2. Act
    const emails = teamGroupEmails(organizationId, "99");

    // 3. Assert
    assert.deepEqual(emails, {
      team: "rotasul99@monamienet.org",
      watch: "rotasul99r@monamienet.org",
      share: "rotasul99w@monamienet.org",
    });
  });
});

describe("validateRoles - Unit Test Suite", () => {
  const valid = [
    ["Happy Path: both roles come back sorted", ["watch", "share"], ["share", "watch"]],
    ["Happy Path: one role is enough", ["watch"], ["watch"]],
    ["Edge Case: repeated roles are deduplicated", ["share", "share"], ["share"]],
  ];
  for (const [label, input, expected] of valid) {
    test(label, () => {
      // 1. Arrange
      const roles = input;

      // 2. Act
      const validated = validateRoles(roles);

      // 3. Assert
      assert.deepEqual(validated, expected);
    });
  }

  const invalid = [
    ["Sad Path: a string is not a list of roles", "share"],
    ["Sad Path: null is not a list of roles", null],
    ["Sad Path: an empty list has no role", []],
    ["Sad Path: an unknown role is refused", ["share", "admin"]],
  ];
  for (const [label, input] of invalid) {
    test(label, () => {
      // 1. Arrange
      const roles = input;

      // 2. Act
      const error = teamErrorOf(() => validateRoles(roles));

      // 3. Assert
      assert.equal(error.code, "roles");
    });
  }
});

describe("roleChanges - Unit Test Suite", () => {
  const cases = [
    ["Happy Path: adding watch to a share-only person", ["share"], ["share", "watch"], { add: ["watch"], remove: [] }],
    ["Happy Path: dropping share from a person with both", ["share", "watch"], ["watch"], { add: [], remove: ["share"] }],
    ["Edge Case: a person with no roles gets both, sorted", [], ["watch", "share"], { add: ["share", "watch"], remove: [] }],
    ["Edge Case: the same roles change nothing", ["watch"], ["watch"], { add: [], remove: [] }],
    ["Edge Case: swapping roles adds one and removes the other", ["watch"], ["share"], { add: ["share"], remove: ["watch"] }],
  ];
  for (const [label, current, wanted, expected] of cases) {
    test(label, () => {
      // 1. Arrange
      const now = current;

      // 2. Act
      const changes = roleChanges(now, wanted);

      // 3. Assert
      assert.deepEqual(changes, expected);
    });
  }
});

describe("whoLosesAccess - Unit Test Suite", () => {
  test("Happy Path: people only in the team lose access, the rest stay", () => {
    // 1. Arrange
    const groupsByPerson = new Map([
      ["zeca@x.com", ["rotasul01w@monamienet.org"]],
      ["ana@x.com", ["rotasul01r@monamienet.org", "rotasul01w@monamienet.org"]],
      ["bia@x.com", ["rotasul01w@monamienet.org", "rotasul02r@monamienet.org"]],
      ["dono@x.com", ["rotasul00@monamienet.org", "rotasul01r@monamienet.org"]],
      ["caio@x.com", ["rotasul02w@monamienet.org"]],
    ]);

    // 2. Act
    const impact = whoLosesAccess("rotasul01", groupsByPerson);

    // 3. Assert
    assert.deepEqual(impact, {
      loses: ["ana@x.com", "zeca@x.com"],
      stays: ["bia@x.com", "dono@x.com"],
    });
  });

  test("Edge Case: a team nobody is in affects nobody", () => {
    // 1. Arrange
    const groupsByPerson = new Map([["caio@x.com", ["rotasul02w@monamienet.org"]]]);

    // 2. Act
    const impact = whoLosesAccess("rotasul01", groupsByPerson);

    // 3. Assert
    assert.deepEqual(impact, { loses: [], stays: [] });
  });

  test("Edge Case: being in the team group itself (not a leaf) does not count as another team", () => {
    // 1. Arrange
    const groupsByPerson = new Map([
      ["ana@x.com", ["rotasul01w@monamienet.org", "rotasul01@monamienet.org"]],
    ]);

    // 2. Act
    const impact = whoLosesAccess("rotasul01", groupsByPerson);

    // 3. Assert
    assert.deepEqual(impact, { loses: ["ana@x.com"], stays: [] });
  });

  test("Sad Path: addresses that are not MonAmie groups are ignored", () => {
    // 1. Arrange
    const groupsByPerson = new Map([
      ["ana@x.com", ["rotasul01r@monamienet.org", "rotasul02w@gmail.com", "nonsense"]],
    ]);

    // 2. Act
    const impact = whoLosesAccess("rotasul01", groupsByPerson);

    // 3. Assert
    assert.deepEqual(impact, { loses: ["ana@x.com"], stays: [] });
  });
});
