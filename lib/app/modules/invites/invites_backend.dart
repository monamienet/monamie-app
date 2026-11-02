import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';

import 'invite.dart';

part 'invites_backend.freezed.dart';

/// The outcome of one send.
@freezed
abstract class InviteSendResult with _$InviteSendResult {
  const factory InviteSendResult({
    /// The group invited to (just created, in first-group mode).
    required String groupId,
    required String groupName,

    /// E-mails invited (a pending invite exists for each).
    required List<String> sent,

    /// Invited, but the e-mail could not be sent: the person still sees the
    /// invite when they sign in.
    required List<String> notEmailed,

    /// Not invited, with the reason ("Já está no grupo.").
    required Map<String, String> skipped,
  }) = _InviteSendResult;
}

/// The central invite functions, behind a contract so the screens are
/// tested with a fake. Throws [InvitesException] with a message.
abstract interface class InvitesBackend {
  Future<InviteSendResult> send(
    String organizationId, {
    required String organizationName,
    String? groupId,
    String? firstGroupName,
    required List<({String email, Set<GroupRole> roles})> invites,
  });

  Future<List<Invite>> listForGroup(String organizationId, String groupId);
  Future<void> resend(String organizationId, String inviteId);
  Future<void> cancel(String organizationId, String inviteId);

  /// The signed-in account's pending invites.
  Future<List<Invite>> mine();

  /// Accepts [inviteId] as the signed-in account; returns the invite.
  Future<Invite> accept(Invite invite);
}

class InvitesException implements Exception {
  const InvitesException(this.message);

  final String message;

  @override
  String toString() => message;
}
