const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { GroupsApi } = require("../groups_api");

/** A `request` that rejects every call with an HTTP `status`. */
function rejectingWith(status) {
  return async () => {
    throw Object.assign(new Error(`HTTP ${status}`), { response: { status } });
  };
}

describe("GroupsApi.lookup - Unit Test Suite", () => {
  test("Happy Path: returns the resource name of an existing group", async () => {
    // 1. Arrange
    const api = new GroupsApi(async () => ({ name: "groups/abc123" }));

    // 2. Act
    const name = await api.lookup("rotasul00@monamienet.org");

    // 3. Assert
    assert.equal(name, "groups/abc123");
  });

  for (const status of [404, 403]) {
    test(`Edge Case: HTTP ${status} means the group is missing (null)`, async () => {
      // 1. Arrange
      const api = new GroupsApi(rejectingWith(status));

      // 2. Act
      const name = await api.lookup("rotasul00@monamienet.org");

      // 3. Assert
      assert.equal(name, null);
    });
  }

  test("Sad Path: HTTP 500 is rethrown", async () => {
    // 1. Arrange
    const api = new GroupsApi(rejectingWith(500));

    // 2. Act
    const lookup = api.lookup("rotasul00@monamienet.org");

    // 3. Assert
    await assert.rejects(lookup, (error) => error.response.status === 500);
  });
});

describe("GroupsApi.isMember - Unit Test Suite", () => {
  test("Happy Path: a membership found means the person is a member", async () => {
    // 1. Arrange
    const api = new GroupsApi(async () => ({ name: "groups/abc123/memberships/m1" }));

    // 2. Act
    const isMember = await api.isMember("groups/abc123", "ana@x.com");

    // 3. Assert
    assert.equal(isMember, true);
  });

  test("Edge Case: the lookup asks the group for the URL-encoded e-mail", async () => {
    // 1. Arrange
    const urls = [];
    const api = new GroupsApi(async ({ url }) => {
      urls.push(url);
      return { name: "groups/abc123/memberships/m1" };
    });

    // 2. Act
    await api.isMember("groups/abc123", "ana+obra@x.com");

    // 3. Assert
    assert.equal(urls.length, 1);
    assert.match(urls[0], /\/groups\/abc123\/memberships:lookup\?memberKey\.id=ana%2Bobra%40x\.com$/);
  });

  test("Edge Case: HTTP 404 means the person is not a member", async () => {
    // 1. Arrange
    const api = new GroupsApi(rejectingWith(404));

    // 2. Act
    const isMember = await api.isMember("groups/abc123", "ana@x.com");

    // 3. Assert
    assert.equal(isMember, false);
  });

  for (const status of [403, 500]) {
    test(`Sad Path: HTTP ${status} is rethrown`, async () => {
      // 1. Arrange
      const api = new GroupsApi(rejectingWith(status));

      // 2. Act
      const isMember = api.isMember("groups/abc123", "ana@x.com");

      // 3. Assert
      await assert.rejects(isMember, (error) => error.response.status === status);
    });
  }
});
