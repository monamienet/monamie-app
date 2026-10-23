const { describe, test } = require("node:test");
const assert = require("node:assert/strict");

const {
  PartnerOptionsReader,
  androidOptionsFromGoogleServices,
  webOptionsFromSdkConfig,
  projectIdFor,
} = require("../partner_options");

const API = "https://firebase.googleapis.com/v1beta1";
const APP_PACKAGE = "org.monamienet.app";

/** A google-services.json of partner `id` with the MonAmie client. */
function googleServices(id, { storageBucket = true } = {}) {
  return {
    project_info: {
      project_number: "111",
      project_id: `monamienet-${id}`,
      ...(storageBucket
        ? { storage_bucket: `monamienet-${id}.firebasestorage.app` }
        : {}),
    },
    client: [
      {
        client_info: {
          mobilesdk_app_id: "1:111:android:other",
          android_client_info: { package_name: "org.example.other" },
        },
        api_key: [{ current_key: "other-key" }],
      },
      {
        client_info: {
          mobilesdk_app_id: `1:111:android:${id}`,
          android_client_info: { package_name: APP_PACKAGE },
        },
        api_key: [{ current_key: `key-${id}` }],
      },
    ],
  };
}

/** The web SDK config of partner `id`. */
function webSdkConfig(id) {
  return {
    apiKey: `web-key-${id}`,
    appId: `1:111:web:${id}`,
    projectId: `monamienet-${id}`,
    messagingSenderId: "111",
    authDomain: `monamienet-${id}.firebaseapp.com`,
    storageBucket: `monamienet-${id}.firebasestorage.app`,
    measurementId: "G-XXXX",
  };
}

/**
 * A fake Management API: answers each URL from `responses` and records the
 * requested URLs in `calls`.
 */
function fakeApi(responses) {
  const api = { calls: [] };
  api.getJson = async (url) => {
    api.calls.push(url);
    if (!(url in responses)) throw new Error(`unexpected GET ${url}`);
    return responses[url];
  };
  return api;
}

/** Management API responses for partner `id` on both platforms. */
function partnerResponses(id, { androidApps, webApps } = {}) {
  const config = Buffer.from(JSON.stringify(googleServices(id))).toString(
    "base64"
  );
  return {
    [`${API}/projects/monamienet-${id}/androidApps`]: {
      apps: androidApps ?? [
        { appId: "1:111:android:other", packageName: "org.example.other" },
        { appId: `1:111:android:${id}`, packageName: APP_PACKAGE },
      ],
    },
    [`${API}/projects/-/androidApps/1:111:android:${id}/config`]: {
      configFilename: "google-services.json",
      configFileContents: config,
    },
    [`${API}/projects/monamienet-${id}/webApps`]: {
      apps: webApps ?? [{ appId: `1:111:web:${id}` }],
    },
    [`${API}/projects/-/webApps/1:111:web:${id}/config`]: webSdkConfig(id),
  };
}

function fakeClock(start = 1000) {
  const clock = { time: start, now: () => clock.time };
  return clock;
}

describe("projectIdFor - Unit Test Suite", () => {
  test("Happy Path: the partner project is monamienet-<id>", () => {
    // 1. Arrange
    const id = "aquariustur";

    // 2. Act
    const projectId = projectIdFor(id);

    // 3. Assert
    assert.equal(projectId, "monamienet-aquariustur");
  });
});

describe("androidOptionsFromGoogleServices - Unit Test Suite", () => {
  test("Happy Path: reads the options of the MonAmie client", () => {
    // 1. Arrange
    const config = googleServices("acme");

    // 2. Act
    const options = androidOptionsFromGoogleServices(config);

    // 3. Assert
    assert.deepEqual(options, {
      apiKey: "key-acme",
      appId: "1:111:android:acme",
      projectId: "monamienet-acme",
      messagingSenderId: "111",
      storageBucket: "monamienet-acme.firebasestorage.app",
    });
  });

  test("Edge Case: a project without storage bucket leaves it out", () => {
    // 1. Arrange
    const config = googleServices("acme", { storageBucket: false });

    // 2. Act
    const options = androidOptionsFromGoogleServices(config);

    // 3. Assert
    assert.equal("storageBucket" in options, false);
  });

  test("Sad Path: no client for the MonAmie package throws", () => {
    // 1. Arrange
    const config = googleServices("acme");
    config.client = config.client.slice(0, 1);

    // 2. Act
    const action = () => androidOptionsFromGoogleServices(config);

    // 3. Assert
    assert.throws(action, /no complete client for org\.monamienet\.app/);
  });

  test("Sad Path: a client without API key throws", () => {
    // 1. Arrange
    const config = googleServices("acme");
    config.client[1].api_key = [];

    // 2. Act
    const action = () => androidOptionsFromGoogleServices(config);

    // 3. Assert
    assert.throws(action, Error);
  });

  test("Sad Path: a client without app id throws", () => {
    // 1. Arrange
    const config = googleServices("acme");
    delete config.client[1].client_info.mobilesdk_app_id;

    // 2. Act
    const action = () => androidOptionsFromGoogleServices(config);

    // 3. Assert
    assert.throws(action, Error);
  });

  test("Sad Path: a file without project number throws", () => {
    // 1. Arrange
    const config = googleServices("acme");
    delete config.project_info.project_number;

    // 2. Act
    const action = () => androidOptionsFromGoogleServices(config);

    // 3. Assert
    assert.throws(action, Error);
  });

  test("Sad Path: a file without project id throws", () => {
    // 1. Arrange
    const config = googleServices("acme");
    delete config.project_info.project_id;

    // 2. Act
    const action = () => androidOptionsFromGoogleServices(config);

    // 3. Assert
    assert.throws(action, Error);
  });

  test("Sad Path: null throws", () => {
    // 1. Arrange
    const config = null;

    // 2. Act
    const action = () => androidOptionsFromGoogleServices(config);

    // 3. Assert
    assert.throws(action, Error);
  });
});

describe("webOptionsFromSdkConfig - Unit Test Suite", () => {
  test("Happy Path: keeps only the FirebaseOptions fields", () => {
    // 1. Arrange
    const config = webSdkConfig("acme");

    // 2. Act
    const options = webOptionsFromSdkConfig(config);

    // 3. Assert
    assert.deepEqual(options, {
      apiKey: "web-key-acme",
      appId: "1:111:web:acme",
      projectId: "monamienet-acme",
      messagingSenderId: "111",
      authDomain: "monamienet-acme.firebaseapp.com",
      storageBucket: "monamienet-acme.firebasestorage.app",
    });
  });

  test("Edge Case: absent or empty optional fields are left out", () => {
    // 1. Arrange
    const config = { ...webSdkConfig("acme"), storageBucket: "" };
    delete config.authDomain;

    // 2. Act
    const options = webOptionsFromSdkConfig(config);

    // 3. Assert
    assert.deepEqual(Object.keys(options), [
      "apiKey",
      "appId",
      "projectId",
      "messagingSenderId",
    ]);
  });

  for (const field of ["apiKey", "appId", "projectId", "messagingSenderId"]) {
    test(`Sad Path: a config without ${field} throws`, () => {
      // 1. Arrange
      const config = webSdkConfig("acme");
      delete config[field];

      // 2. Act
      const action = () => webOptionsFromSdkConfig(config);

      // 3. Assert
      assert.throws(action, /missing a required field/);
    });
  }

  test("Sad Path: undefined throws", () => {
    // 1. Arrange
    const config = undefined;

    // 2. Act
    const action = () => webOptionsFromSdkConfig(config);

    // 3. Assert
    assert.throws(action, /missing a required field/);
  });
});

describe("PartnerOptionsReader - Unit Test Suite", () => {
  test("Happy Path: android reads the options from the app config file", async () => {
    // 1. Arrange
    const api = fakeApi(partnerResponses("acme"));
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });

    // 2. Act
    const options = await reader.get("acme", "android");

    // 3. Assert
    assert.deepEqual(options, androidOptionsFromGoogleServices(googleServices("acme")));
  });

  test("Happy Path: android lists the apps and reads the MonAmie app config", async () => {
    // 1. Arrange
    const api = fakeApi(partnerResponses("acme"));
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });

    // 2. Act
    await reader.get("acme", "android");

    // 3. Assert
    assert.deepEqual(api.calls, [
      `${API}/projects/monamienet-acme/androidApps`,
      `${API}/projects/-/androidApps/1:111:android:acme/config`,
    ]);
  });

  test("Happy Path: web reads the options from the web app config", async () => {
    // 1. Arrange
    const api = fakeApi(partnerResponses("acme"));
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });

    // 2. Act
    const options = await reader.get("acme", "web");

    // 3. Assert
    assert.deepEqual(options, webOptionsFromSdkConfig(webSdkConfig("acme")));
  });

  test("Happy Path: a second read within the TTL is served from the cache", async () => {
    // 1. Arrange
    const clock = fakeClock();
    const api = fakeApi(partnerResponses("acme"));
    const reader = new PartnerOptionsReader(api.getJson, {
      ttlMs: 1000,
      now: clock.now,
    });
    const first = await reader.get("acme", "web");
    clock.time += 999;

    // 2. Act
    const second = await reader.get("acme", "web");

    // 3. Assert
    assert.deepEqual([second, api.calls.length], [first, 2]);
  });

  test("Edge Case: an expired entry is read again", async () => {
    // 1. Arrange
    const clock = fakeClock();
    const api = fakeApi(partnerResponses("acme"));
    const reader = new PartnerOptionsReader(api.getJson, {
      ttlMs: 1000,
      now: clock.now,
    });
    await reader.get("acme", "web");
    clock.time += 1000;

    // 2. Act
    await reader.get("acme", "web");

    // 3. Assert
    assert.equal(api.calls.length, 4);
  });

  test("Edge Case: android and web are cached separately", async () => {
    // 1. Arrange
    const api = fakeApi(partnerResponses("acme"));
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });
    await reader.get("acme", "android");

    // 2. Act
    const options = await reader.get("acme", "web");

    // 3. Assert
    assert.deepEqual(
      [options.appId, api.calls.length],
      ["1:111:web:acme", 4]
    );
  });

  test("Edge Case: partners are cached separately", async () => {
    // 1. Arrange
    const api = fakeApi({
      ...partnerResponses("acme"),
      ...partnerResponses("beta"),
    });
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });
    await reader.get("acme", "web");

    // 2. Act
    const options = await reader.get("beta", "web");

    // 3. Assert
    assert.equal(options.projectId, "monamienet-beta");
  });

  test("Sad Path: no MonAmie Android app throws", async () => {
    // 1. Arrange
    const api = fakeApi(
      partnerResponses("acme", {
        androidApps: [
          { appId: "1:111:android:other", packageName: "org.example.other" },
        ],
      })
    );
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });

    // 2. Act
    const result = reader.get("acme", "android");

    // 3. Assert
    await assert.rejects(result, /monamienet-acme has 0 Android apps/);
  });

  test("Sad Path: two MonAmie Android apps throw", async () => {
    // 1. Arrange
    const api = fakeApi(
      partnerResponses("acme", {
        androidApps: [
          { appId: "1:111:android:acme", packageName: APP_PACKAGE },
          { appId: "1:111:android:dup", packageName: APP_PACKAGE },
        ],
      })
    );
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });

    // 2. Act
    const result = reader.get("acme", "android");

    // 3. Assert
    await assert.rejects(result, /has 2 Android apps/);
  });

  test("Sad Path: no web app throws", async () => {
    // 1. Arrange
    const api = fakeApi(partnerResponses("acme", { webApps: [] }));
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });

    // 2. Act
    const result = reader.get("acme", "web");

    // 3. Assert
    await assert.rejects(result, /monamienet-acme has 0 web apps/);
  });

  test("Sad Path: two web apps throw", async () => {
    // 1. Arrange
    const api = fakeApi(
      partnerResponses("acme", {
        webApps: [{ appId: "1:111:web:acme" }, { appId: "1:111:web:old" }],
      })
    );
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });

    // 2. Act
    const result = reader.get("acme", "web");

    // 3. Assert
    await assert.rejects(result, /has 2 web apps/);
  });

  test("Sad Path: a list response without apps counts as zero apps", async () => {
    // 1. Arrange
    const api = fakeApi({
      [`${API}/projects/monamienet-acme/webApps`]: {},
    });
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });

    // 2. Act
    const result = reader.get("acme", "web");

    // 3. Assert
    await assert.rejects(result, /has 0 web apps/);
  });

  test("Sad Path: a failed read is not cached", async () => {
    // 1. Arrange
    const responses = partnerResponses("acme", { webApps: [] });
    const api = fakeApi(responses);
    const reader = new PartnerOptionsReader(api.getJson, {
      now: fakeClock().now,
    });
    await assert.rejects(reader.get("acme", "web"));
    responses[`${API}/projects/monamienet-acme/webApps`] = {
      apps: [{ appId: "1:111:web:acme" }],
    };

    // 2. Act
    const options = await reader.get("acme", "web");

    // 3. Assert
    assert.equal(options.appId, "1:111:web:acme");
  });
});
