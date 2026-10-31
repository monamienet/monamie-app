import 'package:cloud_functions/cloud_functions.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';

import 'invite.dart';
import 'invites_backend.dart';

/// [InvitesBackend] over the central project's invite functions.
class FirebaseInvitesBackend implements InvitesBackend {
  const FirebaseInvitesBackend();

  Future<Object?> _call(String name, Map<String, Object?> data) async {
    try {
      final result = await CentralFirebase.functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
          )
          .call(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw InvitesException(switch (e.code) {
        'invalid-argument' ||
        'failed-precondition' ||
        'permission-denied' => e.message ?? 'Não foi possível concluir.',
        _ =>
          'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
      });
    }
  }

  List<Invite> _invites(Object? data) => [
    for (final entry
        in (data is Map ? data['invites'] : null) as List? ?? const [])
      ?Invite.fromJson(entry),
  ];

  @override
  Future<InviteSendResult> send(
    String organizationId, {
    required String organizationName,
    String? groupId,
    String? firstGroupName,
    required List<({String email, Set<GroupRole> roles})> invites,
  }) async {
    final data = await _call('sendInvites', {
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
    final map = data is Map ? data : const {};
    final sent = [
      for (final s in (map['sent'] as List?) ?? const [])
        if (s is Map && s['email'] is String) s,
    ];
    return InviteSendResult(
      groupId: '${map['groupId'] ?? groupId ?? ''}',
      groupName: '${map['groupName'] ?? firstGroupName ?? ''}',
      sent: [for (final s in sent) s['email'] as String],
      notEmailed: [
        for (final s in sent)
          if (s['emailed'] != true) s['email'] as String,
      ],
      skipped: {
        for (final s in (map['skipped'] as List?) ?? const [])
          if (s case {'email': final String e, 'reason': final String r}) e: r,
      },
    );
  }

  @override
  Future<List<Invite>> listForGroup(
    String organizationId,
    String groupId,
  ) async => _invites(
    await _call('listInvites', {
      'organizationId': organizationId,
      'groupId': groupId,
    }),
  );

  @override
  Future<void> resend(String organizationId, String inviteId) => _call(
    'resendInvite',
    {'organizationId': organizationId, 'inviteId': inviteId},
  );

  @override
  Future<void> cancel(String organizationId, String inviteId) => _call(
    'cancelInvite',
    {'organizationId': organizationId, 'inviteId': inviteId},
  );

  @override
  Future<List<Invite>> mine() async => _invites(await _call('myInvites', {}));

  @override
  Future<Invite> accept(Invite invite) async {
    await _call('acceptInvite', {'inviteId': invite.id});
    return invite;
  }
}
