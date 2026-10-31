const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { personKey } = require("../person_key");

/** sha256 of "ana@example.com", computed once with `sha256sum` (the
 * contract's fixed vector, shared with the rules and the Dart twin). */
const ANA_KEY = "8e43ca37701228e74983efdbd0cff5c16b3b1e5d4e29a7c05626d4d25a018e11";

describe("personKey - Unit Test Suite", () => {
  test("Happy Path: an e-mail gives the fixed known key", () => {
    // 1. Arrange
    const email = "ana@example.com";

    // 2. Act
    const key = personKey(email);

    // 3. Assert
    assert.equal(key, ANA_KEY);
  });

  test("Edge Case: case and surrounding spaces do not change the key", () => {
    // 1. Arrange
    const email = "  Ana@Example.COM ";

    // 2. Act
    const key = personKey(email);

    // 3. Assert
    assert.equal(key, ANA_KEY);
  });

  test("Sad Path: another e-mail gives another key", () => {
    // 1. Arrange
    const email = "ana@example.org";

    // 2. Act
    const key = personKey(email);

    // 3. Assert
    assert.notEqual(key, ANA_KEY);
  });
});
