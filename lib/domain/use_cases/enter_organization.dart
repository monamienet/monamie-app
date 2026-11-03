import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/organization/organization_binder.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/utils/result.dart';

/// Takes a person signed in to MonAmie into one of their organizations.
///
/// After a Google sign-in (central project), the person's organizations come
/// from the central directory, each paired with its branding: none leads to
/// *Sem organização*, otherwise the picker shows, even for a single
/// organization, so they see where they are entering. An organization that
/// just became theirs (an invite accepted, an organization created) is
/// entered directly whenever it is listed. A pending account deletion comes
/// first: *Em exclusão*. Both *Sem organização* and the picker open with the
/// pending invites: someone already in an organization can be invited to
/// another one, or to another group.
///
/// Entering an organization binds its Firebase project and branding
/// together, signs in to the organization project and checks there that the
/// person still has a membership; the session then moves to the map (or
/// *Boas-vindas* after an invite). The app's theme follows the session, so
/// it changes only once the person is known to belong (#78).
///
/// One entry at a time, app-wide: a call made while another runs does
/// nothing and returns [Ok]. Every method returns [Err] instead of throwing;
/// its failure is an [EntryFailure] of [EntryStage.enter] ("Não foi possível
/// entrar agora"), which callers may replace using [Err.error].
class EnterOrganization {
  EnterOrganization({
    required this._session,
    required this._directory,
    required this._brandingLoader,
    required this._binder,
    required this._memberships,
    required this._userRepository,
    required this._deletions,
    required this._invites,
  });

  final SessionRepository _session;
  final OrganizationDirectory _directory;
  final OrganizationBrandingLoader _brandingLoader;
  final OrganizationBinder _binder;
  final MembershipService _memberships;
  final UserGoogleRepository _userRepository;
  final AccountDeletionRepository _deletions;
  final InvitesRepository _invites;

  bool _running = false;

  /// Continues the Google sign-in that returned [idToken]. [checkDeletion]
  /// false skips the pending deletion (it was just cancelled). [onEntering]
  /// gets the name of the organization being entered, for "Entrando em …".
  Future<Result<void>> afterSignIn(
    String idToken, {
    bool checkDeletion = true,
    void Function(String name)? onEntering,
  }) => _guarded(
    () => _continue(
      idToken,
      checkDeletion: checkDeletion,
      onEntering: onEntering,
    ),
  );

  /// Asks again which organizations the person belongs to, reusing the kept
  /// sign-in when there is one (otherwise Google's chooser shows; nothing
  /// happens when it returns no token). [enter] is the organization that
  /// just became theirs: entered without the picker in between when the
  /// directory lists it (the memberships live in Firestore, so it does at
  /// once); if it does not, the picker shows, never another organization
  /// silently. [welcome] is the invite just accepted: entering its
  /// organization shows *Boas-vindas* first.
  Future<Result<void>> withKeptSignIn({
    String? enter,
    Invite? welcome,
    bool checkDeletion = true,
    void Function(String name)? onEntering,
  }) => _guarded(() async {
    final idToken = await _session.keptOrSignIn();
    if (idToken == null) return;
    await _continue(
      idToken,
      enter: enter,
      welcome: welcome,
      checkDeletion: checkDeletion,
      onEntering: onEntering,
    );
  });

  /// Enters [binding], picked on *Escolher organização*, with the kept
  /// sign-in; nothing without one.
  Future<Result<void>> choose(
    OrganizationBinding binding, {
    void Function(String name)? onEntering,
  }) {
    final idToken = _session.idToken;
    if (idToken == null) return Future.value(const Ok(null));
    return _guarded(() => _enter(binding, idToken, onEntering: onEntering));
  }

  Future<Result<void>> _guarded(Future<void> Function() run) async {
    if (_running) return const Ok(null);
    _running = true;
    try {
      await run();
      return const Ok(null);
    } catch (e, stackTrace) {
      return Err(
        Failure.entry(EntryStage.enter, '$e'),
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _running = false;
    }
  }

  Future<void> _continue(
    String idToken, {
    String? enter,
    Invite? welcome,
    required bool checkDeletion,
    void Function(String name)? onEntering,
  }) async {
    _session.keepIdToken(idToken);
    await _session.readSignedInEmail();
    if (checkDeletion) {
      final deletion = await _pendingDeletion();
      if (deletion != null) {
        _session.moveTo(SessionState.deletionPending(deletion));
        return;
      }
    }
    final candidates = await _directory.organizationsOfSignedInUser();
    if (candidates.isEmpty) {
      _session.moveTo(SessionState.noOrganization(invites: await _mine()));
      return;
    }
    final bindings = await Future.wait(candidates.map(_brandingLoader.load));
    final target = bindings
        .where((b) => b.organization.id == enter)
        .firstOrNull;
    if (target != null) {
      await _enter(target, idToken, welcome: welcome, onEntering: onEntering);
      return;
    }
    _session.moveTo(SessionState.picking(bindings, invites: await _mine()));
  }

  Future<void> _enter(
    OrganizationBinding binding,
    String idToken, {
    Invite? welcome,
    void Function(String name)? onEntering,
  }) async {
    final organization = binding.organization;
    try {
      await _binder.bind(binding);
      onEntering?.call(organization.name);
      await _session.signInToOrganization(idToken);

      // The person's membership first: the rules only let the
      // organization's members read the map or write their own position.
      // A failed read (null) is not evidence of removal.
      final member = await _memberships.isMemberOf(organization.id);
      if (member == false) {
        // Listed by the central directory (`accounts` may lag behind the
        // organization) but no membership here: same outcome as no
        // organization, with the invites the screen already showed.
        await _session.signOutOfOrganization();
        await _binder.forget();
        _session.moveTo(
          SessionState.noOrganization(
            reason: Failure.accessLost(organization.name),
            invites: _shownInvites(),
          ),
        );
        return;
      }

      final user = await _session.saveOrganizationProfile();
      if (user == null) {
        throw StateError('No user after signing in to ${organization.id}.');
      }
      await _userRepository.saveUserGoogleModel(user);

      // The token stays (in memory, until sign-out) so that switching
      // organization does not need Google again while it is still good.
      // Right after accepting an invite to this organization: welcome first.
      _session.moveTo(
        welcome != null && welcome.organizationId == organization.id
            ? SessionState.welcome(welcome)
            : const SessionState.bound(),
      );
    } catch (_) {
      // Never stay bound to an organization the user could not enter.
      await _binder.forget();
      rethrow;
    }
  }

  /// A failing check must not keep anyone out: the account is then
  /// treated as not being deleted.
  Future<AccountDeletion?> _pendingDeletion() async {
    switch (await _deletions.pending()) {
      case Ok(:final value):
        return value;
      case Err(:final error):
        debugPrint('[Account] Could not read the deletion: $error');
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

  /// The invites of the screen the entry started from.
  List<Invite> _shownInvites() => switch (_session.session.value) {
    SessionNoOrganization(:final invites) => invites,
    SessionPicking(:final invites) => invites,
    _ => const [],
  };
}
