const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  acceptInvite,
  cancelGroupInvites,
  cancelInvite,
  inviteGroupId,
  listInvites,
  myInvites,
  resendInvite,
  sendInvites,
} = require("../invite_service");
const { InviteError } = require("../invites");
const { personKey } = require("../person_key");
const { fakeFirestore } = require("./fake_firestore");

const NOW = new Date("2026-10-26T12:00:00Z");
const IN_14_DAYS = "2026-11-09T12:00:00.000Z";
const LATER = new Date("2026-11-05T12:00:00Z");
const ORG = "organizations/rotasul";
const ANA = "ana@x.com";
const VERA = "vera@x.com";

/** Rota Sul's project: group guias, where Vera subscribes. */
function organization(extra = {}) {
  return fakeFirestore({
    [`${ORG}/groups/guias`]: { name: "Guias", createdAt: NOW },
    [`${ORG}/organizationMemberships/${personKey(VERA)}`]: { email: VERA, role: "member" },
    [`${ORG}/groups/guias/groupMemberships/${personKey(VERA)}`]: {
      email: VERA,
      organizationId: "rotasul",
      roles: ["subscriber"],
    },
    ...extra,
  });
}

/** Opens `db` as organization `rotasul`. */
const openerOf = (db) => async (id) => (id === "rotasul" ? { db, registry: {} } : null);

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

function sendRequest(overrides = {}) {
  return {
    organizationId: "rotasul",
    organizationName: "Rota Sul",
    inviter: { email: "olga@x.com", name: "Olga" },
    groupId: "guias",
    invites: [{ email: ANA, roles: ["publisher"] }],
    now: NOW,
    ...overrides,
  };
}

/** A pending invite of Ana to guias, valid until Nov 9. */
function pendingInvite(overrides = {}) {
  return {
    organizationId: "rotasul",
    organizationName: "Rota Sul",
    groupId: "guias",
    groupName: "Guias",
    email: ANA,
    roles: ["publisher", "subscriber"],
    inviterEmail: "olga@x.com",
    inviterName: "Olga",
    createdAt: NOW,
    expiresAt: new Date(IN_14_DAYS),
    status: "pending",
    ...overrides,
  };
}

async function inviteErrorOf(act) {
  try {
    await act();
  } catch (error) {
    assert.ok(error instanceof InviteError, `expected InviteError, got ${error}`);
    return error;
  }
  assert.fail("expected an InviteError");
}

const invitesIn = (centralDb) =>
  [...centralDb.store.entries()].filter(([p]) => p.startsWith("invites/")).map(([, d]) => d);

describe("sendInvites - Unit Test Suite", () => {
  test("Happy Path: creates a pending invite to the group valid for 14 days", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();

    // 2. Act
    await sendInvites(centralDb, organization(), fakeMailer(), sendRequest());

    // 3. Assert
    const [invite] = invitesIn(centralDb);
    assert.deepEqual(
      [invite.groupId, invite.groupName, invite.roles, invite.inviterName, invite.status, invite.expiresAt.toISOString()],
      ["guias", "Guias", ["publisher"], "Olga", "pending", IN_14_DAYS]
    );
  });

  test("Edge Case: a person already in the group with those roles is skipped", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();
    const request = sendRequest({ invites: [{ email: VERA, roles: ["subscriber"] }] });

    // 2. Act
    const result = await sendInvites(centralDb, organization(), fakeMailer(), request);

    // 3. Assert
    assert.deepEqual(result.skipped, [{ email: VERA, reason: "Já está no grupo." }]);
  });

  test("Edge Case: with firstGroupName the group is created and the invite points to it", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();
    const db = organization();
    const request = sendRequest({ groupId: undefined, firstGroupName: "Vendas" });

    // 2. Act
    const result = await sendInvites(centralDb, db, fakeMailer(), request);

    // 3. Assert
    assert.deepEqual(
      [db.store.get(`${ORG}/groups/${result.groupId}`).name, invitesIn(centralDb)[0].groupId],
      ["Vendas", result.groupId]
    );
  });

  test("Sad Path: an unknown group throws group and creates no invite", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();

    // 2. Act
    const error = await inviteErrorOf(() =>
      sendInvites(centralDb, organization(), fakeMailer(), sendRequest({ groupId: "nope" }))
    );

    // 3. Assert
    assert.deepEqual([error.code, invitesIn(centralDb).length], ["group", 0]);
  });
});

describe("acceptInvite - Unit Test Suite", () => {
  test("Happy Path: the person joins the organization and the group with the invite's roles", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite() });
    const db = organization();

    // 2. Act
    await acceptInvite(centralDb, openerOf(db), "i1", ANA, NOW);

    // 3. Assert
    assert.deepEqual(
      [
        db.store.get(`${ORG}/organizationMemberships/${personKey(ANA)}`).role,
        db.store.get(`${ORG}/groups/guias/groupMemberships/${personKey(ANA)}`).roles,
        centralDb.store.get(`accounts/${personKey(ANA)}`).organizationIds,
        centralDb.store.get("invites/i1").status,
      ],
      ["member", ["publisher", "subscriber"], ["rotasul"], "accepted"]
    );
  });

  test("Edge Case: roles already held are kept and an existing role in the organization stays", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({
      "invites/i1": pendingInvite({ email: VERA, roles: ["publisher"] }),
    });
    const db = organization({
      [`${ORG}/organizationMemberships/${personKey(VERA)}`]: { email: VERA, role: "admin" },
    });

    // 2. Act
    await acceptInvite(centralDb, openerOf(db), "i1", "Vera@X.com", NOW);

    // 3. Assert
    assert.deepEqual(
      [
        db.store.get(`${ORG}/organizationMemberships/${personKey(VERA)}`).role,
        db.store.get(`${ORG}/groups/guias/groupMemberships/${personKey(VERA)}`).roles,
      ],
      ["admin", ["publisher", "subscriber"]]
    );
  });

  const refused = [
    ["an expired invite", pendingInvite({ expiresAt: NOW }), "expired"],
    ["a cancelled invite", pendingInvite({ status: "cancelled" }), "invite"],
    ["an invite to someone else", pendingInvite({ email: VERA }), "invite"],
    ["an invite to a deleted group", pendingInvite({ groupId: "apagado" }), "group"],
    ["an invite made before groups had ids", pendingInvite({ groupId: undefined }), "group"],
  ];
  for (const [label, invite, code] of refused) {
    test(`Sad Path: ${label} throws ${code} and adds nobody`, async () => {
      // 1. Arrange
      const centralDb = fakeFirestore({ "invites/i1": invite });
      const db = organization();

      // 2. Act
      const error = await inviteErrorOf(() => acceptInvite(centralDb, openerOf(db), "i1", ANA, NOW));

      // 3. Assert
      assert.deepEqual(
        [error.code, db.store.has(`${ORG}/organizationMemberships/${personKey(ANA)}`)],
        [code, false]
      );
    });
  }
});

describe("cancelGroupInvites - Unit Test Suite", () => {
  test("Happy Path: cancels the pending invites of the group", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/a": pendingInvite(), "invites/b": pendingInvite() });

    // 2. Act
    const count = await cancelGroupInvites(centralDb, "rotasul", "guias");

    // 3. Assert
    assert.equal(count, 2);
  });

  test("Edge Case: invites of another group or already accepted are untouched", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({
      "invites/a": pendingInvite({ groupId: "recepcao" }),
      "invites/b": pendingInvite({ status: "accepted" }),
    });

    // 2. Act
    await cancelGroupInvites(centralDb, "rotasul", "guias");

    // 3. Assert
    assert.deepEqual(invitesIn(centralDb).map((i) => i.status), ["pending", "accepted"]);
  });

  test("Sad Path: a group without invites returns 0", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();

    // 2. Act
    const count = await cancelGroupInvites(centralDb, "rotasul", "guias");

    // 3. Assert
    assert.equal(count, 0);
  });
});

describe("myInvites, resendInvite and cancelInvite - Unit Test Suite", () => {
  test("Happy Path: lists the pending invite with its group", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite() });

    // 2. Act
    const [invite] = await myInvites(centralDb, "ANA@x.com", NOW);

    // 3. Assert
    assert.deepEqual([invite.groupId, invite.groupName, invite.inviterName], ["guias", "Guias", "Olga"]);
  });

  test("Edge Case: resending gives 14 new days from now", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite() });

    // 2. Act
    await resendInvite(centralDb, fakeMailer(), "i1", "rotasul", LATER);

    // 3. Assert
    assert.equal(centralDb.store.get("invites/i1").expiresAt.toISOString(), "2026-11-19T12:00:00.000Z");
  });

  test("Sad Path: an invite of another organization cannot be cancelled", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite({ organizationId: "outro" }) });

    // 2. Act
    const error = await inviteErrorOf(() => cancelInvite(centralDb, "i1", "rotasul"));

    // 3. Assert
    assert.deepEqual([error.code, centralDb.store.get("invites/i1").status], ["invite", "pending"]);
  });
});

describe("sendInvites (more) - Unit Test Suite", () => {
  test("Happy Path: a pending invite of the same person to the group is renewed, not duplicated", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite({ createdAt: new Date("2026-10-01T12:00:00Z") }) });

    // 2. Act
    await sendInvites(centralDb, organization(), fakeMailer(), sendRequest({ now: LATER }));

    // 3. Assert
    const invites = invitesIn(centralDb);
    assert.deepEqual(
      [invites.length, invites[0].roles, invites[0].expiresAt.toISOString()],
      [1, ["publisher"], "2026-11-19T12:00:00.000Z"]
    );
  });

  test("Edge Case: a person in the group without every invited role is invited", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();
    const request = sendRequest({ invites: [{ email: VERA, roles: ["publisher", "subscriber"] }] });

    // 2. Act
    const result = await sendInvites(centralDb, organization(), fakeMailer(), request);

    // 3. Assert
    assert.deepEqual(
      [result.sent.map((s) => s.email), result.skipped],
      [[VERA], []]
    );
  });

  test("Edge Case: an e-mail that cannot be sent still leaves the invite, flagged not emailed", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();
    const mailer = fakeMailer();
    mailer.fail.add(ANA);

    // 2. Act
    const result = await sendInvites(centralDb, organization(), mailer, sendRequest());

    // 3. Assert
    assert.deepEqual(
      [result.sent, invitesIn(centralDb).length],
      [[{ email: ANA, roles: ["publisher"], emailed: false }], 1]
    );
  });

  test("Sad Path: a first group that cannot be created sends nothing", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();
    const db = organization();
    const request = sendRequest({ groupId: undefined, firstGroupName: "guias" });

    // 2. Act
    await sendInvites(centralDb, db, fakeMailer(), request).catch(() => {});

    // 3. Assert
    assert.deepEqual(
      [invitesIn(centralDb).length, [...db.store.keys()].filter((p) => /groups\/[^/]+$/.test(p)).length],
      [0, 1]
    );
  });

  test("Sad Path: an invalid list of people creates no group and no invite", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();
    const db = organization();
    const request = sendRequest({ groupId: undefined, firstGroupName: "Vendas", invites: [] });

    // 2. Act
    const error = await inviteErrorOf(() => sendInvites(centralDb, db, fakeMailer(), request));

    // 3. Assert
    assert.deepEqual(
      [error.code, invitesIn(centralDb).length, [...db.store.keys()].filter((p) => /groups\/[^/]+$/.test(p)).length],
      ["empty", 0, 1]
    );
  });
});

describe("listInvites - Unit Test Suite", () => {
  test("Happy Path: lists the pending invites of the group, not expired", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({
      "invites/a": pendingInvite(),
      "invites/b": pendingInvite({ groupId: "recepcao", groupName: "Recepção" }),
    });

    // 2. Act
    const invites = await listInvites(centralDb, "rotasul", "guias", NOW);

    // 3. Assert
    assert.deepEqual(
      invites.map((i) => [i.id, i.groupId, i.expiresAt, i.expired]),
      [["a", "guias", IN_14_DAYS, false]]
    );
  });

  test("Edge Case: an invite past its 14 days is listed as expired", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/a": pendingInvite() });

    // 2. Act
    const [invite] = await listInvites(centralDb, "rotasul", "guias", new Date(IN_14_DAYS));

    // 3. Assert
    assert.equal(invite.expired, true);
  });

  test("Sad Path: invites of another organization, cancelled or accepted are left out", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({
      "invites/a": pendingInvite({ organizationId: "outro" }),
      "invites/b": pendingInvite({ status: "cancelled" }),
      "invites/c": pendingInvite({ status: "accepted" }),
    });

    // 2. Act
    const invites = await listInvites(centralDb, "rotasul", "guias", NOW);

    // 3. Assert
    assert.deepEqual(invites, []);
  });
});

describe("myInvites (more) - Unit Test Suite", () => {
  test("Edge Case: an expired invite is not offered", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite({ expiresAt: NOW }) });

    // 2. Act
    const invites = await myInvites(centralDb, ANA, NOW);

    // 3. Assert
    assert.deepEqual(invites, []);
  });

  test("Sad Path: invites to someone else are not offered", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite({ email: VERA }) });

    // 2. Act
    const invites = await myInvites(centralDb, ANA, NOW);

    // 3. Assert
    assert.deepEqual(invites, []);
  });
});

describe("resendInvite and cancelInvite (more) - Unit Test Suite", () => {
  test("Happy Path: cancelling a pending invite of the organization marks it cancelled", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite() });

    // 2. Act
    await cancelInvite(centralDb, "i1", "rotasul");

    // 3. Assert
    assert.equal(centralDb.store.get("invites/i1").status, "cancelled");
  });

  test("Sad Path: an accepted invite cannot be resent", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite({ status: "accepted" }) });
    const mailer = fakeMailer();

    // 2. Act
    const error = await inviteErrorOf(() => resendInvite(centralDb, mailer, "i1", "rotasul", LATER));

    // 3. Assert
    assert.deepEqual([error.code, mailer.sent.length], ["invite", 0]);
  });
});

describe("acceptInvite (more) - Unit Test Suite", () => {
  test("Happy Path: the answer names the organization and the group", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite() });

    // 2. Act
    const result = await acceptInvite(centralDb, openerOf(organization()), "i1", ANA, NOW);

    // 3. Assert
    assert.deepEqual(
      [result.organizationId, result.groupId, result.groupName],
      ["rotasul", "guias", "Guias"]
    );
  });

  test("Edge Case: the existing accounts entry keeps its other organizations", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({
      "invites/i1": pendingInvite(),
      [`accounts/${personKey(ANA)}`]: { email: ANA, organizationIds: ["acme"] },
    });

    // 2. Act
    await acceptInvite(centralDb, openerOf(organization()), "i1", ANA, NOW);

    // 3. Assert
    assert.deepEqual(centralDb.store.get(`accounts/${personKey(ANA)}`).organizationIds, ["acme", "rotasul"]);
  });

  test("Sad Path: an invite of an organization that no longer opens throws group", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite({ organizationId: "outro" }) });

    // 2. Act
    const error = await inviteErrorOf(() => acceptInvite(centralDb, openerOf(organization()), "i1", ANA, NOW));

    // 3. Assert
    assert.deepEqual([error.code, centralDb.store.get("invites/i1").status], ["group", "pending"]);
  });

  test("Sad Path: an unknown invite id throws invite", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();

    // 2. Act
    const error = await inviteErrorOf(() => acceptInvite(centralDb, openerOf(organization()), "nope", ANA, NOW));

    // 3. Assert
    assert.equal(error.code, "invite");
  });
});

describe("inviteGroupId - Unit Test Suite", () => {
  test("Happy Path: gives the group of the organization's invite", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite() });

    // 2. Act
    const groupId = await inviteGroupId(centralDb, "i1", "rotasul");

    // 3. Assert
    assert.equal(groupId, "guias");
  });

  test("Edge Case: an invite without a group gives an empty id", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({ "invites/i1": pendingInvite({ groupId: undefined }) });

    // 2. Act
    const groupId = await inviteGroupId(centralDb, "i1", "rotasul");

    // 3. Assert
    assert.equal(groupId, "");
  });

  test("Sad Path: another organization's invite is refused with invite", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore({
      "invites/i1": pendingInvite({ organizationId: "verdemar" }),
    });

    // 2. Act
    const error = await inviteErrorOf(() => inviteGroupId(centralDb, "i1", "rotasul"));

    // 3. Assert
    assert.equal(error.code, "invite");
  });

  test("Sad Path: a missing invite is refused with invite", async () => {
    // 1. Arrange
    const centralDb = fakeFirestore();

    // 2. Act
    const error = await inviteErrorOf(() => inviteGroupId(centralDb, "i9", "rotasul"));

    // 3. Assert
    assert.equal(error.code, "invite");
  });
});
