import 'package:monamie_app/app/modules/admin/teams/team.dart';

import 'invite.dart';

/// The outcome of one send.
class InviteSendResult {
  const InviteSendResult({
    required this.team,
    required this.teamName,
    required this.sent,
    required this.notEmailed,
    required this.skipped,
  });

  final String team;
  final String teamName;

  /// E-mails invited (a pending invite exists for each).
  final List<String> sent;

  /// Invited, but the e-mail could not be sent: the person still sees the
  /// invite when they sign in.
  final List<String> notEmailed;

  /// Not invited, with the reason ("Já está na equipe.").
  final Map<String, String> skipped;
}

/// The central invite functions, behind a contract so the screens are
/// tested with a fake. Throws [InvitesException] with a message.
abstract interface class InvitesBackend {
  Future<InviteSendResult> send(
    String organizationId, {
    required String organizationName,
    String? team,
    String? firstTeamName,
    required List<({String email, Set<TeamRole> roles})> invites,
  });

  Future<List<Invite>> listForTeam(String organizationId, String team);
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
