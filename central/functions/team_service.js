const { parseGroupAddress } = require("./group_address");
const {
  TeamError,
  nextTeamNumber,
  roleChanges,
  teamGroupEmails,
  validateRoles,
  validateTeamName,
  whoLosesAccess,
} = require("./teams");

/**
 * The partner's teams with their people, read from the groups:
 * `[{team, key, email, name, people: [{email, roles}]}]`, by team number.
 *
 * @param {import("./groups_api").GroupsApi} api
 * @param {string} partnerId
 */
async function listTeams(api, partnerId) {
  const root = await api.lookup(`${partnerId}00@monamienet.org`);
  if (!root) throw new TeamError("partner", "Organização sem grupo principal.");
  const teams = [];
  for (const member of await api.members(root)) {
    const address = parseGroupAddress(member.email);
    if (member.type !== "GROUP" || !address) continue;
    if (address.partnerId !== partnerId || address.level !== 1) continue;
    const emails = teamGroupEmails(partnerId, address.team);
    const name = await api.lookup(emails.team);
    const group = name ? await api.get(name) : null;
    const roles = new Map();
    for (const [role, leaf] of [
      ["watch", emails.watch],
      ["share", emails.share],
    ]) {
      const leafName = await api.lookup(leaf);
      if (!leafName) continue;
      for (const person of await api.members(leafName)) {
        if (person.type === "GROUP") continue;
        roles.set(person.email, [...(roles.get(person.email) ?? []), role]);
      }
    }
    teams.push({
      team: address.team,
      key: address.teamKey,
      email: emails.team,
      name: group?.displayName || `Equipe ${address.team}`,
      people: [...roles].map(([email, r]) => ({ email, roles: r.sort() })),
    });
  }
  return teams.sort((a, b) => a.team.localeCompare(b.team));
}

/**
 * Creates a team: `<id>NN` (display name `name`) inside the root group,
 * then its leaves `<id>NNr` and `<id>NNw` inside it, all allowing external
 * members and moderated only by the service account. If any step fails,
 * the groups already created are deleted, so no half-made team is left.
 *
 * @returns {Promise<{team: string, key: string, name: string}>}
 */
async function createTeam(api, partnerId, requestedName) {
  const existing = await listTeams(api, partnerId);
  const name = validateTeamName(
    requestedName,
    existing.map((t) => t.name)
  );
  const team = nextTeamNumber(existing.map((t) => t.team));
  const emails = teamGroupEmails(partnerId, team);
  const root = await api.lookup(`${partnerId}00@monamienet.org`);
  const customer = (await api.get(root)).parent;
  const created = [];
  try {
    const teamGroup = await api.create(emails.team, name, customer);
    created.push(teamGroup);
    await api.setMonAmieSettings(emails.team);
    await api.addMember(root, emails.team);
    for (const [leaf, label] of [
      [emails.watch, "vê o mapa"],
      [emails.share, "em campo"],
    ]) {
      const leafGroup = await api.create(leaf, `${name} · ${label}`, customer);
      created.push(leafGroup);
      await api.setMonAmieSettings(leaf);
      await api.addMember(teamGroup, leaf);
    }
  } catch (error) {
    for (const group of created.reverse()) {
      await api.delete(group).catch(() => {});
    }
    throw error;
  }
  return { team, key: `${partnerId}${team}`, name };
}

/** Changes only the team group's display name; the address never changes. */
async function renameTeam(api, partnerId, team, requestedName) {
  const teams = await listTeams(api, partnerId);
  const current = teams.find((t) => t.team === team);
  if (!current) throw new TeamError("team", "Equipe não encontrada.");
  const name = validateTeamName(
    requestedName,
    teams.filter((t) => t.team !== team).map((t) => t.name)
  );
  await api.rename(await api.lookup(current.email), name);
  return { team, name };
}

/**
 * Who would lose access to the partner if `team` were deleted, for the
 * confirmation dialog.
 */
async function deletionImpact(api, partnerId, team) {
  const teams = await listTeams(api, partnerId);
  const groupsByPerson = new Map();
  // Members of the root group (the administrators) watch every team: they never
  // lose access by a team being deleted.
  const rootEmail = `${partnerId}00@monamienet.org`;
  const root = await api.lookup(rootEmail);
  for (const member of root ? await api.members(root) : []) {
    if (member.type !== "GROUP") groupsByPerson.set(member.email, [rootEmail]);
  }
  for (const t of teams) {
    for (const person of t.people) {
      const leaves = person.roles.map((r) =>
        r === "watch" ? `${t.key}r@monamienet.org` : `${t.key}w@monamienet.org`
      );
      groupsByPerson.set(person.email, [
        ...(groupsByPerson.get(person.email) ?? []),
        ...leaves,
      ]);
    }
  }
  return whoLosesAccess(`${partnerId}${team}`, groupsByPerson);
}

/** Deletes the two leaves, then the team group. */
async function deleteTeam(api, partnerId, team) {
  const emails = teamGroupEmails(partnerId, team);
  for (const email of [emails.watch, emails.share, emails.team]) {
    const name = await api.lookup(email);
    if (name) await api.delete(name);
  }
}

/**
 * Gives `email` exactly `roles` in `team` (one or both of share/watch),
 * joining or leaving the leaves.
 */
async function setRoles(api, partnerId, team, email, roles) {
  const wanted = validateRoles(roles);
  const teams = await listTeams(api, partnerId);
  const current = teams.find((t) => t.team === team);
  if (!current) throw new TeamError("team", "Equipe não encontrada.");
  const person = current.people.find((p) => p.email === email.toLowerCase());
  const { add, remove } = roleChanges(person?.roles ?? [], wanted);
  const emails = teamGroupEmails(partnerId, team);
  const leafOf = (role) => (role === "watch" ? emails.watch : emails.share);
  for (const role of add) await api.addMember(await api.lookup(leafOf(role)), email);
  for (const role of remove) {
    await api.removeMember(await api.lookup(leafOf(role)), email);
  }
  return { team, email, roles: wanted };
}

/** Removes `email` from both leaves of `team`. */
async function removePerson(api, partnerId, team, email) {
  const emails = teamGroupEmails(partnerId, team);
  for (const leaf of [emails.watch, emails.share]) {
    const name = await api.lookup(leaf);
    if (name) await api.removeMember(name, email);
  }
}

module.exports = {
  createTeam,
  deleteTeam,
  deletionImpact,
  listTeams,
  removePerson,
  renameTeam,
  setRoles,
};
