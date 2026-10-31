const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { GroupError } = require("../group_service");
const {
  accessFrom,
  canManageGroup,
  managerAccess,
  requireManagesGroup,
  requireMayInvite,
  visibleGroups,
} = require("../group_access");
const { personKey } = require("../person_key");
const { fakeFirestore } = require("./fake_firestore");

const ORG = "organizations/rotasul";
const OLGA = "olga@x.com";
const VERA = "vera@x.com";
const ANA = "ana@x.com";

/** Vera maintains guias. */
const MAINTAINER = Object.freeze({ admin: false, maintainedGroupIds: ["guias"] });
const ADMIN = Object.freeze({ admin: true, maintainedGroupIds: [] });

function codeOf(act) {
  try {
    act();
  } catch (error) {
    assert.ok(error instanceof GroupError, `expected GroupError, got ${error}`);
    return error.code;
  }
  return null;
}

describe("accessFrom - Unit Test Suite", () => {
  test("Happy Path: a maintainer manages only the groups they maintain", () => {
    // 1. Arrange
    const memberships = [
      { groupId: "recepcao", roles: ["publisher"] },
      { groupId: "guias", roles: ["maintainer", "subscriber"] },
    ];

    // 2. Act
    const access = accessFrom({ role: "member" }, memberships);

    // 3. Assert
    assert.deepEqual(access, { admin: false, maintainedGroupIds: ["guias"] });
  });

  test("Edge Case: an administrator manages every group", () => {
    // 1. Arrange
    const membership = { role: "admin" };

    // 2. Act
    const access = accessFrom(membership, []);

    // 3. Assert
    assert.deepEqual(access, { admin: true, maintainedGroupIds: [] });
  });

  test("Sad Path: a member who maintains no group manages nothing", () => {
    // 1. Arrange
    const memberships = [{ groupId: "guias", roles: ["publisher", "subscriber"] }];

    // 2. Act
    const access = accessFrom({ role: "member" }, memberships);

    // 3. Assert
    assert.equal(access, null);
  });
});

describe("accessFrom (more) - Unit Test Suite", () => {
  test("Happy Path: the maintained groups come sorted", () => {
    // 1. Arrange
    const memberships = [
      { groupId: "recepcao", roles: ["maintainer"] },
      { groupId: "bar", roles: ["maintainer", "publisher"] },
    ];

    // 2. Act
    const access = accessFrom({ role: "member" }, memberships);

    // 3. Assert
    assert.deepEqual(access.maintainedGroupIds, ["bar", "recepcao"]);
  });

  test("Sad Path: someone with no organization membership manages nothing", () => {
    // 1. Arrange
    const memberships = [{ groupId: "guias", roles: ["maintainer"] }];

    // 2. Act
    const access = accessFrom(null, memberships);

    // 3. Assert
    assert.equal(access, null);
  });
});

describe("canManageGroup - Unit Test Suite", () => {
  test("Happy Path: a maintainer manages the group they maintain", () => {
    // 1. Arrange
    const access = MAINTAINER;

    // 2. Act
    const result = canManageGroup(access, "guias");

    // 3. Assert
    assert.equal(result, true);
  });

  test("Edge Case: an administrator manages a group they are not in", () => {
    // 1. Arrange
    const access = ADMIN;

    // 2. Act
    const result = canManageGroup(access, "recepcao");

    // 3. Assert
    assert.equal(result, true);
  });

  test("Sad Path: a maintainer does not manage another group", () => {
    // 1. Arrange
    const access = MAINTAINER;

    // 2. Act
    const result = canManageGroup(access, "recepcao");

    // 3. Assert
    assert.equal(result, false);
  });

  test("Sad Path: no access manages nothing", () => {
    // 1. Arrange
    const access = null;

    // 2. Act
    const result = canManageGroup(access, "guias");

    // 3. Assert
    assert.equal(result, false);
  });
});

describe("requireManagesGroup - Unit Test Suite", () => {
  test("Happy Path: the maintainer's own group passes", () => {
    // 1. Arrange
    const access = MAINTAINER;

    // 2. Act
    const code = codeOf(() => requireManagesGroup(access, "guias"));

    // 3. Assert
    assert.equal(code, null);
  });

  test("Edge Case: a missing group id is refused with forbidden", () => {
    // 1. Arrange
    const access = MAINTAINER;

    // 2. Act
    const code = codeOf(() => requireManagesGroup(access, null));

    // 3. Assert
    assert.equal(code, "forbidden");
  });

  test("Sad Path: another group is refused with forbidden", () => {
    // 1. Arrange
    const access = MAINTAINER;

    // 2. Act
    const code = codeOf(() => requireManagesGroup(access, "recepcao"));

    // 3. Assert
    assert.equal(code, "forbidden");
  });
});

describe("visibleGroups - Unit Test Suite", () => {
  const groups = [{ id: "bar" }, { id: "guias" }, { id: "recepcao" }];

  test("Happy Path: a maintainer sees only the groups they maintain", () => {
    // 1. Arrange
    const access = MAINTAINER;

    // 2. Act
    const visible = visibleGroups(access, groups);

    // 3. Assert
    assert.deepEqual(visible, [{ id: "guias" }]);
  });

  test("Edge Case: an administrator sees every group", () => {
    // 1. Arrange
    const access = ADMIN;

    // 2. Act
    const visible = visibleGroups(access, groups);

    // 3. Assert
    assert.deepEqual(visible, groups);
  });

  test("Sad Path: no access sees no group", () => {
    // 1. Arrange
    const access = null;

    // 2. Act
    const visible = visibleGroups(access, groups);

    // 3. Assert
    assert.deepEqual(visible, []);
  });
});

describe("requireMayInvite - Unit Test Suite", () => {
  test("Happy Path: a maintainer invites to the group they maintain", () => {
    // 1. Arrange
    const request = { groupId: "guias" };

    // 2. Act
    const code = codeOf(() => requireMayInvite(MAINTAINER, request));

    // 3. Assert
    assert.equal(code, null);
  });

  test("Edge Case: an administrator may create the first group with the invites", () => {
    // 1. Arrange
    const request = { firstGroupName: "Guias" };

    // 2. Act
    const code = codeOf(() => requireMayInvite(ADMIN, request));

    // 3. Assert
    assert.equal(code, null);
  });

  test("Sad Path: a maintainer cannot create the first group", () => {
    // 1. Arrange
    const request = { groupId: "guias", firstGroupName: "Bar" };

    // 2. Act
    const code = codeOf(() => requireMayInvite(MAINTAINER, request));

    // 3. Assert
    assert.equal(code, "forbidden");
  });

  test("Sad Path: a maintainer cannot invite to another group", () => {
    // 1. Arrange
    const request = { groupId: "recepcao" };

    // 2. Act
    const code = codeOf(() => requireMayInvite(MAINTAINER, request));

    // 3. Assert
    assert.equal(code, "forbidden");
  });

  test("Sad Path: a maintainer must name a group", () => {
    // 1. Arrange
    const request = {};

    // 2. Act
    const code = codeOf(() => requireMayInvite(MAINTAINER, request));

    // 3. Assert
    assert.equal(code, "forbidden");
  });
});

describe("managerAccess - Unit Test Suite", () => {
  /** Rota Sul: Olga administers it, Vera maintains guias, Ana publishes there. */
  function organization() {
    const member = (email, role) => ({
      [`${ORG}/organizationMemberships/${personKey(email)}`]: { email, role },
    });
    const inGuias = (email, roles) => ({
      [`${ORG}/groups/guias/groupMemberships/${personKey(email)}`]: {
        email,
        organizationId: "rotasul",
        roles,
      },
    });
    return fakeFirestore({
      [`${ORG}/groups/guias`]: { name: "Guias" },
      ...member(OLGA, "admin"),
      ...member(VERA, "member"),
      ...member(ANA, "member"),
      ...inGuias(VERA, ["maintainer", "subscriber"]),
      ...inGuias(ANA, ["publisher"]),
    });
  }

  /** Opens `db` as organization rotasul with registry `status`. */
  const openerOf = (db, status = "active") => async (id) =>
    id === "rotasul" ? { db, registry: { status } } : null;

  test("Happy Path: a maintainer gets the organization and the groups they maintain", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const access = await managerAccess(openerOf(db), "rotasul", VERA);

    // 3. Assert
    assert.deepEqual(access, { db, admin: false, maintainedGroupIds: ["guias"] });
  });

  test("Edge Case: an administrator in no group manages every group", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const access = await managerAccess(openerOf(db), "rotasul", OLGA);

    // 3. Assert
    assert.deepEqual(access, { db, admin: true, maintainedGroupIds: [] });
  });

  test("Sad Path: a member who maintains no group gets nothing", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const access = await managerAccess(openerOf(db), "rotasul", ANA);

    // 3. Assert
    assert.equal(access, null);
  });

  test("Sad Path: an organization that is not active grants nothing", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const access = await managerAccess(openerOf(db, "deleting"), "rotasul", OLGA);

    // 3. Assert
    assert.equal(access, null);
  });

  test("Sad Path: an unknown organization grants nothing", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const access = await managerAccess(openerOf(db), "verdemar", OLGA);

    // 3. Assert
    assert.equal(access, null);
  });

  test("Sad Path: a call without an e-mail grants nothing", async () => {
    // 1. Arrange
    const db = organization();

    // 2. Act
    const access = await managerAccess(openerOf(db), "rotasul", "");

    // 3. Assert
    assert.equal(access, null);
  });
});
