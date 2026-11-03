import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/group.dart';

import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/invite_send_result.dart';
import 'invite_state.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';

export 'invite_state.dart';

/// State of *Convidar pessoas*: the group (or the first group's name when
/// the organization has none), the people with their roles, and the send.
class InviteViewModel extends ChangeNotifier {
  InviteViewModel({
    required this.organizationId,
    required this.organizationName,
    required List<Group> groups,
    required this._repository,
    String? groupId,
    this.canCreateFirstGroup = true,
  }) : _state = InviteState(
         groups: groups,
         groupId: groupId ?? (groups.isEmpty ? null : groups.first.id),
       );

  final String organizationId;
  final String organizationName;
  final InvitesRepository _repository;

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
    send.dispose();
    super.dispose();
  }

  /// No group yet: the first one is created with the invites (only by
  /// someone who [canCreateFirstGroup]).
  bool get firstGroupMode => _state.groups.isEmpty && canCreateFirstGroup;

  /// Why the first group's name is not valid yet, or `null`.
  Failure? get firstGroupProblem =>
      firstGroupMode ? groupNameProblem(_state.firstGroupName, const []) : null;

  /// The first group's name as typed (first-group mode).
  void setFirstGroupName(String name) =>
      _emit(_state.copyWith(firstGroupName: name));

  /// Chooses the group to invite to.
  void selectGroup(String? groupId) => _emit(_state.copyWith(groupId: groupId));

  /// Adds [email] with the default role (*Em campo*). Returns whether it
  /// was added.
  bool add(String email) {
    if (send.running) return false;
    final problem = inviteEmailProblem(email, _state.people);
    if (problem != null) {
      _emit(_state.copyWith(draftFailure: problem));
      return false;
    }
    _emit(
      _state.copyWith(
        draftFailure: null,
        people: [..._state.people, InviteDraft(email.trim().toLowerCase())],
      ),
    );
    return true;
  }

  /// Takes [person] (matched by e-mail, unique in the list) off the list.
  void remove(InviteDraft person) {
    if (send.running) return;
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
    if (send.running) return;
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
      !send.running &&
      _state.people.isNotEmpty &&
      _state.people.every((p) => p.roles.isNotEmpty) &&
      (firstGroupMode ? firstGroupProblem == null : _state.groupId != null);

  /// Sends the invites; [Ok] holds the outcome, also kept in
  /// [InviteState.result]. The failure is also kept in
  /// [InviteState.failure]. Ignored unless [canSend].
  late final Command0<InviteSendResult> send = Command0(
    _send,
    blocked: () => !canSend,
  );

  Future<Result<InviteSendResult>> _send() async {
    _emit(_state.copyWith(failure: null));
    final sent = await _repository.send(
      organizationId,
      organizationName: organizationName,
      groupId: firstGroupMode ? null : _state.groupId,
      firstGroupName: firstGroupMode ? _state.firstGroupName.trim() : null,
      invites: [
        for (final p in _state.people) (email: p.email, roles: {...p.roles}),
      ],
    );
    switch (sent) {
      case Ok(value: final result):
        _emit(_state.copyWith(result: result));
      case Err(:final failure):
        _emit(_state.copyWith(failure: failure));
    }
    return sent;
  }

  /// "Convidar mais pessoas".
  void again() =>
      _emit(_state.copyWith(people: const [], result: null, failure: null));
}
