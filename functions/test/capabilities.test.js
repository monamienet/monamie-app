const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { capabilitiesFromGroups, hasNoAccess } = require("../capabilities");

const hostsEverything = () => true;
const hostsOnlyRotasul = (partnerId) => partnerId === "rotasul";

const none = { share: [], watch: [], owns: [], partners: [], ignored: [] };

describe("capabilitiesFromGroups - Unit Test Suite", () => {
  const single = [
    [
      "Happy Path: a share leaf gives share in its team",
      "rotasul01w@monamienet.org",
      { ...none, share: ["rotasul01"], partners: ["rotasul"] },
    ],
    [
      "Happy Path: a watch leaf gives watch in its team",
      "rotasul01r@monamienet.org",
      { ...none, watch: ["rotasul01"], partners: ["rotasul"] },
    ],
    [
      "Happy Path: the root group makes the person the owner",
      "rotasul00@monamienet.org",
      { ...none, owns: ["rotasul"], partners: ["rotasul"] },
    ],
    [
      "Edge Case: a direct team group grants nothing and is reported",
      "rotasul01@monamienet.org",
      { ...none, ignored: ["rotasul01@monamienet.org"] },
    ],
    [
      "Edge Case: an ignored team group is reported normalized",
      "  RotaSul02@MonAmieNet.org ",
      { ...none, ignored: ["rotasul02@monamienet.org"] },
    ],
  ];
  for (const [label, email, expected] of single) {
    test(`${label} (${JSON.stringify(email.trim())})`, () => {
      // 1. Arrange
      const groups = [{ email }];

      // 2. Act
      const caps = capabilitiesFromGroups(groups, hostsEverything);

      // 3. Assert
      assert.deepEqual(caps, expected);
    });
  }

  test("Happy Path: several groups give sorted lists without duplicates", () => {
    // 1. Arrange
    const groups = [
      { email: "rotasul02w@monamienet.org" },
      { email: "rotasul01w@monamienet.org" },
      { email: "RotaSul01W@monamienet.org" },
      { email: "rotasul03r@monamienet.org" },
      { email: "rotasul01r@monamienet.org" },
      { email: "rotasul00@monamienet.org" },
      { email: "rotasul00@monamienet.org" },
      { email: "rotasul05@monamienet.org" },
      { email: "rotasul04@monamienet.org" },
    ];

    // 2. Act
    const caps = capabilitiesFromGroups(groups, hostsEverything);

    // 3. Assert
    assert.deepEqual(caps, {
      share: ["rotasul01", "rotasul02"],
      watch: ["rotasul01", "rotasul03"],
      owns: ["rotasul"],
      partners: ["rotasul"],
      ignored: ["rotasul04@monamienet.org", "rotasul05@monamienet.org"],
    });
  });

  test("Edge Case: groups of partners not hosted here are left out entirely", () => {
    // 1. Arrange
    const groups = [
      { email: "rotasul01w@monamienet.org" },
      { email: "outro01w@monamienet.org" },
      { email: "outro01r@monamienet.org" },
      { email: "outro00@monamienet.org" },
      { email: "outro01@monamienet.org" },
    ];

    // 2. Act
    const caps = capabilitiesFromGroups(groups, hostsOnlyRotasul);

    // 3. Assert
    assert.deepEqual(caps, { ...none, share: ["rotasul01"], partners: ["rotasul"] });
  });

  for (const [label, value] of [
    ["an empty list", []],
    ["null", null],
    ["undefined", undefined],
  ]) {
    test(`Edge Case: ${label} gives no capabilities`, () => {
      // 1. Arrange
      const groups = value;

      // 2. Act
      const caps = capabilitiesFromGroups(groups, hostsEverything);

      // 3. Assert
      assert.deepEqual(caps, none);
    });
  }

  test("Sad Path: malformed entries are skipped", () => {
    // 1. Arrange
    const groups = [
      null,
      {},
      { email: 42 },
      { email: "rotasul01w@gmail.com" },
      { email: "rotasul00w@monamienet.org" },
      { email: "tur201w@monamienet.org" },
      { email: "ti-suporte@monamienet.org" },
      { email: "rotasul01r@monamienet.org" },
    ];

    // 2. Act
    const caps = capabilitiesFromGroups(groups, hostsEverything);

    // 3. Assert
    assert.deepEqual(caps, { ...none, watch: ["rotasul01"], partners: ["rotasul"] });
  });
});

describe("capabilitiesFromGroups partners - Unit Test Suite", () => {
  test("Happy Path: partners lists every hosted partner with a capability, sorted", () => {
    // 1. Arrange
    const groups = [
      { email: "zeta01r@monamienet.org" },
      { email: "rotasul01w@monamienet.org" },
      { email: "alfa00@monamienet.org" },
      { email: "rotasul02r@monamienet.org" },
    ];

    // 2. Act
    const caps = capabilitiesFromGroups(groups, hostsEverything);

    // 3. Assert
    assert.deepEqual(caps.partners, ["alfa", "rotasul", "zeta"]);
  });

  test("Edge Case: a direct team group of another partner does not add that partner", () => {
    // 1. Arrange
    const groups = [{ email: "rotasul01w@monamienet.org" }, { email: "outro01@monamienet.org" }];

    // 2. Act
    const caps = capabilitiesFromGroups(groups, hostsEverything);

    // 3. Assert
    assert.deepEqual(caps.partners, ["rotasul"]);
  });

  test("Sad Path: a partner not hosted here is not listed", () => {
    // 1. Arrange
    const groups = [{ email: "outro00@monamienet.org" }, { email: "outro01w@monamienet.org" }];

    // 2. Act
    const caps = capabilitiesFromGroups(groups, hostsOnlyRotasul);

    // 3. Assert
    assert.deepEqual(caps.partners, []);
  });
});

describe("hasNoAccess - Unit Test Suite", () => {
  const cases = [
    ["Happy Path: no capability means no access", { share: [], watch: [], owns: [] }, true],
    ["Edge Case: share alone is access", { share: ["rotasul01"], watch: [], owns: [] }, false],
    ["Edge Case: watch alone is access", { share: [], watch: ["rotasul01"], owns: [] }, false],
    ["Edge Case: owns alone is access", { share: [], watch: [], owns: ["rotasul"] }, false],
    [
      "Sad Path: ignored groups alone are no access",
      { share: [], watch: [], owns: [], ignored: ["rotasul01@monamienet.org"] },
      true,
    ],
  ];
  for (const [label, caps, expected] of cases) {
    test(label, () => {
      // 1. Arrange
      const input = caps;

      // 2. Act
      const noAccess = hasNoAccess(input);

      // 3. Assert
      assert.equal(noAccess, expected);
    });
  }
});
