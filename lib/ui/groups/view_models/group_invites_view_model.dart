import 'package:flutter/foundation.dart';

import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'group_invites_state.dart';

export 'group_invites_state.dart';

/// State of the invites tab of *Grupo*: the group's pending invites,
/// resending an expired one and cancelling another. Created by the group's
/// route; the screen runs [load] when it opens and again when *Convidar
/// pessoas* closes.
class GroupInvitesViewModel extends ChangeNotifier {
  GroupInvitesViewModel({
    required this.organizationId,
    required this.groupId,
    required this._repository,
  });

  final String organizationId;
  final String groupId;
  final InvitesRepository _repository;

  GroupInvitesState _state = const GroupInvitesState();
  bool _disposed = false;

  /// What the tab shows; replaced whole, never changed in place.
  GroupInvitesState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(GroupInvitesState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    load.dispose();
    resend.dispose();
    cancel.dispose();
    super.dispose();
  }

  /// Reads the group's pending invites. A failure is kept in
  /// [GroupInvitesState.errorMessage]; the invites already read stay.
  late final Command0<void> load = Command0(_load);

  /// Sends the invite given again (a new e-mail, 14 more days), then reads
  /// the invites again.
  late final Command1<void, Invite> resend = Command1(
    (invite) =>
        _changeAndReload(() => _repository.resend(organizationId, invite.id)),
    blocked: () => isWorking,
  );

  /// Cancels the invite given, then reads the invites again.
  late final Command1<void, Invite> cancel = Command1(
    (invite) =>
        _changeAndReload(() => _repository.cancel(organizationId, invite.id)),
    blocked: () => isWorking,
  );

  /// Whether an invite is being resent or cancelled, or the list is being
  /// read: one operation at a time.
  bool get isWorking => load.running || resend.running || cancel.running;

  Future<Result<void>> _load() async {
    final loaded = await _repository.listForGroup(organizationId, groupId);
    switch (loaded) {
      case Ok(value: final invites):
        _emit(_state.copyWith(invites: invites, errorMessage: ''));
        return const Ok(null);
      case Err(:final error, :final stackTrace):
        const message = 'Não foi possível carregar os convites.';
        _emit(_state.copyWith(errorMessage: message));
        return Err(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Runs [operation] and, once it worked, reads the invites again (a
  /// failed reload does not fail it).
  Future<Result<void>> _changeAndReload(
    Future<Result<void>> Function() operation,
  ) async {
    final result = await operation();
    if (result is Err) return result;
    await _load();
    return const Ok(null);
  }
}
