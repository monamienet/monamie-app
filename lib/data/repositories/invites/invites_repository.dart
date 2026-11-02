import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/invite_send_result.dart';
import 'package:monamie_app/utils/result.dart';

/// The central invite functions, behind a contract so the screens are
/// tested with a fake. Every method returns an [Err] with a message instead
/// of throwing.
abstract interface class InvitesRepository {
  Future<Result<InviteSendResult>> send(
    String organizationId, {
    required String organizationName,
    String? groupId,
    String? firstGroupName,
    required List<({String email, Set<GroupRole> roles})> invites,
  });

  Future<Result<List<Invite>>> listForGroup(
    String organizationId,
    String groupId,
  );
  Future<Result<void>> resend(String organizationId, String inviteId);
  Future<Result<void>> cancel(String organizationId, String inviteId);

  /// The signed-in account's pending invites.
  Future<Result<List<Invite>>> mine();

  /// Accepts [invite] as the signed-in account; returns the invite.
  Future<Result<Invite>> accept(Invite invite);
}
