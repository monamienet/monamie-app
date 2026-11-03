import 'package:monamie_app/data/repositories/functions_result.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/invite_send_result.dart';
import 'package:monamie_app/utils/result.dart';

import 'invites_repository.dart';

const _failed = Failure.connection(FailedAction.conclude);
const _loadFailed = Failure.load(LoadTarget.invites);

/// [InvitesRepository] over the central project's invite functions.
class InvitesRepositoryRemote implements InvitesRepository {
  const InvitesRepositoryRemote({required this._functions});

  final CentralFunctionsService _functions;

  Future<Result<T>> _run<T>(
    Future<Result<T>> Function() operation, {
    Failure unexpected = _failed,
  }) => functionsResult(
    operation,
    refusal: functionsRefusal,
    unexpected: unexpected,
    logTag: 'Invites',
  );

  List<Invite> _invites(Object? data) => [
    for (final entry
        in (data is Map ? data['invites'] : null) as List? ?? const [])
      ?Invite.fromJson(entry),
  ];

  @override
  Future<Result<InviteSendResult>> send(
    String organizationId, {
    required String organizationName,
    String? groupId,
    String? firstGroupName,
    required List<({String email, Set<GroupRole> roles})> invites,
  }) => _run(() async {
    final data = await _functions.call('sendInvites', {
      'organizationId': organizationId,
      'organizationName': organizationName,
      'groupId': ?groupId,
      'firstGroupName': ?firstGroupName,
      'invites': [
        for (final i in invites)
          {
            'email': i.email,
            'roles': [for (final r in i.roles) r.id],
          },
      ],
    });
    final map = data is Map ? data : const <Object?, Object?>{};
    final sent = [
      for (final s in (map['sent'] as List?) ?? const [])
        if (s is Map && s['email'] is String) s,
    ];
    return Ok(
      InviteSendResult(
        groupId: '${map['groupId'] ?? groupId ?? ''}',
        groupName: '${map['groupName'] ?? firstGroupName ?? ''}',
        sent: [for (final s in sent) s['email'] as String],
        notEmailed: [
          for (final s in sent)
            if (s['emailed'] != true) s['email'] as String,
        ],
        skipped: {
          for (final s in (map['skipped'] as List?) ?? const [])
            if (s case {'email': final String e, 'reason': final String r})
              e: r,
        },
      ),
    );
  }, unexpected: const Failure.connection(FailedAction.send));

  @override
  Future<Result<List<Invite>>> listForGroup(
    String organizationId,
    String groupId,
  ) => _run(
    () async => Ok(
      _invites(
        await _functions.call('listInvites', {
          'organizationId': organizationId,
          'groupId': groupId,
        }),
      ),
    ),
    unexpected: _loadFailed,
  );

  @override
  Future<Result<void>> resend(String organizationId, String inviteId) =>
      _run(() async {
        await _functions.call('resendInvite', {
          'organizationId': organizationId,
          'inviteId': inviteId,
        });
        return const Ok(null);
      });

  @override
  Future<Result<void>> cancel(String organizationId, String inviteId) =>
      _run(() async {
        await _functions.call('cancelInvite', {
          'organizationId': organizationId,
          'inviteId': inviteId,
        });
        return const Ok(null);
      });

  @override
  Future<Result<List<Invite>>> mine() => _run(
    () async => Ok(_invites(await _functions.call('myInvites', const {}))),
    unexpected: _loadFailed,
  );

  @override
  Future<Result<Invite>> accept(Invite invite) => _run(() async {
    await _functions.call('acceptInvite', {'inviteId': invite.id});
    return Ok(invite);
  }, unexpected: const Failure.connection(FailedAction.accept));
}
