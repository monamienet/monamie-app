import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:monamie_app/app/config/organization/group_address.dart';

import 'group_directory.dart';
import 'organizations.dart';

/// One change to the organization's groups.
sealed class GroupChange {
  const GroupChange();

  /// The `gcloud identity` arguments that make this change.
  List<String> get gcloudArgs;
}

/// Creates a group with no initial owner (only the service accounts and
/// MonAmieNet's admins administer groups).
class CreateGroup extends GroupChange {
  const CreateGroup(this.email, this.displayName);

  final String email;
  final String displayName;

  @override
  List<String> get gcloudArgs => [
    'identity',
    'groups',
    'create',
    email,
    '--organization=$groupDomain',
    '--display-name=$displayName',
    '--with-initial-owner=empty',
  ];

  @override
  String toString() => 'create $email ("$displayName")';
}

/// Adds [member] (a person or a group) to [group] as a plain `MEMBER`.
class AddMember extends GroupChange {
  const AddMember(this.group, this.member);

  final String group;
  final String member;

  @override
  List<String> get gcloudArgs => [
    'identity',
    'groups',
    'memberships',
    'add',
    '--group-email=$group',
    '--member-email=$member',
    '--roles=MEMBER',
  ];

  @override
  String toString() => 'add $member to $group';
}

/// Removes [member] from [group].
class RemoveMember extends GroupChange {
  const RemoveMember(this.group, this.member);

  final String group;
  final String member;

  @override
  List<String> get gcloudArgs => [
    'identity',
    'groups',
    'memberships',
    'delete',
    '--group-email=$group',
    '--member-email=$member',
    '--quiet',
  ];

  @override
  String toString() => 'remove $member from $group';
}

/// A team of the old model: its group and its direct members.
class LegacyTeam {
  const LegacyTeam({
    required this.email,
    required this.name,
    required this.members,
  });

  final String email;
  final String name;
  final List<GroupMember> members;
}

/// The changes that move [teams] to the three-level model (#91):
///
/// - each team `<id>NN` gets its leaves `<id>NNr` (watch) and `<id>NNw`
///   (share), nested in it, unless they already exist ([existingGroups]);
/// - each direct person becomes a member of a leaf: `MEMBER` and `MANAGER`
///   (who shared their location) go to `w`, `OWNER` (who only watched) goes
///   to `r`, and also to `w` when [ownersAlsoShare] lists them;
/// - then they leave the team group, which keeps no direct members.
///
/// Subgroups that are not leaves of the team, and members that are not
/// people (type `OTHER`), are left alone. Running it
/// again after a partial run only plans what is still missing.
List<GroupChange> planGroupMigration(
  List<LegacyTeam> teams, {
  Set<String> existingGroups = const {},
  Set<String> ownersAlsoShare = const {},
}) {
  final changes = <GroupChange>[];
  for (final team in teams) {
    final address = parseGroupAddress(team.email);
    if (address == null || address.level != GroupLevel.team) continue;
    final watchLeaf = '${address.teamKey}r@$groupDomain';
    final shareLeaf = '${address.teamKey}w@$groupDomain';
    final nested = {
      for (final member in team.members)
        if (member.isGroup) member.email.trim().toLowerCase(),
    };
    for (final (leaf, label) in [
      (watchLeaf, 'vê o mapa'),
      (shareLeaf, 'em campo'),
    ]) {
      if (!existingGroups.contains(leaf)) {
        changes.add(CreateGroup(leaf, '${team.name} · $label'));
      }
      if (!nested.contains(leaf)) {
        changes.add(AddMember(address.teamEmail, leaf));
      }
    }
    for (final person in team.members.where((m) => m.isUser && !m.isGroup)) {
      final email = person.email.trim().toLowerCase();
      final watches = person.role == 'OWNER';
      final shares = !watches || ownersAlsoShare.contains(email);
      if (watches) changes.add(AddMember(watchLeaf, email));
      if (shares) changes.add(AddMember(shareLeaf, email));
      changes.add(RemoveMember(address.teamEmail, email));
    }
  }
  return changes;
}

/// Runs `gcloud` with [args]; throws a [OrganizationToolException] on failure.
typedef GcloudRunner = Future<void> Function(List<String> args);

/// `migrate-groups <id>`: moves an organization made before #91 to the
/// three-level group model. Prints the plan; `--apply` runs it.
class MigrateGroupsCommand extends Command<void> {
  MigrateGroupsCommand(this._groups, this._runGcloud) {
    argParser
      ..addFlag(
        'apply',
        negatable: false,
        help: 'Run the plan (without it, only print it).',
      )
      ..addMultiOption(
        'owner-shares',
        help:
            'E-mail of a team OWNER who also shared their location: they '
            'join the share leaf too. Repeat for several.',
      );
  }

  final GroupDirectory _groups;
  final GcloudRunner _runGcloud;

  /// Runs [change]. A membership or group that already exists counts as
  /// done, so a run interrupted halfway can simply be repeated.
  Future<void> _apply(GroupChange change) async {
    try {
      await _runGcloud(change.gcloudArgs);
    } on OrganizationToolException catch (error) {
      if (change is RemoveMember || !error.message.contains('already exists')) {
        rethrow;
      }
      stdout.writeln('  (already done)');
    }
  }

  @override
  String get name => 'migrate-groups';

  @override
  String get description =>
      'Move an organization to the three-level group model: <id>NN teams with '
      '<id>NNr (watch) and <id>NNw (share) leaves.';

  @override
  String get invocation => '${runner!.executableName} $name <id>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      usageException('Expected exactly one organization id.');
    }
    final id = rest.single;
    checkOrganizationId(id);

    final rootMembers = await _groups.members(rootGroupEmail(id));
    final teams = <LegacyTeam>[];
    final existing = <String>{};
    for (final member in rootMembers.where((m) => m.isGroup)) {
      final address = parseGroupAddress(member.email);
      if (address == null ||
          address.organizationId != id ||
          address.level != GroupLevel.team) {
        continue;
      }
      final members = await _groups.members(address.teamEmail);
      for (final leaf in members.where((m) => m.isGroup)) {
        existing.add(leaf.email.trim().toLowerCase());
      }
      teams.add(
        LegacyTeam(
          email: address.teamEmail,
          name: 'Equipe ${address.team}',
          members: members,
        ),
      );
    }

    final people = rootMembers.where((m) => !m.isGroup).map((m) => m.email);
    if (people.length > 1) {
      stdout.writeln(
        'Warning: the root group should only hold the owner, but it has '
        '${people.length} people: ${people.join(', ')}. Each of them watches '
        'every team.',
      );
    }

    final plan = planGroupMigration(
      teams,
      existingGroups: existing,
      ownersAlsoShare: {
        for (final email in argResults!.multiOption('owner-shares'))
          email.trim().toLowerCase(),
      },
    );
    if (plan.isEmpty) {
      stdout.writeln("Organization '$id' already uses the three-level model.");
      return;
    }
    final apply = argResults!.flag('apply');
    for (final change in plan) {
      stdout.writeln('${apply ? 'Running' : 'Would'}: $change');
      if (apply) await _apply(change);
    }
    stdout.writeln(
      apply
          ? 'Done. Rename the leaves in the Admin console if you like, set '
                '"Allow members outside your organization" on every new leaf, '
                'and ask the people to sign in again (their claims are '
                'recomputed at sign-in).'
          : 'Nothing changed. Run again with --apply to make these changes.',
    );
  }
}
