import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';

import 'invite.dart';
import 'invite_state.dart';
import 'invites_backend.dart';

export 'invite_state.dart';

/// State of *Convidar pessoas*: the group (or the first group's name when
/// the organization has none), the people with their roles, and the send.
class InviteController extends ChangeNotifier {
  InviteController({
    required this.organizationId,
    required this.organizationName,
    required List<Group> groups,
    required this._backend,
    String? groupId,
    this.canCreateFirstGroup = true,
  }) : _state = InviteState(
         groups: groups,
         groupId: groupId ?? (groups.isEmpty ? null : groups.first.id),
       );

  final String organizationId;
  final String organizationName;
  final InvitesBackend _backend;

  /// Whether an organization with no group may create its first one here
  /// (administrators); a group's maintainer only invites to their groups.
  final bool canCreateFirstGroup;

  InviteState _state;
  bool _disposed = false;

  /// What the screen shows; replaced whole, never changed in place.
  InviteState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(InviteState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// No group yet: the first one is created with the invites (only by
  /// someone who [canCreateFirstGroup]).
  bool get firstGroupMode => _state.groups.isEmpty && canCreateFirstGroup;

  /// Why the first group's name is not valid yet, or `null`.
  String? get firstGroupProblem =>
      firstGroupMode ? groupNameProblem(_state.firstGroupName, const []) : null;

  /// The first group's name as typed (first-group mode).
  void setFirstGroupName(String name) =>
      _emit(_state.copyWith(firstGroupName: name));

  /// Chooses the group to invite to.
  void selectGroup(String? groupId) => _emit(_state.copyWith(groupId: groupId));

  /// Adds [email] with the default role (*Em campo*). Returns whether it
  /// was added.
  bool add(String email) {
    if (_state.isSending) return false;
    final problem = inviteEmailProblem(email, _state.people);
    if (problem != null) {
      _emit(_state.copyWith(draftError: problem));
      return false;
    }
    _emit(
      _state.copyWith(
        draftError: '',
        people: [..._state.people, InviteDraft(email.trim().toLowerCase())],
      ),
    );
    return true;
  }

  /// Takes [person] (matched by e-mail, unique in the list) off the list.
  void remove(InviteDraft person) {
    if (_state.isSending) return;
    _emit(
      _state.copyWith(
        people: [
          for (final p in _state.people)
            if (p.email != person.email) p,
        ],
      ),
    );
  }

  /// Turns [role] on or off for [person] (matched by e-mail, unique in the
  /// list; a person may end up with none, which blocks the send until
  /// fixed).
  void toggle(InviteDraft person, GroupRole role) {
    if (_state.isSending) return;
    _emit(
      _state.copyWith(
        people: [
          for (final p in _state.people)
            if (p.email != person.email)
              p
            else
              p.copyWith(
                roles: p.roles.contains(role)
                    ? p.roles.difference({role})
                    : {...p.roles, role},
              ),
        ],
      ),
    );
  }

  bool get canSend =>
      !_state.isSending &&
      _state.people.isNotEmpty &&
      _state.people.every((p) => p.roles.isNotEmpty) &&
      (firstGroupMode ? firstGroupProblem == null : _state.groupId != null);

  /// Sends the invites. Returns whether they were sent.
  Future<bool> send() async {
    if (!canSend) return false;
    _emit(_state.copyWith(isSending: true, errorMessage: ''));
    try {
      final result = await _backend.send(
        organizationId,
        organizationName: organizationName,
        groupId: firstGroupMode ? null : _state.groupId,
        firstGroupName: firstGroupMode ? _state.firstGroupName.trim() : null,
        invites: [
          for (final p in _state.people) (email: p.email, roles: {...p.roles}),
        ],
      );
      _emit(_state.copyWith(result: result));
      return true;
    } on InvitesException catch (e) {
      _emit(_state.copyWith(errorMessage: e.message));
      return false;
    } catch (e) {
      debugPrint('[Invite] Send failed: $e');
      _emit(
        _state.copyWith(
          errorMessage:
              'Não foi possível enviar agora. Verifique a conexão e tente de '
              'novo.',
        ),
      );
      return false;
    } finally {
      _emit(_state.copyWith(isSending: false));
    }
  }

  /// "Convidar mais pessoas".
  void again() =>
      _emit(_state.copyWith(people: const [], result: null, errorMessage: ''));
}
