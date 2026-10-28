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
