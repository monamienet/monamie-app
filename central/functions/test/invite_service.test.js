const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  acceptInvite,
  cancelInvite,
  myInvites,
  resendInvite,
  sendInvites,
} = require("../invite_service");
const { InviteError } = require("../invites");

const CUSTOMER = "customers/C0abc";
const NOW = new Date("2026-10-26T12:00:00Z");
const IN_14_DAYS = "2026-11-09T12:00:00.000Z";
const LATER = new Date("2026-11-05T12:00:00Z");
const EARLIER = new Date("2026-10-20T12:00:00Z");

/**
 * An in-memory `GroupsApi` (as in team_service.test.js): groups by e-mail
 * with a resource name `groups/<e-mail>`, display name, parent and direct
 * members. Every call is appended to `calls`.
 */
function fakeGroupsApi(groups = {}) {
  const byEmail = new Map();
  const calls = [];
  const nameOf = (email) => `groups/${email}`;
  const byName = (name) => [...byEmail.values()].find((g) => g.name === name);
  const add = (email, displayName, parent, members = []) =>
    byEmail.set(email, { name: nameOf(email), email, displayName, parent, members: [...members] });
  for (const [email, group] of Object.entries(groups)) {
    add(email, group.displayName, group.parent ?? CUSTOMER, group.members);
  }
  return {
    calls,
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

/** Rota Sul with team 01 "Equipe Norte" (ana: share; bia: share + watch). */
function rotaSul() {
  return fakeGroupsApi({
    [g("rotasul00")]: { displayName: "Rota Sul", members: [user("dono@x.com"), group(g("rotasul01"))] },
    [g("rotasul01")]: {
      displayName: "Equipe Norte",
      members: [group(g("rotasul01r")), group(g("rotasul01w"))],
    },
    [g("rotasul01r")]: { displayName: "Equipe Norte · vê o mapa", members: [user("bia@x.com")] },
    [g("rotasul01w")]: {
      displayName: "Equipe Norte · em campo",
      members: [user("ana@x.com"), user("bia@x.com")],
    },
  });
}

/** Rota Sul with no team yet. */
function rotaSulWithoutTeams() {
  return fakeGroupsApi({
    [g("rotasul00")]: { displayName: "Rota Sul", members: [user("dono@x.com")] },
  });
}

const peopleOf = (api, leaf) => api.byEmail.get(g(leaf)).members.map((m) => m.email);

/**
 * An in-memory Firestore with only what the invite service uses:
 * `collection(c).where(f, "==", v)...get()`, `collection(c).add(data)`,
 * `doc("c/id").get()` and `ref.update(data)`. `docs` maps "c/id" to data.
 */
function fakeFirestore(docs = {}) {
  const store = new Map(Object.entries(docs).map(([path, data]) => [path, { ...data }]));
  let next = 1;
  const ref = (path) => ({
    async update(data) {
      store.set(path, { ...store.get(path), ...data });
    },
  });
  const snapshot = (path) => {
    const data = store.get(path);
    return {
      id: path.split("/")[1],
      exists: data !== undefined,
      data: () => (data === undefined ? undefined : { ...data }),
      get: (field) => data?.[field],
      ref: ref(path),
    };
  };
  const query = (collection, filters) => ({
    where(field, op, value) {
      assert.equal(op, "==", `the fake only supports ==, got ${op}`);
      return query(collection, [...filters, [field, value]]);
    },
    async get() {
      const docs = [...store.keys()]
        .filter((path) => path.startsWith(`${collection}/`))
        .filter((path) => filters.every(([f, v]) => store.get(path)[f] === v))
        .map(snapshot);
      return { empty: docs.length === 0, docs };
    },
  });
  return {
    store,
    /** The documents of `collection`, as `[{id, ...data}]`. */
    all(collection) {
      return [...store.entries()]
        .filter(([path]) => path.startsWith(`${collection}/`))
        .map(([path, data]) => ({ id: path.split("/")[1], ...data }));
    },
    collection(name) {
      return {
        ...query(name, []),
        async add(data) {
          const id = `new${next++}`;
          store.set(`${name}/${id}`, { ...data });
          return ref(`${name}/${id}`);
        },
      };
    },
    doc(path) {
      return { ...ref(path), get: async () => snapshot(path) };
    },
  };
}

/** A mailer that records what it sends; e-mails in `fail` reject. */
function fakeMailer() {
  const sent = [];
  const fail = new Set();
  return {
    sent,
    fail,
    async send(message) {
      if (fail.has(message.to)) throw new Error(`smtp refused ${message.to}`);
      sent.push(message);
    },
  };
}

const owner = { email: "dono@x.com", name: "Rita Lima" };

function sendRequest(overrides = {}) {
  return {
    partnerId: "rotasul",
    partnerName: "Rota Sul",
    owner,
    team: "01",
    invites: [{ email: "davi@x.com", roles: ["share"] }],
    now: NOW,
    ...overrides,
  };
}

/** A stored invite of davi to Rota Sul's team 01. */
function storedInvite(overrides = {}) {
  return {
    partnerId: "rotasul",
    partnerName: "Rota Sul",
    team: "01",
    teamName: "Equipe Norte",
    email: "davi@x.com",
    roles: ["share", "watch"],
    invitedByName: "Rita Lima",
    invitedByEmail: "dono@x.com",
    expiresAt: LATER,
    status: "pending",
    ...overrides,
  };
}

const iso = (date) => (date instanceof Date ? date.toISOString() : date);

/** Awaits `act` and returns the InviteError it rejects with. */
async function inviteErrorOf(act) {
  try {
    await act();
  } catch (error) {
    assert.ok(error instanceof InviteError, `expected InviteError, got ${error}`);
    return error;
  }
  assert.fail("expected an InviteError");
}

describe("sendInvites - Unit Test Suite", () => {
  test("Happy Path: creates a pending invite valid for 14 days", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const request = sendRequest({ invites: [{ email: " Davi@X.com", roles: ["watch", "share"] }] });

    // 2. Act
    await sendInvites(db, rotaSul(), fakeMailer(), request);

    // 3. Assert
    const invites = db.all("invites");
    assert.equal(invites.length, 1);
    const { partnerId, team, teamName, email, roles, expiresAt, status, invitedByName } = invites[0];
    assert.deepEqual(
      { partnerId, team, teamName, email, roles, expiresAt: iso(expiresAt), status, invitedByName },
      {
        partnerId: "rotasul",
        team: "01",
        teamName: "Equipe Norte",
        email: "davi@x.com",
        roles: ["share", "watch"],
        expiresAt: IN_14_DAYS,
        status: "pending",
        invitedByName: "Rita Lima",
      }
    );
  });

  test("Happy Path: each invite is e-mailed and reported as emailed", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const mailer = fakeMailer();

    // 2. Act
    const result = await sendInvites(db, rotaSul(), mailer, sendRequest());

    // 3. Assert
    assert.deepEqual(mailer.sent.map((m) => m.to), ["davi@x.com"]);
    assert.deepEqual(result.sent, [{ email: "davi@x.com", roles: ["share"], emailed: true }]);
  });

  test("Edge Case: a person already in the team with those roles is skipped", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const mailer = fakeMailer();
    const request = sendRequest({ invites: [{ email: "ana@x.com", roles: ["share"] }] });

    // 2. Act
    const result = await sendInvites(db, rotaSul(), mailer, request);

    // 3. Assert
    assert.equal(result.skipped.length, 1);
    assert.equal(result.skipped[0].email, "ana@x.com");
    assert.ok(result.skipped[0].reason, "a skipped person has a reason");
    assert.deepEqual(db.all("invites"), []);
    assert.deepEqual(mailer.sent, []);
  });

  test("Edge Case: a person in the team who lacks one of the roles is invited", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const request = sendRequest({ invites: [{ email: "ana@x.com", roles: ["share", "watch"] }] });

    // 2. Act
    const result = await sendInvites(db, rotaSul(), fakeMailer(), request);

    // 3. Assert
    assert.deepEqual(result.skipped, []);
    assert.deepEqual(db.all("invites").map((i) => i.email), ["ana@x.com"]);
  });

  test("Edge Case: a pending invite for the same team and e-mail is updated, not duplicated", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      "invites/old": storedInvite({ roles: ["share"], expiresAt: EARLIER }),
    });
    const request = sendRequest({ invites: [{ email: "davi@x.com", roles: ["watch"] }] });

    // 2. Act
    await sendInvites(db, rotaSul(), fakeMailer(), request);

    // 3. Assert
    const invites = db.all("invites");
    assert.deepEqual(
      invites.map((i) => ({ id: i.id, roles: i.roles, expiresAt: iso(i.expiresAt), status: i.status })),
      [{ id: "old", roles: ["watch"], expiresAt: IN_14_DAYS, status: "pending" }]
    );
  });

  test("Edge Case: a cancelled invite for the same person does not block a new one", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/old": storedInvite({ status: "cancelled" }) });

    // 2. Act
    await sendInvites(db, rotaSul(), fakeMailer(), sendRequest());

    // 3. Assert
    const statuses = db.all("invites").map((i) => i.status).sort();
    assert.deepEqual(statuses, ["cancelled", "pending"]);
  });

  test("Edge Case: with firstTeamName the team is created first and the invites go to it", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const api = rotaSulWithoutTeams();
    const request = sendRequest({ team: undefined, firstTeamName: "Equipe Serra" });

    // 2. Act
    const result = await sendInvites(db, api, fakeMailer(), request);

    // 3. Assert
    const created = api.calls.filter(([m]) => m === "create").map((c) => c[1]);
    assert.deepEqual(created, [g("rotasul01"), g("rotasul01r"), g("rotasul01w")]);
    const [invite] = db.all("invites");
    assert.deepEqual(
      { team: invite.team, teamName: invite.teamName, resultTeam: result.team },
      { team: "01", teamName: "Equipe Serra", resultTeam: "01" }
    );
  });

  test("Sad Path: when the e-mail fails the invite still exists and emailed is false", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const mailer = fakeMailer();
    mailer.fail.add("davi@x.com");
    const quiet = console.error;
    console.error = () => {};

    // 2. Act
    const result = await sendInvites(db, rotaSul(), mailer, sendRequest()).finally(() => {
      console.error = quiet;
    });

    // 3. Assert
    assert.deepEqual(result.sent, [{ email: "davi@x.com", roles: ["share"], emailed: false }]);
    assert.deepEqual(db.all("invites").map((i) => i.status), ["pending"]);
  });

  test("Sad Path: an unknown team throws team and creates no invite", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const mailer = fakeMailer();

    // 2. Act
    const error = await inviteErrorOf(() =>
      sendInvites(db, rotaSul(), mailer, sendRequest({ team: "07" }))
    );

    // 3. Assert
    assert.equal(error.code, "team");
    assert.deepEqual(db.all("invites"), []);
    assert.deepEqual(mailer.sent, []);
  });

  test("Sad Path: an empty list of people throws empty and creates nothing", async () => {
    // 1. Arrange
    const db = fakeFirestore();
    const api = rotaSulWithoutTeams();
    const request = sendRequest({ team: undefined, firstTeamName: "Equipe Serra", invites: [] });

    // 2. Act
    const error = await inviteErrorOf(() => sendInvites(db, api, fakeMailer(), request));

    // 3. Assert
    assert.equal(error.code, "empty");
    assert.deepEqual(db.all("invites"), []);
    assert.deepEqual(api.calls.filter(([m]) => m === "create"), []);
  });
});

describe("myInvites - Unit Test Suite", () => {
  test("Happy Path: lists only the pending, unexpired invites of that e-mail", async () => {
    // 1. Arrange
    const db = fakeFirestore({
      "invites/ok": storedInvite(),
      "invites/expired": storedInvite({ team: "02", expiresAt: EARLIER }),
      "invites/cancelled": storedInvite({ team: "03", status: "cancelled" }),
      "invites/accepted": storedInvite({ team: "04", status: "accepted" }),
      "invites/other": storedInvite({ email: "ana@x.com" }),
    });

    // 2. Act
    const invites = await myInvites(db, "davi@x.com", NOW);

    // 3. Assert
    assert.deepEqual(invites.map((i) => i.id), ["ok"]);
  });

  test("Edge Case: the e-mail is compared ignoring case", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/ok": storedInvite() });

    // 2. Act
    const invites = await myInvites(db, "Davi@X.com", NOW);

    // 3. Assert
    assert.deepEqual(invites.map((i) => i.id), ["ok"]);
  });

  test("Edge Case: an invite expiring exactly now is not listed", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/ok": storedInvite({ expiresAt: new Date(NOW) }) });

    // 2. Act
    const invites = await myInvites(db, "davi@x.com", NOW);

    // 3. Assert
    assert.deepEqual(invites, []);
  });

  test("Sad Path: an e-mail with no invite gets an empty list", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/ok": storedInvite() });

    // 2. Act
    const invites = await myInvites(db, "zeca@x.com", NOW);

    // 3. Assert
    assert.deepEqual(invites, []);
  });
});

describe("acceptInvite - Unit Test Suite", () => {
  test("Happy Path: adds the person to both leaves for share + watch", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite() });
    const api = rotaSul();

    // 2. Act
    await acceptInvite(db, api, "inv1", "davi@x.com", NOW);

    // 3. Assert
    assert.ok(peopleOf(api, "rotasul01r").includes("davi@x.com"));
    assert.ok(peopleOf(api, "rotasul01w").includes("davi@x.com"));
  });

  test("Happy Path: marks the invite accepted and returns its partner", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite() });

    // 2. Act
    const result = await acceptInvite(db, rotaSul(), "inv1", "davi@x.com", NOW);

    // 3. Assert
    assert.equal(result.partnerId, "rotasul");
    assert.equal(db.store.get("invites/inv1").status, "accepted");
  });

  test("Edge Case: a watch-only invite adds the person to the r leaf only", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite({ roles: ["watch"] }) });
    const api = rotaSul();

    // 2. Act
    await acceptInvite(db, api, "inv1", "davi@x.com", NOW);

    // 3. Assert
    const adds = api.calls.filter(([m]) => m === "addMember").map((c) => [c[1], c[2]]);
    assert.deepEqual(adds, [[`groups/${g("rotasul01r")}`, "davi@x.com"]]);
  });

  test("Edge Case: a share-only invite adds the person to the w leaf only", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite({ roles: ["share"] }) });
    const api = rotaSul();

    // 2. Act
    await acceptInvite(db, api, "inv1", "davi@x.com", NOW);

    // 3. Assert
    const adds = api.calls.filter(([m]) => m === "addMember").map((c) => [c[1], c[2]]);
    assert.deepEqual(adds, [[`groups/${g("rotasul01w")}`, "davi@x.com"]]);
  });

  test("Edge Case: the signed-in e-mail is compared ignoring case", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite() });

    // 2. Act
    await acceptInvite(db, rotaSul(), "inv1", "Davi@X.com", NOW);

    // 3. Assert
    assert.equal(db.store.get("invites/inv1").status, "accepted");
  });

  const refused = [
    ["another account", "inv1", "ana@x.com", {}, "invite"],
    ["an invite that does not exist", "nope", "davi@x.com", {}, "invite"],
    ["an expired invite", "inv1", "davi@x.com", { expiresAt: EARLIER }, "expired"],
    ["a cancelled invite", "inv1", "davi@x.com", { status: "cancelled" }, "invite"],
    ["an invite already accepted", "inv1", "davi@x.com", { status: "accepted" }, "invite"],
  ];
  for (const [label, id, email, overrides, code] of refused) {
    test(`Sad Path: ${label} throws ${code} and adds nobody`, async () => {
      // 1. Arrange
      const db = fakeFirestore({ "invites/inv1": storedInvite(overrides) });
      const api = rotaSul();

      // 2. Act
      const error = await inviteErrorOf(() => acceptInvite(db, api, id, email, NOW));

      // 3. Assert
      assert.equal(error.code, code);
      assert.deepEqual(api.calls.filter(([m]) => m === "addMember"), []);
    });
  }

  test("Sad Path: a team whose leaf no longer exists throws team", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite({ team: "05" }) });

    // 2. Act
    const error = await inviteErrorOf(() => acceptInvite(db, rotaSul(), "inv1", "davi@x.com", NOW));

    // 3. Assert
    assert.equal(error.code, "team");
    assert.equal(db.store.get("invites/inv1").status, "pending");
  });
});

describe("resendInvite - Unit Test Suite", () => {
  test("Happy Path: the invite gets 14 new days from now", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite({ expiresAt: EARLIER }) });

    // 2. Act
    await resendInvite(db, fakeMailer(), "inv1", "rotasul", NOW);

    // 3. Assert
    assert.equal(iso(db.store.get("invites/inv1").expiresAt), IN_14_DAYS);
  });

  test("Edge Case: an expired invite is resent with a new expiry", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite({ expiresAt: EARLIER }) });

    // 2. Act
    const result = await resendInvite(db, fakeMailer(), "inv1", "rotasul", NOW);

    // 3. Assert
    assert.equal(iso(result.expiresAt), IN_14_DAYS);
  });

  test("Sad Path: an invite of another partner is refused with invite", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite() });

    // 2. Act
    const error = await inviteErrorOf(() => resendInvite(db, fakeMailer(), "inv1", "outro", NOW));

    // 3. Assert
    assert.equal(error.code, "invite");
    assert.equal(db.store.get("invites/inv1").expiresAt, LATER);
  });
});

describe("cancelInvite - Unit Test Suite", () => {
  test("Happy Path: the invite becomes cancelled", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite() });

    // 2. Act
    await cancelInvite(db, "inv1", "rotasul");

    // 3. Assert
    assert.equal(db.store.get("invites/inv1").status, "cancelled");
  });

  test("Edge Case: an invite that does not exist is refused with invite", async () => {
    // 1. Arrange
    const db = fakeFirestore();

    // 2. Act
    const error = await inviteErrorOf(() => cancelInvite(db, "nope", "rotasul"));

    // 3. Assert
    assert.equal(error.code, "invite");
  });

  test("Sad Path: an invite of another partner is refused and stays pending", async () => {
    // 1. Arrange
    const db = fakeFirestore({ "invites/inv1": storedInvite() });

    // 2. Act
    const error = await inviteErrorOf(() => cancelInvite(db, "inv1", "outro"));

    // 3. Assert
    assert.equal(error.code, "invite");
    assert.equal(db.store.get("invites/inv1").status, "pending");
  });
});
