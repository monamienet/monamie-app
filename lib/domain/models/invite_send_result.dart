import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_send_result.freezed.dart';

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
