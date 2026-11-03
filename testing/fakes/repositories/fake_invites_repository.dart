import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/invite_send_result.dart';
import 'package:monamie_app/utils/result.dart';

import 'fake_outcomes.dart';

/// [InvitesRepository] over in-memory invites: [sent] (the invites an
/// administrator or maintainer sent, by organization id) and [mineInvites]
/// (the signed-in account's own). Sending adds one invite per e-mail
/// (ids `i1`, `i2`…; a first group gets the id `first-group`), cancelling
/// removes it, accepting removes it from [mineInvites].
class FakeInvitesRepository with FakeOutcomes implements InvitesRepository {
  FakeInvitesRepository({
    List<Invite>? mine,
    Map<String, List<Invite>>? sent,
    Map<String, String>? groupNames,
  }) : mineInvites = [...?mine],
       sent = {
         for (final MapEntry(:key, :value) in (sent ?? const {}).entries)
           key: [...value],
       },
       groupNames = {...?groupNames};

  /// The signed-in account's pending invites.
  final List<Invite> mineInvites;

  /// The invites sent in each organization.
  final Map<String, List<Invite>> sent;

  /// The name of each group invited to, by id (the id itself otherwise).
  final Map<String, String> groupNames;

  /// Who [send] names as the inviter.
  String inviterName = 'Ana';

  int _nextId = 1;

  @override
  Future<Result<InviteSendResult>> send(
    String organizationId, {
    required String organizationName,
    String? groupId,
    String? firstGroupName,
    required List<({String email, Set<GroupRole> roles})> invites,
  }) => answer(
    'send',
    [organizationId, organizationName, groupId, firstGroupName, invites],
    () {
      final id = groupId ?? 'first-group';
      final name = firstGroupName ?? groupNames[id] ?? id;
      if (firstGroupName != null) groupNames[id] = firstGroupName;
      final list = sent.putIfAbsent(organizationId, () => []);
      for (final invite in invites) {
        list.add(
          Invite(
            id: 'i${_nextId++}',
            organizationId: organizationId,
            organizationName: organizationName,
            groupId: id,
            groupName: name,
            email: invite.email,
            roles: invite.roles,
            inviterName: inviterName,
            expiresAt: null,
          ),
        );
      }
      return InviteSendResult(
        groupId: id,
        groupName: name,
        sent: [for (final invite in invites) invite.email],
        notEmailed: const [],
        skipped: const {},
      );
    },
  );

  @override
  Future<Result<List<Invite>>> listForGroup(
    String organizationId,
    String groupId,
  ) => answer('listForGroup', [
    organizationId,
    groupId,
  ], () => [...?sent[organizationId]?.where((i) => i.groupId == groupId)]);

  @override
  Future<Result<void>> resend(String organizationId, String inviteId) =>
      answer('resend', [organizationId, inviteId], () {});

  @override
  Future<Result<void>> cancel(String organizationId, String inviteId) =>
      answer('cancel', [organizationId, inviteId], () {
        sent[organizationId]?.removeWhere((i) => i.id == inviteId);
      });

  @override
  Future<Result<List<Invite>>> mine() =>
      answer('mine', const [], () => [...mineInvites]);

  @override
  Future<Result<Invite>> accept(Invite invite) =>
      answer('accept', [invite], () {
        mineInvites.removeWhere((i) => i.id == invite.id);
        return invite;
      });
}
