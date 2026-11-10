import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/organization/organization_binder.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/repositories/sharing_resume/sharing_resume_repository.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

/// Leaves the bound organization: "Sair", "Trocar de organização", losing
/// access to it and deleting the account.
///
/// The background tracking stops first: the service outlives the screens,
/// and once the organization is signed out the rules refuse the write of
/// `isPublishing = false`. Then the device forgets the organization (its
/// binding, the Google profile, the cached data) and the session moves on;
/// the app's theme follows it back to MonAmie's.
///
/// One at a time, app-wide: [SessionRepository.leaving] says which one runs
/// (the home screen's overlay), and a call made meanwhile does nothing.
/// [notices] shows the messages no screen is waiting for: the tracking
/// warning, which shows after the screen that started the sign-out is gone,
/// and the failures of the sign-outs no screen started.
class SignOut {
  SignOut({
    required this._session,
    required this._trackingStopper,
    required this._userRepository,
    required this._binder,
    required this._localData,
    required this._directory,
    required this._brandingLoader,
    required this._invites,
    required this._sharingResume,
    required this._notices,
  });

  final SessionRepository _session;
  final BackgroundTrackingStopper _trackingStopper;
  final UserGoogleRepository _userRepository;
  final OrganizationBinder _binder;
  final OrganizationLocalData _localData;
  final OrganizationDirectory _directory;
  final OrganizationBrandingLoader _brandingLoader;
  final InvitesRepository _invites;
  final SharingResumeRepository _sharingResume;
  final NoticePresenter _notices;

  /// "Sair". [Ok] holds whether the sign-out finished (`false` while
  /// another one runs); [Err] says why it failed.
  Future<Result<bool>> call() => _signOut(const SessionState.signedOut());

  /// Forgets the organization after the person's membership was removed:
  /// the same steps as [call], then *Sem organização* saying why.
  Future<void> afterAccessLost() async {
    final name = Organization.current?.name;
    _showFailure(
      await _signOut(
        SessionState.noOrganization(
          reason: Failure.removedFromOrganization(name),
        ),
      ),
    );
  }

  /// *Minha conta* scheduled [deletion]: signs out of everything and shows
  /// *Em exclusão*.
  Future<void> afterAccountDeleted(AccountDeletion deletion) async {
    // Registry entries made before in-app creation have no name: the bound
    // organization's display name stands in.
    final organization = Organization.current;
    final shown =
        organization != null &&
            deletion.ownedOrganizationIds.contains(organization.id) &&
            !deletion.ownedOrganizationNames.containsKey(organization.id)
        ? deletion.copyWith(
            ownedOrganizationNames: {
              ...deletion.ownedOrganizationNames,
              organization.id: organization.name,
            },
          )
        : deletion;
    _showFailure(await _signOut(SessionState.deletionPending(shown)));
  }

  /// "Trocar de organização": leaves the bound organization and opens the
  /// organization picker, still signed in with the same Google account.
  ///
  /// The person's organizations are looked up first, so a failing lookup
  /// leaves them where they are instead of unbound. Then the tracking stops,
  /// the organization is forgotten and the picker, or *Sem organização* when
  /// nothing is left, replaces the stack. [Err] says why nothing changed;
  /// [Ok] also while another one runs.
  Future<Result<void>> switchOrganization() async {
    if (_session.leaving.value != null) return const Ok(null);
    // Google is asked again (which may show its account chooser) only when
    // the kept token is no longer good.
    final idToken = await _session.freshIdToken();
    if (idToken == null) {
      // Nothing was changed: the person stays where they are.
      return const Err(Failure.googleRenewal());
    }

    _session.setLeaving(SessionExit.switchOrganization);
    try {
      final candidates = await _directory.organizationsOfSignedInUser();
      final bindings = await Future.wait(candidates.map(_brandingLoader.load));

      await _stopTracking();
      await _session.signOutOfOrganization();
      await _forgetOrganization();
      _session.keepIdToken(idToken);

      final invites = await _mine();
      _session.moveTo(
        bindings.isEmpty
            ? SessionState.noOrganization(invites: invites)
            : SessionState.picking(bindings, invites: invites),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      debugPrint('Erro ao trocar de organização: $e');
      return Err(
        const Failure.connection(FailedAction.switchOrganization),
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _session.setLeaving(null);
    }
  }

  /// Signs out of everything and moves the session to [destination]. [Ok]
  /// holds whether the sign-out finished (`false` while another one runs);
  /// [Err] says why it failed.
  Future<Result<bool>> _signOut(SessionState destination) async {
    if (_session.leaving.value != null) return const Ok(false);

    _session.setLeaving(SessionExit.signOut);
    try {
      // O rastreamento precisa parar ANTES do signOut: o serviço sobrevive ao
      // fechamento da tela, e depois do logout as regras do Firestore recusam
      // a escrita de `isPublishing = false`.
      await _stopTracking();

      await _session.signOut();
      await _forgetOrganization();
      _session.moveTo(destination);
      return const Ok(true);
    } catch (e, stackTrace) {
      debugPrint("Erro ao sair: $e");
      return Err(Failure.signOut('$e'), error: e, stackTrace: stackTrace);
    } finally {
      _session.setLeaving(null);
    }
  }

  /// Forgets the bound organization on the device: the Google profile, the
  /// binding and the cached data.
  Future<void> _forgetOrganization() async {
    await _userRepository.deleteUserGoogleModel();
    await _binder.forget();
    await _localData.clear();
  }

  /// Stops the background tracking and warns when it could not be confirmed.
  /// It must run while the organization is still signed in.
  ///
  /// The warning goes through [_notices]: the operation goes on, and the
  /// screen that started it is usually replaced by then.
  Future<void> _stopTracking() async {
    final stopped = await _trackingStopper.stop(email: await _currentEmail());
    if (!stopped) {
      _notices.show(const UserNotice.trackingStopUnconfirmed());
    }
    // Nobody shares here any more: nothing may resume after a restart, for
    // an organization or an account that is gone.
    try {
      await _sharingResume.clearIntent();
    } catch (e) {
      debugPrint('Could not forget who was sharing: $e');
    }
  }

  /// E-mail do usuário salvo no Hive, a mesma fonte usada pelo
  /// `UserViewModel` para o id do documento em `positions`. Uma falha na
  /// leitura não deve impedir o logout.
  Future<String?> _currentEmail() async {
    try {
      return (await _userRepository.getUserGoogleModel())?.email;
    } catch (e) {
      debugPrint("Erro ao ler o usuário salvo antes do logout: $e");
      return null;
    }
  }

  /// The signed-in account's pending invites; none when they cannot be read.
  Future<List<Invite>> _mine() async {
    switch (await _invites.mine()) {
      case Ok(value: final invites):
        return invites;
      case Err(:final error):
        debugPrint('[Invites] Could not read the invites: $error');
        return const [];
    }
  }

  /// Shows [result]'s failure through [_notices] when it failed: for the
  /// sign-outs no screen waits for.
  void _showFailure(Result<Object?> result) {
    if (result case Err(:final failure)) {
      _notices.show(UserNotice.failure(failure));
    }
  }
}
