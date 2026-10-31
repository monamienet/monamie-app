const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  createTeam,
  deleteTeam,
  deletionImpact,
  listTeams,
  removePerson,
  renameTeam,
  setRoles,
} = require("../team_service");
const { TeamError } = require("../teams");

const CUSTOMER = "customers/C0abc";

/**
 * An in-memory `GroupsApi`: groups by e-mail, each with a resource name
 * `groups/<e-mail>`, a display name, a parent and direct members. Every
 * call is appended to `calls` as `[method, ...args]`. `failCreate` names
 * e-mails whose creation rejects.
 */
function fakeGroupsApi(groups = {}) {
  const byEmail = new Map();
  const calls = [];
  const failCreate = new Set();
  const nameOf = (email) => `groups/${email}`;
  const byName = (name) => [...byEmail.values()].find((g) => g.name === name);
  const add = (email, displayName, parent, members = []) =>
    byEmail.set(email, { name: nameOf(email), email, displayName, parent, members: [...members] });
  for (const [email, group] of Object.entries(groups)) {
    add(email, group.displayName, group.parent ?? CUSTOMER, group.members);
  }
  return {
    calls,
    failCreate,
    byEmail,
    async lookup(email) {
      calls.push(["lookup", email]);
      return byEmail.get(email)?.name ?? null;
    },
    async get(name) {
      calls.push(["get", name]);
      const group = byName(name);
      return { displayName: group.displayName, parent: group.parent };
    },
    async create(email, displayName, customer) {
      calls.push(["create", email, displayName, customer]);
      if (failCreate.has(email)) throw new Error(`create ${email} failed`);
      add(email, displayName, customer);
      return nameOf(email);
    },
    async setMonAmieSettings(email) {
      calls.push(["setMonAmieSettings", email]);
    },
    async rename(name, displayName) {
      calls.push(["rename", name, displayName]);
      byName(name).displayName = displayName;
    },
    async delete(name) {
      calls.push(["delete", name]);
      byEmail.delete(byName(name).email);
    },
    async members(name) {
      calls.push(["members", name]);
      return byName(name).members.map((m) => ({ ...m }));
    },
    async addMember(name, email) {
      calls.push(["addMember", name, email]);
      const type = email.endsWith("@monamienet.org") ? "GROUP" : "USER";
      byName(name).members.push({ email, type });
    },
    async removeMember(name, email) {
      calls.push(["removeMember", name, email]);
      const group = byName(name);
      group.members = group.members.filter((m) => m.email !== email);
    },
  };
}

const user = (email) => ({ email, type: "USER" });
const group = (email) => ({ email, type: "GROUP" });
const g = (local) => `${local}@monamienet.org`;

/**
 * Rota Sul with teams 01 "Equipe Norte" (ana: share; bia: share + watch)
 * and 03 "Equipe Leste" (bia: watch; caio: share), the owner dono in the
 * root group.
 */
function rotaSul() {
  return fakeGroupsApi({
    [g("rotasul00")]: {
      displayName: "Rota Sul",
      members: [user("dono@x.com"), group(g("rotasul01")), group(g("rotasul03"))],
    },
    [g("rotasul01")]: {
      displayName: "Equipe Norte",
      members: [group(g("rotasul01r")), group(g("rotasul01w"))],
    },
    [g("rotasul01r")]: { displayName: "Equipe Norte · vê o mapa", members: [user("bia@x.com")] },
    [g("rotasul01w")]: {
      displayName: "Equipe Norte · em campo",
      members: [user("ana@x.com"), user("bia@x.com")],
    },
    [g("rotasul03")]: {
      displayName: "Equipe Leste",
      members: [group(g("rotasul03r")), group(g("rotasul03w"))],
    },
    [g("rotasul03r")]: { displayName: "Equipe Leste · vê o mapa", members: [user("bia@x.com")] },
    [g("rotasul03w")]: { displayName: "Equipe Leste · em campo", members: [user("caio@x.com")] },
  });
}

/** The write calls (no lookups, gets or member reads). */
const writes = (api) =>
  api.calls.filter(([method]) => !["lookup", "get", "members"].includes(method));

/** Awaits `act` and returns the TeamError it rejects with. */
async function teamErrorOf(act) {
  try {
    await act();
  } catch (error) {
    assert.ok(error instanceof TeamError, `expected TeamError, got ${error}`);
    return error;
  }
  assert.fail("expected a TeamError");
}

describe("listTeams - Unit Test Suite", () => {
  test("Happy Path: lists the teams with their people and roles, by number", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    const teams = await listTeams(api, "rotasul");

    // 3. Assert
    assert.deepEqual(
      teams.map((t) => ({ team: t.team, key: t.key, name: t.name, people: sortByEmail(t.people) })),
      [
        {
          team: "01",
          key: "rotasul01",
          name: "Equipe Norte",
          people: [
            { email: "ana@x.com", roles: ["share"] },
            { email: "bia@x.com", roles: ["share", "watch"] },
          ],
        },
        {
          team: "03",
          key: "rotasul03",
          name: "Equipe Leste",
          people: [
            { email: "bia@x.com", roles: ["watch"] },
            { email: "caio@x.com", roles: ["share"] },
          ],
        },
      ]
    );
  });

  test("Edge Case: users, leaves and other organizations' groups in the root are ignored", async () => {
    // 1. Arrange
    const api = fakeGroupsApi({
      [g("rotasul00")]: {
        displayName: "Rota Sul",
        members: [
          group(g("rotasul02")),
          user("dono@x.com"),
          group(g("rotasul02w")),
          group(g("aquariustur01")),
          group("equipe@gmail.com"),
        ],
      },
      [g("rotasul02")]: { displayName: "Equipe Serra", members: [] },
      [g("aquariustur01")]: { displayName: "Outra", members: [] },
    });

    // 2. Act
    const teams = await listTeams(api, "rotasul");

    // 3. Assert
    assert.deepEqual(teams.map((t) => t.key), ["rotasul02"]);
  });

  test("Edge Case: a team without a display name is called Equipe NN", async () => {
    // 1. Arrange
    const api = fakeGroupsApi({
      [g("rotasul00")]: { displayName: "Rota Sul", members: [group(g("rotasul05"))] },
      [g("rotasul05")]: { displayName: "", members: [] },
    });

    // 2. Act
    const teams = await listTeams(api, "rotasul");

    // 3. Assert
    assert.equal(teams[0].name, "Equipe 05");
  });

  test("Edge Case: teams come sorted by number whatever the root's order", async () => {
    // 1. Arrange
    const api = fakeGroupsApi({
      [g("rotasul00")]: {
        displayName: "Rota Sul",
        members: [group(g("rotasul10")), group(g("rotasul02"))],
      },
      [g("rotasul10")]: { displayName: "Dez", members: [] },
      [g("rotasul02")]: { displayName: "Dois", members: [] },
    });

    // 2. Act
    const teams = await listTeams(api, "rotasul");

    // 3. Assert
    assert.deepEqual(teams.map((t) => t.team), ["02", "10"]);
  });

  test("Sad Path: an organization without a root group throws TeamError", async () => {
    // 1. Arrange
    const api = fakeGroupsApi({});

    // 2. Act
    const error = await teamErrorOf(() => listTeams(api, "rotasul"));

    // 3. Assert
    assert.ok(error instanceof TeamError);
  });
});

/** People sorted by e-mail, to compare without depending on read order. */
function sortByEmail(people) {
  return [...people].sort((a, b) => a.email.localeCompare(b.email));
}

describe("createTeam - Unit Test Suite", () => {
  test("Happy Path: creates team 02 with its two leaves, nested and configured", async () => {
    // 1. Arrange
    const api = rotaSul();
    api.byEmail.get(g("rotasul00")).parent = CUSTOMER;

    // 2. Act
    const created = await createTeam(api, "rotasul", "Equipe Serra");

    // 3. Assert
    assert.deepEqual(created, { team: "02", key: "rotasul02", name: "Equipe Serra" });
    assert.deepEqual(
      writes(api).map((c) => c.join(" | ")),
      [
        `create | ${g("rotasul02")} | Equipe Serra | ${CUSTOMER}`,
        `setMonAmieSettings | ${g("rotasul02")}`,
        `addMember | groups/${g("rotasul00")} | ${g("rotasul02")}`,
        `create | ${g("rotasul02r")} | Equipe Serra · vê o mapa | ${CUSTOMER}`,
        `setMonAmieSettings | ${g("rotasul02r")}`,
        `addMember | groups/${g("rotasul02")} | ${g("rotasul02r")}`,
        `create | ${g("rotasul02w")} | Equipe Serra · em campo | ${CUSTOMER}`,
        `setMonAmieSettings | ${g("rotasul02w")}`,
        `addMember | groups/${g("rotasul02")} | ${g("rotasul02w")}`,
      ]
    );
  });

  test("Edge Case: the customer comes from the root group's parent", async () => {
    // 1. Arrange
    const api = rotaSul();
    api.byEmail.get(g("rotasul00")).parent = "customers/Cother";

    // 2. Act
    await createTeam(api, "rotasul", "Equipe Serra");

    // 3. Assert
    const customers = api.calls.filter(([m]) => m === "create").map((c) => c[3]);
    assert.deepEqual(customers, ["customers/Cother", "customers/Cother", "customers/Cother"]);
  });

  test("Sad Path: a duplicate name throws duplicate before creating anything", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    const error = await teamErrorOf(() => createTeam(api, "rotasul", "equipe  NORTE"));

    // 3. Assert
    assert.equal(error.code, "duplicate");
    assert.deepEqual(writes(api), []);
  });

  test("Sad Path: when the share leaf fails, the groups already created are deleted", async () => {
    // 1. Arrange
    const api = rotaSul();
    api.failCreate.add(g("rotasul02w"));

    // 2. Act
    const failure = await createTeam(api, "rotasul", "Equipe Serra").then(
      () => null,
      (error) => error
    );

    // 3. Assert
    assert.match(String(failure?.message), /rotasul02w/);
    const deleted = api.calls.filter(([m]) => m === "delete").map((c) => c[1]).sort();
    assert.deepEqual(deleted, [`groups/${g("rotasul02")}`, `groups/${g("rotasul02r")}`]);
    assert.equal(api.byEmail.has(g("rotasul02")), false);
    assert.equal(api.byEmail.has(g("rotasul02r")), false);
  });
});

describe("renameTeam - Unit Test Suite", () => {
  test("Happy Path: renames only the team group", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await renameTeam(api, "rotasul", "01", "Equipe Serra");

    // 3. Assert
    assert.deepEqual(writes(api), [["rename", `groups/${g("rotasul01")}`, "Equipe Serra"]]);
  });

  test("Edge Case: renaming a team to its own name is allowed", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await renameTeam(api, "rotasul", "01", "equipe norte");

    // 3. Assert
    assert.deepEqual(writes(api), [["rename", `groups/${g("rotasul01")}`, "equipe norte"]]);
  });

  test("Sad Path: another team's name throws duplicate without renaming", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    const error = await teamErrorOf(() => renameTeam(api, "rotasul", "01", "Equipe Léste"));

    // 3. Assert
    assert.equal(error.code, "duplicate");
    assert.deepEqual(writes(api), []);
  });

  test("Sad Path: an unknown team throws code team", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    const error = await teamErrorOf(() => renameTeam(api, "rotasul", "07", "Equipe Serra"));

    // 3. Assert
    assert.equal(error.code, "team");
  });
});

describe("deletionImpact - Unit Test Suite", () => {
  test("Happy Path: people only in the team lose access, people in another team stay", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    const impact = await deletionImpact(api, "rotasul", "01");

    // 3. Assert
    assert.deepEqual(impact, { loses: ["ana@x.com"], stays: ["bia@x.com"] });
  });

  test("Edge Case: a team whose people are all elsewhere loses nobody", async () => {
    // 1. Arrange
    const api = rotaSul();
    api.byEmail.get(g("rotasul03w")).members = [user("ana@x.com")];

    // 2. Act
    const impact = await deletionImpact(api, "rotasul", "03");

    // 3. Assert
    assert.deepEqual(impact, { loses: [], stays: ["ana@x.com", "bia@x.com"] });
  });

  test("Sad Path: an unknown team affects nobody", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    const impact = await deletionImpact(api, "rotasul", "07");

    // 3. Assert
    assert.deepEqual(impact, { loses: [], stays: [] });
  });
});

describe("deleteTeam - Unit Test Suite", () => {
  test("Happy Path: deletes the watch leaf, the share leaf, then the team", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await deleteTeam(api, "rotasul", "01");

    // 3. Assert
    assert.deepEqual(writes(api), [
      ["delete", `groups/${g("rotasul01r")}`],
      ["delete", `groups/${g("rotasul01w")}`],
      ["delete", `groups/${g("rotasul01")}`],
    ]);
  });

  test("Edge Case: a missing leaf is skipped", async () => {
    // 1. Arrange
    const api = rotaSul();
    api.byEmail.delete(g("rotasul01r"));

    // 2. Act
    await deleteTeam(api, "rotasul", "01");

    // 3. Assert
    assert.deepEqual(writes(api), [
      ["delete", `groups/${g("rotasul01w")}`],
      ["delete", `groups/${g("rotasul01")}`],
    ]);
  });

  test("Sad Path: a team that does not exist deletes nothing", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await deleteTeam(api, "rotasul", "07");

    // 3. Assert
    assert.deepEqual(writes(api), []);
  });
});

describe("setRoles - Unit Test Suite", () => {
  test("Happy Path: giving watch to a share-only person adds them to the r leaf only", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await setRoles(api, "rotasul", "01", "ana@x.com", ["share", "watch"]);

    // 3. Assert
    assert.deepEqual(writes(api), [["addMember", `groups/${g("rotasul01r")}`, "ana@x.com"]]);
  });

  test("Happy Path: keeping only watch removes a person with both from the w leaf only", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await setRoles(api, "rotasul", "01", "bia@x.com", ["watch"]);

    // 3. Assert
    assert.deepEqual(writes(api), [["removeMember", `groups/${g("rotasul01w")}`, "bia@x.com"]]);
  });

  test("Edge Case: the roles a person already has change nothing", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await setRoles(api, "rotasul", "01", "ana@x.com", ["share"]);

    // 3. Assert
    assert.deepEqual(writes(api), []);
  });

  test("Sad Path: no roles throws roles without any API call", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    const error = await teamErrorOf(() => setRoles(api, "rotasul", "01", "ana@x.com", []));

    // 3. Assert
    assert.equal(error.code, "roles");
    assert.deepEqual(api.calls, []);
  });
});

describe("removePerson - Unit Test Suite", () => {
  test("Happy Path: a person with both roles leaves both leaves", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await removePerson(api, "rotasul", "01", "bia@x.com");

    // 3. Assert
    assert.deepEqual(writes(api).sort(), [
      ["removeMember", `groups/${g("rotasul01r")}`, "bia@x.com"],
      ["removeMember", `groups/${g("rotasul01w")}`, "bia@x.com"],
    ]);
    assert.deepEqual(api.byEmail.get(g("rotasul01w")).members, [user("ana@x.com")]);
  });

  test("Edge Case: a missing leaf is skipped", async () => {
    // 1. Arrange
    const api = rotaSul();
    api.byEmail.delete(g("rotasul01r"));

    // 2. Act
    await removePerson(api, "rotasul", "01", "ana@x.com");

    // 3. Assert
    assert.deepEqual(writes(api), [["removeMember", `groups/${g("rotasul01w")}`, "ana@x.com"]]);
  });

  test("Sad Path: a team that does not exist removes nobody", async () => {
    // 1. Arrange
    const api = rotaSul();

    // 2. Act
    await removePerson(api, "rotasul", "07", "ana@x.com");

    // 3. Assert
    assert.deepEqual(writes(api), []);
  });
});
