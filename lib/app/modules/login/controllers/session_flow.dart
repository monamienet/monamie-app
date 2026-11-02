// check_layers: state_contract

import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_state.dart';
import 'package:monamie_app/app/modules/login/controllers/session_state.dart';
import 'package:monamie_app/app/utils/result.dart';

/// What the screens read and start of the sign-in flow: MonAmie's entry
/// screens (*Login*, *Escolher organização*, *Sem organização*, *Em
/// exclusão*, *Boas-vindas*) and the home screen's menu and sign-out
/// overlay. Implemented by `AuthGoogleController`, provided by the app
/// scope; screens depend on this contract, so their tests use a mock.
///
/// Notifies whenever [state] changes.
abstract interface class SessionFlow implements Listenable {
  /// What the screens show; replaced whole, never changed in place.
  AuthGoogleState get state;

  /// Where the flow stands, the router's only input (it redirects on each
  /// change); the same value as `state.session`.
  ValueListenable<SessionState> get session;

  /// "Sair". [Ok] holds whether the sign-out finished (`false` while
  /// another one runs); [Err] says why it failed.
  Future<Result<bool>> logout();

  /// Enters the organization picked on *Escolher organização*. [Err] says
  /// why it could not; [Ok] also when there is nothing to do.
  Future<Result<void>> chooseOrganization(OrganizationBinding binding);

  /// "Já me convidaram · verificar de novo" (and *Em exclusão*'s "Entrar").
  /// [Err] says why it could not; [Ok] also while another operation runs.
  Future<Result<void>> recheckOrganizations();

  /// "Trocar de organização". [Err] says why nothing changed; [Ok] also
  /// while another operation runs.
  Future<Result<void>> switchOrganization();

  /// "Cancelar exclusão".
  Future<void> cancelAccountDeletion();

  /// "Aceitar e entrar" on an invite card.
  Future<void> acceptInvite(Invite invite);

  /// *Boas-vindas* closed: the person goes on to the map.
  void finishWelcome();

  /// Reads once whether the person owns [organizationId] into
  /// `state.ownership`.
  Future<void> loadOwnership(String organizationId);
}
