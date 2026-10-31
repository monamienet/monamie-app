import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';

import 'invite.dart';
import 'invites_backend.dart';

/// State of *Convidar pessoas*: the group (or the first group's name when
/// the organization has none), the people with their roles, and the send.
class InviteController extends GetxController {
  InviteController({
    required this.organizationId,
    required this.organizationName,
    required List<Group> groups,
    required InvitesBackend backend,
    String? groupId,
    this.canCreateFirstGroup = true,
  }) : _backend = backend,
       groups = groups.obs,
       groupId = RxnString(
         groupId ?? (groups.isEmpty ? null : groups.first.id),
       );

  final String organizationId;
  final String organizationName;
  final InvitesBackend _backend;

  /// Whether an organization with no group may create its first one here
  /// (administrators); a group's maintainer only invites to their groups.
  final bool canCreateFirstGroup;

  final RxList<Group> groups;

  /// The chosen group's id, or `null` in first-group mode.
  final RxnString groupId;

  /// The first group's name, when the organization has no group yet.
  final RxString firstGroupName = ''.obs;

  final RxList<InviteDraft> people = <InviteDraft>[].obs;
  final RxString draftError = ''.obs;
  final RxBool isSending = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<InviteSendResult> result = Rxn<InviteSendResult>();

  /// No group yet: the first one is created with the invites (only by
  /// someone who [canCreateFirstGroup]).
  bool get firstGroupMode => groups.isEmpty && canCreateFirstGroup;

  /// Why the first group's name is not valid yet, or `null`.
  String? get firstGroupProblem =>
      firstGroupMode ? groupNameProblem(firstGroupName.value, const []) : null;

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
  void toggle(InviteDraft person, GroupRole role) {
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
      (firstGroupMode ? firstGroupProblem == null : groupId.value != null);

  /// Sends the invites. Returns whether they were sent.
  Future<bool> send() async {
    if (!canSend) return false;
    isSending.value = true;
    errorMessage.value = '';
    try {
      result.value = await _backend.send(
        organizationId,
        organizationName: organizationName,
        groupId: firstGroupMode ? null : groupId.value,
        firstGroupName: firstGroupMode ? firstGroupName.value.trim() : null,
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
