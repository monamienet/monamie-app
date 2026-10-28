const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const { BrandingError, activeThemeIdsFrom, validateBranding } = require("../branding");

const themes = new Set(["grafite", "oceano"]);

/** The code of the BrandingError thrown by [action], or fails. */
function codeOf(action) {
  try {
    action();
  } catch (error) {
    assert.ok(error instanceof BrandingError, `expected a BrandingError, got ${error}`);
    return error.code;
  }
  assert.fail("expected a BrandingError");
}

describe("validateBranding - Unit Test Suite", () => {
  test("Happy Path: name, theme and logo together are kept", () => {
    // 1. Arrange
    const input = { name: "Rota Sul", themeId: "oceano", logo: "set" };

    // 2. Act
    const change = validateBranding(input, themes);

    // 3. Assert
    assert.deepEqual(change, { name: "Rota Sul", themeId: "oceano", logo: "set" });
  });

  const single = [
    ["Happy Path: a name alone is a change", { name: "Rota Sul" }, { name: "Rota Sul" }],
    ["Happy Path: a theme alone is a change", { themeId: "grafite" }, { themeId: "grafite" }],
    ['Happy Path: logo "set" alone is a change', { logo: "set" }, { logo: "set" }],
    ['Happy Path: logo "removed" alone is a change', { logo: "removed" }, { logo: "removed" }],
    [
      "Edge Case: the name is trimmed and inner whitespace collapsed",
      { name: "  Rota   Sul " },
      { name: "Rota Sul" },
    ],
    ["Edge Case: tabs and new lines collapse too", { name: "\tRota\n\nSul\t" }, { name: "Rota Sul" }],
    ["Edge Case: a name of exactly 2 characters is accepted", { name: "RS" }, { name: "RS" }],
    [
      "Edge Case: a name of exactly 40 characters is accepted",
      { name: "a".repeat(40) },
      { name: "a".repeat(40) },
    ],
    [
      "Edge Case: 40 characters after collapsing whitespace are accepted",
      { name: `  ${"a".repeat(19)}     ${"b".repeat(20)}  ` },
      { name: `${"a".repeat(19)} ${"b".repeat(20)}` },
    ],
    ['Edge Case: "MonAmieTur" (no space) is accepted', { name: "MonAmieTur" }, { name: "MonAmieTur" }],
    [
      'Edge Case: "MonAmie" later in the name is accepted',
      { name: "Rota MonAmie Sul" },
      { name: "Rota MonAmie Sul" },
    ],
  ];
  for (const [label, input, expected] of single) {
    test(label, () => {
      // 1. Arrange
      const body = input;

      // 2. Act
      const change = validateBranding(body, themes);

      // 3. Assert
      assert.deepEqual(change, expected);
    });
  }

  const rejected = [
    ["Sad Path: a name that is not a string", { name: 42 }, "name"],
    ["Sad Path: a null name", { name: null }, "name"],
    ["Sad Path: a blank name", { name: "   " }, "name"],
    ["Sad Path: a 1-character name", { name: "R" }, "name"],
    ["Sad Path: a 1-character name after trimming", { name: "  R  " }, "name"],
    ["Sad Path: a 41-character name", { name: "a".repeat(41) }, "name"],
    ['Sad Path: a name starting with "MonAmie "', { name: "MonAmie Rota Sul" }, "name"],
    ['Sad Path: the "MonAmie " prefix in any case', { name: "monAMIE Rota" }, "name"],
    ['Sad Path: "MonAmie" followed by a tab', { name: "MonAmie\tRota" }, "name"],
    ['Sad Path: "MonAmie " after leading spaces', { name: "   MonAmie Rota" }, "name"],
    ["Sad Path: a theme not in the catalog", { themeId: "neon" }, "themeId"],
    ["Sad Path: a theme that is not a string", { themeId: 7 }, "themeId"],
    ["Sad Path: an empty theme id", { themeId: "" }, "themeId"],
    ['Sad Path: logo "deleted"', { logo: "deleted" }, "logo"],
    ["Sad Path: logo true", { logo: true }, "logo"],
    ["Sad Path: logo null", { logo: null }, "logo"],
    ["Sad Path: an empty object", {}, "empty"],
    ["Sad Path: only unknown fields", { colors: { primary: "#0ABAB5" } }, "empty"],
    ["Sad Path: null input", null, "empty"],
    ["Sad Path: undefined input", undefined, "empty"],
  ];
  for (const [label, input, expected] of rejected) {
    test(`${label} throws code "${expected}"`, () => {
      // 1. Arrange
      const body = input;

      // 2. Act
      const code = codeOf(() => validateBranding(body, themes));

      // 3. Assert
      assert.equal(code, expected);
    });
  }

  test("Sad Path: a valid name does not excuse an invalid theme", () => {
    // 1. Arrange
    const input = { name: "Rota Sul", themeId: "neon" };

    // 2. Act
    const code = codeOf(() => validateBranding(input, themes));

    // 3. Assert
    assert.equal(code, "themeId");
  });

  test("Sad Path: no theme is valid when the catalog is empty", () => {
    // 1. Arrange
    const input = { themeId: "grafite" };

    // 2. Act
    const code = codeOf(() => validateBranding(input, new Set()));

    // 3. Assert
    assert.equal(code, "themeId");
  });
});

describe("activeThemeIdsFrom - Unit Test Suite", () => {
  const prefix = "projects/monamienet-app/databases/(default)/documents/themes";

  test("Happy Path: active and unflagged themes are listed, inactive ones are not", () => {
    // 1. Arrange
    const listing = {
      documents: [
        { name: `${prefix}/grafite`, fields: { active: { booleanValue: true } } },
        { name: `${prefix}/oceano`, fields: { name: { stringValue: "Oceano" } } },
        { name: `${prefix}/neon`, fields: { active: { booleanValue: false } } },
      ],
    };

    // 2. Act
    const ids = activeThemeIdsFrom(listing);

    // 3. Assert
    assert.deepEqual([...ids].sort(), ["grafite", "oceano"]);
  });

  test("Edge Case: a document without fields counts as active", () => {
    // 1. Arrange
    const listing = { documents: [{ name: `${prefix}/areia` }] };

    // 2. Act
    const ids = activeThemeIdsFrom(listing);

    // 3. Assert
    assert.deepEqual([...ids], ["areia"]);
  });

  for (const [label, listing] of [
    ["an empty documents list", { documents: [] }],
    ["a listing without documents", {}],
    ["null", null],
    ["undefined", undefined],
  ]) {
    test(`Sad Path: ${label} gives an empty set`, () => {
      // 1. Arrange
      const input = listing;

      // 2. Act
      const ids = activeThemeIdsFrom(input);

      // 3. Assert
      assert.equal(ids.size, 0);
    });
  }
});
