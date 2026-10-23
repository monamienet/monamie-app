const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { TtlCache } = require("../ttl_cache");

/** A clock the test moves by hand. */
function fakeClock(start = 1000) {
  const clock = { time: start, now: () => clock.time };
  return clock;
}

/** A compute function that counts its calls and returns `value-<n>`. */
function counter() {
  const state = { calls: 0 };
  state.compute = async () => {
    state.calls += 1;
    return `value-${state.calls}`;
  };
  return state;
}

describe("TtlCache - Unit Test Suite", () => {
  test("Happy Path: computes and returns the value on a miss", async () => {
    // 1. Arrange
    const cache = new TtlCache(100, fakeClock().now);
    const source = counter();

    // 2. Act
    const value = await cache.getOrCompute("acme", source.compute);

    // 3. Assert
    assert.deepEqual([value, source.calls], ["value-1", 1]);
  });

  test("Happy Path: a hit within the TTL does not compute again", async () => {
    // 1. Arrange
    const clock = fakeClock();
    const cache = new TtlCache(100, clock.now);
    const source = counter();
    await cache.getOrCompute("acme", source.compute);
    clock.time += 99;

    // 2. Act
    const value = await cache.getOrCompute("acme", source.compute);

    // 3. Assert
    assert.deepEqual([value, source.calls], ["value-1", 1]);
  });

  test("Edge Case: an entry expires exactly at the TTL", async () => {
    // 1. Arrange
    const clock = fakeClock();
    const cache = new TtlCache(100, clock.now);
    const source = counter();
    await cache.getOrCompute("acme", source.compute);
    clock.time += 100;

    // 2. Act
    const value = await cache.getOrCompute("acme", source.compute);

    // 3. Assert
    assert.deepEqual([value, source.calls], ["value-2", 2]);
  });

  test("Edge Case: different keys are cached separately", async () => {
    // 1. Arrange
    const cache = new TtlCache(100, fakeClock().now);
    const source = counter();
    await cache.getOrCompute("acme", source.compute);

    // 2. Act
    const value = await cache.getOrCompute("beta", source.compute);

    // 3. Assert
    assert.deepEqual([value, source.calls], ["value-2", 2]);
  });

  test("Edge Case: falsy values are cached too", async () => {
    // 1. Arrange
    const cache = new TtlCache(100, fakeClock().now);
    let calls = 0;
    const compute = async () => {
      calls += 1;
      return 0;
    };
    await cache.getOrCompute("acme", compute);

    // 2. Act
    const value = await cache.getOrCompute("acme", compute);

    // 3. Assert
    assert.deepEqual([value, calls], [0, 1]);
  });

  test("Sad Path: a failure is passed on to the caller", async () => {
    // 1. Arrange
    const cache = new TtlCache(100, fakeClock().now);
    const compute = async () => {
      throw new Error("gateway down");
    };

    // 2. Act
    const result = cache.getOrCompute("acme", compute);

    // 3. Assert
    await assert.rejects(result, /gateway down/);
  });

  test("Sad Path: a failure is not cached", async () => {
    // 1. Arrange
    const cache = new TtlCache(100, fakeClock().now);
    await assert.rejects(
      cache.getOrCompute("acme", async () => {
        throw new Error("gateway down");
      })
    );
    const source = counter();

    // 2. Act
    const value = await cache.getOrCompute("acme", source.compute);

    // 3. Assert
    assert.deepEqual([value, source.calls], ["value-1", 1]);
  });
});
