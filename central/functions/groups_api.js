const CLOUD_IDENTITY = "https://cloudidentity.googleapis.com/v1";
const GROUPS_SETTINGS = "https://www.googleapis.com/groups/v1/groups";

/** Scopes of the team functions' service account (groups-admin@). */
const GROUPS_SCOPES = [
  "https://www.googleapis.com/auth/cloud-identity.groups",
  "https://www.googleapis.com/auth/apps.groups.settings",
];

/**
 * The Cloud Identity Groups and Groups Settings calls the team functions
 * make, over an authorized `request({url, method, data})` that resolves to
 * the response body (google-auth-library's client.request, unwrapped).
 *
 * The caller (the groups-admin@ service account) holds the Workspace
 * "Groups Administrator" admin role, assigned to it directly, without
 * domain-wide delegation.
 */
class GroupsApi {
  /** @param {(options: object) => Promise<any>} request */
  constructor(request) {
    this._request = request;
  }

  /**
   * The resource name (`groups/…`) of the group `email`, or null.
   *
   * Cloud Identity answers 403 "Permission denied … (or it may not exist)"
   * for a group that does not exist, so 403 counts as missing like 404; a
   * real permission problem then shows up on the next call (the create).
   */
  async lookup(email) {
    try {
      const body = await this._request({
        url: `${CLOUD_IDENTITY}/groups:lookup?groupKey.id=${encodeURIComponent(email)}`,
      });
      return body?.name ?? null;
    } catch (error) {
      const status = error?.response?.status ?? error?.code;
      if (status === 404 || status === 403) return null;
      throw error;
    }
  }

  /** The group `name` (`groups/…`): displayName, parent (customer), createTime. */
  get(name) {
    return this._request({ url: `${CLOUD_IDENTITY}/${name}` });
  }

  /**
   * Creates the group `email` with no initial owner, in `customer`
   * (`customers/…`). Returns its resource name.
   */
  async create(email, displayName, customer) {
    const operation = await this._request({
      url: `${CLOUD_IDENTITY}/groups?initialGroupConfig=EMPTY`,
      method: "POST",
      data: {
        parent: customer,
        groupKey: { id: email },
        displayName,
        labels: { "cloudidentity.googleapis.com/groups.discussion_forum": "" },
      },
    });
    return operation?.response?.name ?? (await this.lookup(email));
  }

  /** Lets people outside the organization join, and nobody but the
   * service account manage members (groups.google.com included). */
  setMonAmieSettings(email) {
    return this._request({
      url: `${GROUPS_SETTINGS}/${encodeURIComponent(email)}?alt=json`,
      method: "PATCH",
      data: { allowExternalMembers: "true", whoCanModerateMembers: "NONE" },
    });
  }

  rename(name, displayName) {
    return this._request({
      url: `${CLOUD_IDENTITY}/${name}?updateMask=displayName`,
      method: "PATCH",
      data: { displayName },
    });
  }

  delete(name) {
    return this._request({ url: `${CLOUD_IDENTITY}/${name}`, method: "DELETE" });
  }

  /** Direct members of group `name`: `[{email, type}]` (USER, GROUP…). */
  async members(name) {
    const members = [];
    let pageToken = "";
    do {
      const body = await this._request({
        url:
          `${CLOUD_IDENTITY}/${name}/memberships?view=FULL&pageSize=200` +
          (pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : ""),
      });
      for (const m of body?.memberships ?? []) {
        const email = m?.preferredMemberKey?.id;
        if (email) members.push({ email: email.toLowerCase(), type: m.type });
      }
      pageToken = body?.nextPageToken ?? "";
    } while (pageToken);
    return members;
  }

  /** Adds `email` (a person or a group) to group `name` as a MEMBER. An
   * existing membership counts as done. */
  async addMember(name, email) {
    try {
      await this._request({
        url: `${CLOUD_IDENTITY}/${name}/memberships`,
        method: "POST",
        data: { preferredMemberKey: { id: email }, roles: [{ name: "MEMBER" }] },
      });
    } catch (error) {
      if (error?.response?.status !== 409 && error?.code !== 409) throw error;
    }
  }

  /** Removes `email` from group `name`. A missing membership counts as
   * done. */
  async removeMember(name, email) {
    let membership;
    try {
      membership = await this._request({
        url: `${CLOUD_IDENTITY}/${name}/memberships:lookup?memberKey.id=${encodeURIComponent(email)}`,
      });
    } catch (error) {
      if (error?.response?.status === 404 || error?.code === 404) return;
      throw error;
    }
    if (membership?.name) {
      await this._request({ url: `${CLOUD_IDENTITY}/${membership.name}`, method: "DELETE" });
    }
  }
}

module.exports = { GROUPS_SCOPES, GroupsApi };
