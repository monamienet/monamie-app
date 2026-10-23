const APP_PACKAGE = "org.monamienet.app";
const API = "https://firebase.googleapis.com/v1beta1";

/**
 * The Firebase project of partner `id`.
 *
 * @param {string} id - Partner id
 * @returns {string} Project id
 */
function projectIdFor(id) {
  return `monamienet-${id}`;
}

/**
 * Turns an Android `google-services.json` into the FirebaseOptions fields
 * the app needs, for the client with package `org.monamienet.app`.
 *
 * @param {object} config - Parsed google-services.json
 * @returns {object} apiKey, appId, projectId, messagingSenderId, storageBucket
 * @throws {Error} If the file has no usable client for the package
 */
function androidOptionsFromGoogleServices(config) {
  const info = config?.project_info ?? {};
  const client = (config?.client ?? []).find(
    (c) => c?.client_info?.android_client_info?.package_name === APP_PACKAGE
  );
  const apiKey = client?.api_key?.[0]?.current_key;
  const appId = client?.client_info?.mobilesdk_app_id;
  if (!client || !apiKey || !appId || !info.project_id || !info.project_number) {
    throw new Error(
      `google-services.json has no complete client for ${APP_PACKAGE}.`
    );
  }
  return {
    apiKey,
    appId,
    projectId: info.project_id,
    messagingSenderId: info.project_number,
    ...(info.storage_bucket ? { storageBucket: info.storage_bucket } : {}),
  };
}

/**
 * Keeps the FirebaseOptions fields the app uses from a web SDK config.
 *
 * @param {object} config - Web app config from the Management API
 * @returns {object} FirebaseOptions fields
 * @throws {Error} If a required field is missing
 */
function webOptionsFromSdkConfig(config) {
  const { apiKey, appId, projectId, messagingSenderId } = config ?? {};
  if (!apiKey || !appId || !projectId || !messagingSenderId) {
    throw new Error("Web app config is missing a required field.");
  }
  return {
    apiKey,
    appId,
    projectId,
    messagingSenderId,
    ...(config.authDomain ? { authDomain: config.authDomain } : {}),
    ...(config.storageBucket ? { storageBucket: config.storageBucket } : {}),
  };
}

/**
 * Reads partners' FirebaseOptions from the Firebase Management API, caching
 * each (partner, platform) pair for `ttlMs`.
 *
 * The function's service account only needs the custom role
 * `firebaseAppConfigReader` (firebase.clients.list + firebase.clients.get)
 * on each partner project: the two calls made here.
 */
class PartnerOptionsReader {
  /**
   * @param {(url: string) => Promise<object>} getJson - Authorized GET
   * @param {{ttlMs?: number, now?: () => number}} [options]
   */
  constructor(getJson, { ttlMs = 60 * 60 * 1000, now = Date.now } = {}) {
    this._getJson = getJson;
    this._ttlMs = ttlMs;
    this._now = now;
    this._cache = new Map();
  }

  /**
   * @param {string} id - Partner id
   * @param {"android"|"web"} platform - Platform of the caller
   * @returns {Promise<object>} FirebaseOptions fields
   */
  async get(id, platform) {
    const key = `${id}/${platform}`;
    const cached = this._cache.get(key);
    if (cached && cached.expires > this._now()) return cached.value;
    const value =
      platform === "android" ? await this._android(id) : await this._web(id);
    this._cache.set(key, { value, expires: this._now() + this._ttlMs });
    return value;
  }

  async _android(id) {
    const list = await this._getJson(
      `${API}/projects/${projectIdFor(id)}/androidApps`
    );
    const apps = (list.apps ?? []).filter((a) => a.packageName === APP_PACKAGE);
    if (apps.length !== 1) {
      throw new Error(
        `${projectIdFor(id)} has ${apps.length} Android apps for ${APP_PACKAGE}.`
      );
    }
    const config = await this._getJson(
      `${API}/projects/-/androidApps/${apps[0].appId}/config`
    );
    const json = Buffer.from(config.configFileContents ?? "", "base64").toString(
      "utf8"
    );
    return androidOptionsFromGoogleServices(JSON.parse(json));
  }

  async _web(id) {
    const list = await this._getJson(
      `${API}/projects/${projectIdFor(id)}/webApps`
    );
    const apps = list.apps ?? [];
    if (apps.length !== 1) {
      throw new Error(`${projectIdFor(id)} has ${apps.length} web apps.`);
    }
    return webOptionsFromSdkConfig(
      await this._getJson(`${API}/projects/-/webApps/${apps[0].appId}/config`)
    );
  }
}

module.exports = {
  PartnerOptionsReader,
  androidOptionsFromGoogleServices,
  webOptionsFromSdkConfig,
  projectIdFor,
};
