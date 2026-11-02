import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/auth/view_models/organization_choice_state.dart';
import 'package:monamie_app/utils/result.dart';

export 'organization_choice_state.dart';

/// State of *Sem organização* and *Escolher organização*, the screens of a
/// person signed in to MonAmie but in no organization yet: the choices and
/// invites the session opened them with, entering an organization, checking
/// again, accepting an invite and "Trocar" (signing out).
///
/// It follows the session: a new check that lands on the same screen
/// refreshes what it shows. It never navigates: the entry moves the session
/// and the router follows.
class OrganizationChoiceViewModel extends ChangeNotifier {
  OrganizationChoiceViewModel({
    required this._session,
    required this._enterOrganization,
    required this._signOut,
    required this._invites,
  }) {
    _onSession();
    _onLeaving();
    _session.session.addListener(_onSession);
    _session.leaving.addListener(_onLeaving);
  }

  final SessionRepository _session;
  final EnterOrganization _enterOrganization;
  final SignOut _signOut;
  final InvitesRepository _invites;

  OrganizationChoiceState _state = const OrganizationChoiceState();
  bool _disposed = false;

  /// What the screens show; replaced whole, never changed in place.
  OrganizationChoiceState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(OrganizationChoiceState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  /// Takes what the session opened the screen with; any other session is
  /// the screen being left, and changes nothing.
  void _onSession() {
    final email = _session.signedInEmail;
    switch (_session.session.value) {
      case SessionNoOrganization(:final reason, :final invites):
        _emit(
          _state.copyWith(
            signedInEmail: email,
            noAccessReason: reason,
            organizationChoices: const [],
            pendingInvites: invites,
          ),
        );
      case SessionPicking(:final choices, :final invites):
        _emit(
          _state.copyWith(
            signedInEmail: email,
            noAccessReason: null,
            organizationChoices: choices,
            pendingInvites: invites,
          ),
        );
      default:
    }
  }

  void _onLeaving() =>
      _emit(_state.copyWith(isLoggingOut: _session.leaving.value != null));

  void _onEntering(String name) =>
      _emit(_state.copyWith(enteringOrganizationName: name));

  @override
  void dispose() {
    _disposed = true;
    _session.session.removeListener(_onSession);
    _session.leaving.removeListener(_onLeaving);
    super.dispose();
  }

  /// "Trocar": signs out. [Ok] holds whether the sign-out finished
  /// (`false` while another one runs); [Err] says why it failed.
  Future<Result<bool>> logout() => _signOut();

  /// "Já me convidaram · verificar de novo": asks again which organizations
  /// the person belongs to, reusing this sign-in when there is one. [Err]
  /// says why it could not; [Ok] also while another operation runs.
  Future<Result<void>> recheckOrganizations() async {
    if (_state.isLoading) return const Ok(null);
    _emit(_state.copyWith(isLoading: true, noAccessReason: null));
    try {
      return switch (await _enterOrganization.withKeptSignIn(
        onEntering: _onEntering,
      )) {
        Ok() => const Ok(null),
        Err(:final error, :final stackTrace) => Err(
          "Não foi possível verificar agora: $error",
          title: EnterOrganization.errorTitle,
          error: error,
          stackTrace: stackTrace,
        ),
      };
    } finally {
      _emit(_state.copyWith(isLoading: false, enteringOrganizationName: null));
    }
  }

  /// Enters the organization picked on *Escolher organização*. [Err] says
  /// why it could not; [Ok] also when there is nothing to do.
  Future<Result<void>> chooseOrganization(OrganizationBinding binding) async {
    if (_session.idToken == null || _state.isLoading) return const Ok(null);
    _emit(_state.copyWith(isLoading: true));
    try {
      return switch (await _enterOrganization.choose(
        binding,
        onEntering: _onEntering,
      )) {
        Ok() => const Ok(null),
        Err(:final error, :final stackTrace) => Err(
          "Não foi possível entrar em ${binding.organization.name}: $error",
          title: EnterOrganization.errorTitle,
          error: error,
          stackTrace: stackTrace,
        ),
      };
    } finally {
      _emit(_state.copyWith(isLoading: false, enteringOrganizationName: null));
    }
  }

  /// "Aceitar e entrar": joins the invite's group, then enters its
  /// organization and shows *Boas-vindas*.
  Future<void> acceptInvite(Invite invite) async {
    if (_state.acceptingInvite != null || _state.isLoading) return;
    _emit(_state.copyWith(acceptingInvite: invite.id, inviteError: ''));
    try {
      switch (await _invites.accept(invite)) {
        case Ok():
          final entered = await _enterOrganization.withKeptSignIn(
            enter: invite.organizationId,
            welcome: invite,
            onEntering: _onEntering,
          );
          if (entered case Err(:final error)) {
            // Entering the organization after joining failed.
            debugPrint('[Invites] Accept failed: $error');
            _emit(
              _state.copyWith(
                inviteError:
                    'Não foi possível aceitar agora. Verifique a conexão e '
                    'tente de novo.',
              ),
            );
          }
        case Err(:final message):
          _emit(_state.copyWith(inviteError: message));
      }
    } finally {
      _emit(
        _state.copyWith(acceptingInvite: null, enteringOrganizationName: null),
      );
    }
  }
}
