import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/admin/teams/team.dart';

import 'invite.dart';
import 'invites_backend.dart';

/// State of *Convidar pessoas*: the team (or the first team's name when the
/// organization has none), the people with their roles, and the send.
class InviteController extends GetxController {
  InviteController({
    required this.partnerId,
    required this.partnerName,
    required List<Team> teams,
    required InvitesBackend backend,
    String? team,
  }) : _backend = backend,
       teams = teams.obs,
       team = RxnString(team ?? (teams.isEmpty ? null : teams.first.number));

  final String partnerId;
  final String partnerName;
  final InvitesBackend _backend;

  final RxList<Team> teams;

  /// The chosen team's number, or `null` in first-team mode.
  final RxnString team;

  /// The first team's name, when the organization has no team yet.
  final RxString firstTeamName = ''.obs;

  final RxList<InviteDraft> people = <InviteDraft>[].obs;
  final RxString draftError = ''.obs;
  final RxBool isSending = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<InviteSendResult> result = Rxn<InviteSendResult>();

  /// No team yet: the first one is created with the invites.
  bool get firstTeamMode => teams.isEmpty;

  /// Why the first team's name is not valid yet, or `null`.
  String? get firstTeamProblem =>
      firstTeamMode ? teamNameProblem(firstTeamName.value, const []) : null;

  /// Adds [email] with the default role (*Em campo*). Returns whether it
  /// was added.
  bool add(String email) {
    if (isSending.value) return false;
    final problem = inviteEmailProblem(email, people);
    draftError.value = problem ?? '';
    if (problem != null) return false;
    people.add(InviteDraft(email.trim().toLowerCase()));
    return true;
  }

  void remove(InviteDraft person) {
    if (!isSending.value) people.remove(person);
  }

  /// Turns [role] on or off for [person] (a person may end up with none,
  /// which blocks the send until fixed).
  void toggle(InviteDraft person, TeamRole role) {
    if (isSending.value) return;
    person.roles.contains(role)
        ? person.roles.remove(role)
        : person.roles.add(role);
    people.refresh();
  }

  bool get canSend =>
      !isSending.value &&
      people.isNotEmpty &&
      people.every((p) => p.roles.isNotEmpty) &&
      (firstTeamMode ? firstTeamProblem == null : team.value != null);

  /// Sends the invites. Returns whether they were sent.
  Future<bool> send() async {
    if (!canSend) return false;
    isSending.value = true;
    errorMessage.value = '';
    try {
      result.value = await _backend.send(
        partnerId,
        partnerName: partnerName,
        team: firstTeamMode ? null : team.value,
        firstTeamName: firstTeamMode ? firstTeamName.value.trim() : null,
        invites: [
          for (final p in people) (email: p.email, roles: {...p.roles}),
        ],
      );
      return true;
    } on InvitesException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      debugPrint('[Invite] Send failed: $e');
      errorMessage.value =
          'Não foi possível enviar agora. Verifique a conexão e tente de novo.';
      return false;
    } finally {
      isSending.value = false;
    }
  }

  /// "Convidar mais pessoas".
  void again() {
    people.clear();
    result.value = null;
    errorMessage.value = '';
  }
}
