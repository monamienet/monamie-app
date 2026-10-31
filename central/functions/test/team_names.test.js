const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { teamNames, visibleTeams } = require("../team_names");

/**
 * An in-memory read-only `GroupsApi`: groups by e-mail, each with a
 * resource name `groups/<e-mail>`, a display name and direct members.
 * Every call is appended to `calls` as `[method, arg]`.
 */
function fakeGroupsApi(groups = {}) {
  const calls = [];
  const byName = (name) =>
    Object.entries(groups).find(([email]) => `groups/${email}` === name)?.[1];
  return {
    calls,
    async lookup(email) {
      calls.push(["lookup", email]);
      return email in groups ? `groups/${email}` : null;
    },
    async get(name) {
      calls.push(["get", name]);
      return { displayName: byName(name).displayName };
    },
    async members(name) {
      calls.push(["members", name]);
      return (byName(name).members ?? []).map((m) => ({ ...m }));
    },
  };
}

const group = (email) => ({ email });
const subgroup = (email) => ({ email, type: "GROUP" });

/** The rotasul tree: root with three teams, each team with its name. */
function rotasulTree() {
  return {
    "rotasul00@monamienet.org": {
      displayName: "Rota Sul",
      members: [
        subgroup("rotasul01@monamienet.org"),
        subgroup("rotasul02@monamienet.org"),
        subgroup("rotasul03@monamienet.org"),
        { email: "chefe@rotasul.com.br", type: "USER" },
      ],
    },
    "rotasul01@monamienet.org": { displayName: "Centro" },
    "rotasul02@monamienet.org": { displayName: "Zona Norte" },
    "rotasul03@monamienet.org": { displayName: "Zona Sul" },
  };
}

describe("visibleTeams - Unit Test Suite", () => {
  test("Happy Path: leaves give their sorted, distinct team keys", () => {
    // 1. Arrange
    const groups = [
      group("rotasul02w@monamienet.org"),
      group("rotasul01r@monamienet.org"),
      group("rotasul01w@monamienet.org"),
    ];

    // 2. Act
    const visible = visibleTeams("rotasul", groups);

    // 3. Assert
    assert.deepEqual(visible, { all: false, keys: ["rotasul01", "rotasul02"] });
  });

  test("Happy Path: a root-group member sees every team", () => {
    // 1. Arrange
    const groups = [group("rotasul00@monamienet.org")];

    // 2. Act
    const visible = visibleTeams("rotasul", groups);

    // 3. Assert
    assert.deepEqual(visible, { all: true, keys: [] });
  });

  test("Edge Case: a root-group member who is also in a leaf keeps both", () => {
    // 1. Arrange
    const groups = [
      group("rotasul03w@monamienet.org"),
      group("rotasul00@monamienet.org"),
    ];

    // 2. Act
    const visible = visibleTeams("rotasul", groups);

    // 3. Assert
    assert.deepEqual(visible, { all: true, keys: ["rotasul03"] });
  });

  test("Edge Case: mixed-case addresses give lowercase keys", () => {
    // 1. Arrange
    const groups = [group("RotaSul04R@MonAmieNet.org")];

    // 2. Act
    const visible = visibleTeams("rotasul", groups);

    // 3. Assert
    assert.deepEqual(visible, { all: false, keys: ["rotasul04"] });
  });

  test("Edge Case: no groups see nothing", () => {
    // 1. Arrange
    const groups = [];

    // 2. Act
    const visible = visibleTeams("rotasul", groups);

    // 3. Assert
    assert.deepEqual(visible, { all: false, keys: [] });
  });

  test(
    "Sad Path: team groups, other organizations, other domains and malformed " +
      "entries give nothing",
    () => {
      // 1. Arrange
      const groups = [
        group("rotasul01@monamienet.org"),
        group("outro00@monamienet.org"),
        group("outro01w@monamienet.org"),
        group("rotasul02w@example.com"),
        group("rotasul00r@monamienet.org"),
        group("rotasul5w@monamienet.org"),
        { email: 42 },
        {},
        null,
      ];

      // 2. Act
      const visible = visibleTeams("rotasul", groups);

      // 3. Assert
      assert.deepEqual(visible, { all: false, keys: [] });
    },
  );
});

describe("teamNames - Unit Test Suite", () => {
  test("Happy Path: a leaf member gets the names of their teams", async () => {
    // 1. Arrange
    const api = fakeGroupsApi(rotasulTree());
    const groups = [
      group("rotasul02r@monamienet.org"),
      group("rotasul01w@monamienet.org"),
    ];

    // 2. Act
    const names = await teamNames(api, "rotasul", groups);

    // 3. Assert
    assert.deepEqual(names, { rotasul01: "Centro", rotasul02: "Zona Norte" });
  });

  test(
    "Happy Path: an administrator gets every team under the root group",
    async () => {
      // 1. Arrange
      const api = fakeGroupsApi(rotasulTree());
      const groups = [group("rotasul00@monamienet.org")];

      // 2. Act
      const names = await teamNames(api, "rotasul", groups);

      // 3. Assert
      assert.deepEqual(names, {
        rotasul01: "Centro",
        rotasul02: "Zona Norte",
        rotasul03: "Zona Sul",
      });
    },
  );

  test(
    "Edge Case: an administrator also in a leaf reads each team once",
    async () => {
      // 1. Arrange
      const api = fakeGroupsApi(rotasulTree());
      const groups = [
        group("rotasul02w@monamienet.org"),
        group("rotasul00@monamienet.org"),
      ];

      // 2. Act
      const names = await teamNames(api, "rotasul", groups);

      // 3. Assert
      const reads = api.calls.filter(([method]) => method === "get");
      assert.deepEqual(
        [names, reads],
        [
          { rotasul01: "Centro", rotasul02: "Zona Norte", rotasul03: "Zona Sul" },
          [
            ["get", "groups/rotasul01@monamienet.org"],
            ["get", "groups/rotasul02@monamienet.org"],
            ["get", "groups/rotasul03@monamienet.org"],
          ],
        ],
      );
    },
  );

  test("Edge Case: display names are trimmed", async () => {
    // 1. Arrange
    const tree = rotasulTree();
    tree["rotasul01@monamienet.org"].displayName = "  Centro \n";
    const api = fakeGroupsApi(tree);
    const groups = [group("rotasul01w@monamienet.org")];

    // 2. Act
    const names = await teamNames(api, "rotasul", groups);

    // 3. Assert
    assert.deepEqual(names, { rotasul01: "Centro" });
  });

  test(
    "Edge Case: the root's users, leaves and other organizations' groups add " +
      "no team",
    async () => {
      // 1. Arrange
      const api = fakeGroupsApi({
        "rotasul00@monamienet.org": {
          displayName: "Rota Sul",
          members: [
            subgroup("rotasul01@monamienet.org"),
            subgroup("rotasul02w@monamienet.org"),
            subgroup("outro03@monamienet.org"),
            { email: "rotasul04@monamienet.org", type: "USER" },
          ],
        },
        "rotasul01@monamienet.org": { displayName: "Centro" },
        "rotasul02@monamienet.org": { displayName: "Zona Norte" },
        "outro03@monamienet.org": { displayName: "Outro" },
        "rotasul04@monamienet.org": { displayName: "Usuario" },
      });
      const groups = [group("rotasul00@monamienet.org")];

      // 2. Act
      const names = await teamNames(api, "rotasul", groups);

      // 3. Assert
      assert.deepEqual(names, { rotasul01: "Centro" });
    },
  );

  test(
    "Sad Path: a non-administrator never reads the teams they are not in",
    async () => {
      // 1. Arrange
      const api = fakeGroupsApi(rotasulTree());
      const groups = [
        group("rotasul02w@monamienet.org"),
        group("rotasul01@monamienet.org"),
        group("outro00@monamienet.org"),
      ];

      // 2. Act
      const names = await teamNames(api, "rotasul", groups);

      // 3. Assert
      assert.deepEqual(
        [names, api.calls],
        [
          { rotasul02: "Zona Norte" },
          [
            ["lookup", "rotasul02@monamienet.org"],
            ["get", "groups/rotasul02@monamienet.org"],
          ],
        ],
      );
    },
  );

  test("Sad Path: a team whose group is missing is left out", async () => {
    // 1. Arrange
    const api = fakeGroupsApi(rotasulTree());
    const groups = [
      group("rotasul01w@monamienet.org"),
      group("rotasul09w@monamienet.org"),
    ];

    // 2. Act
    const names = await teamNames(api, "rotasul", groups);

    // 3. Assert
    assert.deepEqual(names, { rotasul01: "Centro" });
  });

  const unusable = [
    ["blank", "   "],
    ["empty", ""],
    ["not a string", 7],
    ["missing", undefined],
  ];
  for (const [label, displayName] of unusable) {
    test(`Sad Path: a team whose display name is ${label} is left out`, async () => {
      // 1. Arrange
      const tree = rotasulTree();
      tree["rotasul02@monamienet.org"].displayName = displayName;
      const api = fakeGroupsApi(tree);
      const groups = [
        group("rotasul01r@monamienet.org"),
        group("rotasul02r@monamienet.org"),
      ];

      // 2. Act
      const names = await teamNames(api, "rotasul", groups);

      // 3. Assert
      assert.deepEqual(names, { rotasul01: "Centro" });
    });
  }

  test("Sad Path: no visible teams give no names and no calls", async () => {
    // 1. Arrange
    const api = fakeGroupsApi(rotasulTree());
    const groups = [group("outro01w@monamienet.org")];

    // 2. Act
    const names = await teamNames(api, "rotasul", groups);

    // 3. Assert
    assert.deepEqual([names, api.calls], [{}, []]);
  });
});
