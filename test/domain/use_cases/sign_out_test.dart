import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
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
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

import '../../support/session_double.dart';
import '../../support/test_organization.dart';

@GenerateNiceMocks([
  MockSpec<BackgroundTrackingStopper>(),
  MockSpec<InvitesRepository>(),
  MockSpec<NoticePresenter>(),
  MockSpec<OrganizationBinder>(),
  MockSpec<OrganizationBrandingLoader>(),
  MockSpec<OrganizationDirectory>(),
  MockSpec<OrganizationLocalData>(),
  MockSpec<SharingResumeRepository>(),
  MockSpec<UserGoogleRepository>(),
])
import 'sign_out_test.mocks.dart';

const _kStoredEmail = 'ana.souza@monamie.net';

const _kFreshToken = 'fresh-token';

const _kOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
);

const _kRotaSul = OrganizationCandidate(id: 'rotasul', options: _kOptions);

const _kRotaSulConfig = OrganizationConfig(id: 'rotasul', name: 'Rota Sul');

/// What the fake branding loader makes of [candidate].
OrganizationBinding _binding(OrganizationCandidate candidate) =>
    OrganizationBinding(
      organization: OrganizationConfig(id: candidate.id, name: 'Rota Sul'),
      options: candidate.options,
    );

final _kInvite = Invite(
  id: 'inv1',
  organizationId: 'verdemar',
  organizationName: 'Verde Mar',
  groupId: '01',
  groupName: 'Equipe Norte',
  email: _kStoredEmail,
  roles: const {GroupRole.publisher},
  inviterName: 'Rita Lima',
  expiresAt: DateTime.utc(2026, 11, 9, 12),
);

UserGoogleModel _storedUser() =>
    UserGoogleModel(id: 'uid-123', name: 'Ana Souza', email: _kStoredEmail);

/// An [Err] whose failure matches [failure].
Matcher _errWith(Object failure) =>
    isA<Err<Object?>>().having((err) => err.failure, 'failure', failure);

/// The notice of a failed sign-out ("Erro ao sair" on screen).
final Matcher _signOutFailedNotice = isA<FailureNotice>().having(
  (notice) => notice.failure,
  'failure',
  isA<SignOutFailure>(),
);

/// The dependencies of a [SignOut] under test, starting on the map: the
/// session double and mocks whose calls are written to [log] in order (each
/// move of the session as `move:<variant>`).
class _Harness {
  _Harness({
    UserGoogleModel? storedUser,
    Object? getUserError,
    Object? deleteError,
    bool stopResult = true,
    Completer<bool>? pendingStop,
    Object? logoutError,
    Object? clearIntentError,
    List<OrganizationCandidate> organizations = const [_kRotaSul],
    String? freshToken = _kFreshToken,
  }) : session = SessionDouble(initial: const SessionState.bound()) {
    final repository = session.repository;
    session.session.addListener(
      () => log.add('move:${session.session.value.runtimeType}'),
    );
    when(repository.signOut()).thenAnswer((_) async {
      log.add('signOut');
      if (logoutError != null) throw logoutError;
    });
    when(repository.signOutOfOrganization()).thenAnswer((_) async {
      log.add('signOutOfOrganization');
    });
    when(repository.freshIdToken()).thenAnswer((_) async {
      log.add('freshIdToken');
      return freshToken;
    });
    when(
      repository.signInGoogle(onAccountChosen: anyNamed('onAccountChosen')),
    ).thenAnswer((_) async => null);

    when(stopper.stop(email: anyNamed('email'))).thenAnswer((_) {
      log.add('stop');
      return pendingStop?.future ?? Future<bool>.value(stopResult);
    });
    when(userRepository.getUserGoogleModel()).thenAnswer((_) async {
      if (getUserError != null) throw getUserError;
      return storedUser;
    });
    when(userRepository.deleteUserGoogleModel()).thenAnswer((_) async {
      log.add('deleteUserGoogleModel');
      if (deleteError != null) throw deleteError;
      return 'ok';
    });
    when(binder.forget()).thenAnswer((_) async => log.add('forget'));
    when(localData.clear()).thenAnswer((_) async => log.add('clear'));
    when(directory.organizationsOfSignedInUser()).thenAnswer((_) async {
      log.add('directory');
      return organizations;
    });
    when(brandingLoader.load(any)).thenAnswer(
      (invocation) async => _binding(
        invocation.positionalArguments.single as OrganizationCandidate,
      ),
    );
    when(invites.mine()).thenAnswer((_) async => const Ok([]));
    when(sharingResume.clearIntent()).thenAnswer((_) async {
      log.add('clearIntent');
      if (clearIntentError != null) throw clearIntentError;
    });

    signOut = SignOut(
      session: repository,
      trackingStopper: stopper,
      userRepository: userRepository,
      binder: binder,
      localData: localData,
      directory: directory,
      brandingLoader: brandingLoader,
      invites: invites,
      sharingResume: sharingResume,
      notices: notices,
    );
  }

  final log = <String>[];
  final SessionDouble session;
  final stopper = MockBackgroundTrackingStopper();
  final userRepository = MockUserGoogleRepository();
  final binder = MockOrganizationBinder();
  final localData = MockOrganizationLocalData();
  final directory = MockOrganizationDirectory();
  final brandingLoader = MockOrganizationBrandingLoader();
  final invites = MockInvitesRepository();
  final sharingResume = MockSharingResumeRepository();
  final notices = MockNoticePresenter();
  late final SignOut signOut;

  /// E-mails passed to `stop` since the last verification.
  List<Object?> stoppedEmails() =>
      verify(stopper.stop(email: captureAnyNamed('email'))).captured;
}

/// The steps of a sign-out that finished, in order.
const _kSignOutSteps = [
  'stop',
  'clearIntent',
  'signOut',
  'deleteUserGoogleModel',
  'forget',
  'clear',
];

void main() {
  provideDummy<Result<List<Invite>>>(const Ok([]));

  tearDown(() => Organization.bind(testOrganization));

  group('SignOut.call - Unit Test Suite', () {
    test('Happy Path: stops the tracking with the e-mail of the saved '
        'user', () async {
      // 1. Arrange
      final harness = _Harness(storedUser: _storedUser());

      // 2. Act
      await harness.signOut();

      // 3. Assert
      expect(harness.stoppedEmails(), [_kStoredEmail]);
    });

    test('Happy Path: stops the tracking before signing out, then forgets '
        'the organization and only then moves to Login', () async {
      // 1. Arrange
      final harness = _Harness(storedUser: _storedUser());

      // 2. Act
      await harness.signOut();

      // 3. Assert
      expect(harness.log, [..._kSignOutSteps, 'move:SessionSignedOut']);
      expect(harness.session.session.value, const SessionState.signedOut());
    });

    test('Happy Path: finishes with Ok(true) and no warning when the tracking '
        'stops normally', () async {
      // 1. Arrange
      final harness = _Harness(storedUser: _storedUser());

      // 2. Act
      final result = await harness.signOut();

      // 3. Assert
      expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', true));
      verifyNever(harness.notices.show(any));
    });

    test('Happy Path: leaving is a sign-out while it runs and clear after, '
        'never a switch', () async {
      // 1. Arrange
      final harness = _Harness(storedUser: _storedUser());

      // 2. Act
      await harness.signOut();

      // 3. Assert
      expect(harness.session.leavingHistory, [SessionExit.signOut, null]);
      expect(harness.session.leaving.value, isNull);
    });

    test('Edge Case: stops with a null e-mail and goes on when no user is '
        'saved', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.signOut();

      // 3. Assert
      expect(harness.stoppedEmails(), [null]);
      expect(harness.log, [..._kSignOutSteps, 'move:SessionSignedOut']);
    });

    test('Edge Case: keeps leaving set and signs out nothing while the '
        'tracking stop runs', () async {
      // 1. Arrange
      final pendingStop = Completer<bool>();
      final harness = _Harness(
        storedUser: _storedUser(),
        pendingStop: pendingStop,
      );

      // 2. Act
      final running = harness.signOut();
      await pumpEventQueue();

      // 3. Assert
      expect(harness.session.leaving.value, SessionExit.signOut);
      verifyNever(harness.session.repository.signOut());
      verifyNever(harness.userRepository.deleteUserGoogleModel());
      pendingStop.complete(true);
      await running;
    });

    test('Edge Case: a second sign-out while the first runs returns '
        'Ok(false) and stops nothing again', () async {
      // 1. Arrange
      final pendingStop = Completer<bool>();
      final harness = _Harness(
        storedUser: _storedUser(),
        pendingStop: pendingStop,
      );
      final first = harness.signOut();
      await pumpEventQueue();

      // 2. Act
      final second = await harness.signOut();

      // 3. Assert
      expect(second, isA<Ok<bool>>().having((ok) => ok.value, 'value', false));
      verify(harness.stopper.stop(email: anyNamed('email'))).called(1);
      pendingStop.complete(true);
      await first;
    });

    test('Edge Case: two sign-outs at once stop the tracking and sign out a '
        'single time', () async {
      // 1. Arrange
      final harness = _Harness(storedUser: _storedUser());

      // 2. Act
      await Future.wait([harness.signOut(), harness.signOut()]);

      // 3. Assert
      verify(harness.stopper.stop(email: anyNamed('email'))).called(1);
      verify(harness.session.repository.signOut()).called(1);
    });

    test('Sad Path: stops with a null e-mail and goes on when the saved user '
        'cannot be read', () async {
      // 1. Arrange
      final harness = _Harness(
        getUserError: StateError('box do Hive indisponível'),
      );

      // 2. Act
      await harness.signOut();

      // 3. Assert
      expect(harness.stoppedEmails(), [null]);
      expect(harness.log, [..._kSignOutSteps, 'move:SessionSignedOut']);
    });

    test('Sad Path: signs out and moves to Login even when the tracking stop '
        'is not confirmed, warning "Rastreamento"', () async {
      // 1. Arrange
      final harness = _Harness(storedUser: _storedUser(), stopResult: false);

      // 2. Act
      await harness.signOut();

      // 3. Assert
      expect(harness.log, [..._kSignOutSteps, 'move:SessionSignedOut']);
      verify(
        harness.notices.show(
          argThat(equals(const UserNotice.trackingStopUnconfirmed())),
        ),
      ).called(1);
    });

    test('Sad Path: a failing Google sign-out returns Err "Erro ao sair", '
        'keeps the saved user and the session, and clears leaving', () async {
      // 1. Arrange
      final harness = _Harness(
        storedUser: _storedUser(),
        logoutError: Exception('falha de rede no signOut'),
      );

      // 2. Act
      final result = await harness.signOut();

      // 3. Assert
      expect(result, _errWith(isA<SignOutFailure>()));
      verifyNever(harness.userRepository.deleteUserGoogleModel());
      expect(harness.session.session.value, const SessionState.bound());
      expect(harness.session.moves, isEmpty);
      expect(harness.session.leaving.value, isNull);
    });

    test('Sad Path: a failing cleanup of the saved user returns an Err '
        'instead of throwing and clears leaving', () async {
      // 1. Arrange
      final harness = _Harness(
        storedUser: _storedUser(),
        deleteError: StateError('falha ao apagar o box do Hive'),
      );

      // 2. Act
      final result = await harness.signOut();

      // 3. Assert
      expect(result, _errWith(isA<SignOutFailure>()));
      expect(harness.session.leaving.value, isNull);
    });
  });

  group('SignOut.afterAccessLost - Unit Test Suite', () {
    test('Happy Path: ends in noOrganization saying the person is no longer '
        'part of the organization', () async {
      // 1. Arrange
      final harness = _Harness();
      Organization.bind(_kRotaSulConfig);

      // 2. Act
      await harness.signOut.afterAccessLost();

      // 3. Assert
      expect(
        harness.session.session.value,
        const SessionState.noOrganization(
          reason: Failure.removedFromOrganization('Rota Sul'),
        ),
      );
    });

    test('Happy Path: stops the tracking before signing out, as "Sair" '
        'does', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.signOut.afterAccessLost();

      // 3. Assert
      expect(harness.log, [..._kSignOutSteps, 'move:SessionNoOrganization']);
    });

    test('Edge Case: says "desta organização" when no organization is '
        'bound', () async {
      // 1. Arrange
      final harness = _Harness();
      Organization.unbind();

      // 2. Act
      await harness.signOut.afterAccessLost();

      // 3. Assert
      expect(
        harness.session.session.value,
        const SessionState.noOrganization(
          reason: Failure.removedFromOrganization(null),
        ),
      );
    });

    test('Edge Case: Sem organização opens with no invites (the account is '
        'signed out)', () async {
      // 1. Arrange
      final harness = _Harness();
      when(harness.invites.mine()).thenAnswer((_) async => Ok([_kInvite]));

      // 2. Act
      await harness.signOut.afterAccessLost();

      // 3. Assert
      verifyNever(harness.invites.mine());
      expect(
        (harness.session.session.value as SessionNoOrganization).invites,
        isEmpty,
      );
    });

    test(
      'Sad Path: a failing sign-out stays on the map and shows why',
      () async {
        // 1. Arrange
        final harness = _Harness(logoutError: Exception('falha de rede'));

        // 2. Act
        await harness.signOut.afterAccessLost();

        // 3. Assert
        expect(harness.session.session.value, const SessionState.bound());
        verify(harness.notices.show(argThat(_signOutFailedNotice))).called(1);
      },
    );
  });

  group('SignOut.afterAccountDeleted - Unit Test Suite', () {
    test('Happy Path: signs out of everything and ends in deletionPending '
        'with the deletion', () async {
      // 1. Arrange
      final harness = _Harness();
      final deletion = AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2));

      // 2. Act
      await harness.signOut.afterAccountDeleted(deletion);

      // 3. Assert
      expect(
        harness.session.session.value,
        SessionState.deletionPending(deletion),
      );
      verify(harness.session.repository.signOut()).called(1);
      expect(harness.log.first, 'stop');
    });

    test('Edge Case: a bound organization owned without a name in the '
        'registry is named after its display name', () async {
      // 1. Arrange
      final harness = _Harness();
      Organization.bind(_kRotaSulConfig);
      final deletion = AccountDeletion(
        deleteAt: DateTime.utc(2026, 12, 2),
        ownedOrganizationIds: const ['rotasul'],
      );

      // 2. Act
      await harness.signOut.afterAccountDeleted(deletion);

      // 3. Assert
      expect(
        harness.session.session.value,
        SessionState.deletionPending(
          deletion.copyWith(
            ownedOrganizationNames: const {'rotasul': 'Rota Sul'},
          ),
        ),
      );
    });

    test('Edge Case: a name from the registry is kept as it came', () async {
      // 1. Arrange
      final harness = _Harness();
      Organization.bind(_kRotaSulConfig);
      final deletion = AccountDeletion(
        deleteAt: DateTime.utc(2026, 12, 2),
        ownedOrganizationIds: const ['rotasul'],
        ownedOrganizationNames: const {'rotasul': 'Rota Sul Ltda'},
      );

      // 2. Act
      await harness.signOut.afterAccountDeleted(deletion);

      // 3. Assert
      expect(
        harness.session.session.value,
        SessionState.deletionPending(deletion),
      );
    });

    test(
      'Sad Path: a failing sign-out stays on the map and shows why',
      () async {
        // 1. Arrange
        final harness = _Harness(logoutError: Exception('offline'));

        // 2. Act
        await harness.signOut.afterAccountDeleted(
          AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2)),
        );

        // 3. Assert
        expect(harness.session.session.value, const SessionState.bound());
        verify(harness.notices.show(argThat(_signOutFailedNotice))).called(1);
      },
    );
  });

  group('SignOut.switchOrganization - Unit Test Suite', () {
    test("Happy Path: opens the picker with the person's organizations and "
        'the pending invites', () async {
      // 1. Arrange
      final harness = _Harness();
      when(harness.invites.mine()).thenAnswer((_) async => Ok([_kInvite]));

      // 2. Act
      final result = await harness.signOut.switchOrganization();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(
        harness.session.session.value,
        SessionState.picking([_binding(_kRotaSul)], invites: [_kInvite]),
      );
    });

    test('Happy Path: looks the organizations up before stopping the tracking '
        'and forgetting the organization, and moves only after', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.signOut.switchOrganization();

      // 3. Assert
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
      expect(harness.log, [
        'freshIdToken',
        'directory',
        'stop',
        'clearIntent',
        'signOutOfOrganization',
        'deleteUserGoogleModel',
        'forget',
        'clear',
        'move:SessionPicking',
      ]);
    });

    test('Happy Path: keeps the Google sign-in, without signing out or '
        "showing Google's chooser, and keeps the token used", () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.signOut.switchOrganization();

      // 3. Assert
      verifyNever(harness.session.repository.signOut());
      verifyNever(
        harness.session.repository.signInGoogle(
          onAccountChosen: anyNamed('onAccountChosen'),
        ),
      );
      expect(harness.session.idToken, _kFreshToken);
    });

    test(
      'Happy Path: leaving is a switch while it runs and clear after',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        await harness.signOut.switchOrganization();

        // 3. Assert
        expect(harness.session.leavingHistory, [
          SessionExit.switchOrganization,
          null,
        ]);
      },
    );

    test('Edge Case: nothing left ends in noOrganization, still signed in to '
        'MonAmie', () async {
      // 1. Arrange
      final harness = _Harness(organizations: const []);

      // 2. Act
      await harness.signOut.switchOrganization();

      // 3. Assert
      expect(
        harness.session.session.value,
        const SessionState.noOrganization(),
      );
      verifyNever(harness.session.repository.signOut());
    });

    test('Edge Case: does nothing while a sign-out runs', () async {
      // 1. Arrange
      final pendingStop = Completer<bool>();
      final harness = _Harness(pendingStop: pendingStop);
      final logout = harness.signOut();
      await pumpEventQueue();
      harness.log.clear();
      harness.session.leavingHistory.clear();

      // 2. Act
      final result = await harness.signOut.switchOrganization();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(harness.log, isEmpty);
      expect(harness.session.leavingHistory, isEmpty);
      verifyNever(harness.session.repository.freshIdToken());
      verifyNever(harness.directory.organizationsOfSignedInUser());
      pendingStop.complete(true);
      await logout;
    });

    test('Sad Path: with no valid token nor a renewal it changes nothing and '
        'returns Err "Trocar de organização"', () async {
      // 1. Arrange
      final harness = _Harness(freshToken: null);

      // 2. Act
      final result = await harness.signOut.switchOrganization();

      // 3. Assert
      expect(result, _errWith(const Failure.googleRenewal()));
      expect(harness.log, ['freshIdToken']);
      expect(harness.session.leavingHistory, isEmpty);
      expect(harness.session.session.value, const SessionState.bound());
    });

    test('Sad Path: a failing lookup stops nothing, forgets nothing, keeps '
        'the session bound and returns Err "Trocar de organização"', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => throw Exception('sem rede'));

      // 2. Act
      final result = await harness.signOut.switchOrganization();

      // 3. Assert
      expect(
        result,
        _errWith(const Failure.connection(FailedAction.switchOrganization)),
      );
      expect(
        harness.log.where(
          (e) =>
              e == 'stop' ||
              e == 'clearIntent' ||
              e == 'signOutOfOrganization' ||
              e == 'forget',
        ),
        isEmpty,
      );
      expect(harness.session.session.value, const SessionState.bound());
      expect(harness.session.leavingHistory, [
        SessionExit.switchOrganization,
        null,
      ]);
    });
  });

  group('SignOut - sharing intent - Unit Test Suite', () {
    test('Happy Path: "Sair" forgets who was sharing right after stopping '
        'the tracking, before signing out', () async {
      // 1. Arrange
      final harness = _Harness(storedUser: _storedUser());

      // 2. Act
      await harness.signOut();

      // 3. Assert
      verify(harness.sharingResume.clearIntent()).called(1);
      expect(harness.log.take(3), ['stop', 'clearIntent', 'signOut']);
    });

    test('Happy Path: losing access forgets who was sharing', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.signOut.afterAccessLost();

      // 3. Assert
      verify(harness.sharingResume.clearIntent()).called(1);
    });

    test('Happy Path: deleting the account forgets who was sharing', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.signOut.afterAccountDeleted(
        AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2)),
      );

      // 3. Assert
      verify(harness.sharingResume.clearIntent()).called(1);
    });

    test('Happy Path: switching organization forgets who was sharing before '
        'leaving the organization', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.signOut.switchOrganization();

      // 3. Assert
      verify(harness.sharingResume.clearIntent()).called(1);
      expect(
        harness.log.indexOf('clearIntent'),
        lessThan(harness.log.indexOf('signOutOfOrganization')),
      );
    });

    test('Edge Case: forgets who was sharing even when the tracking stop is '
        'not confirmed', () async {
      // 1. Arrange
      final harness = _Harness(storedUser: _storedUser(), stopResult: false);

      // 2. Act
      await harness.signOut();

      // 3. Assert
      verify(harness.sharingResume.clearIntent()).called(1);
    });

    test('Edge Case: a sign-out ignored while another runs forgets nothing '
        'more', () async {
      // 1. Arrange
      final pendingStop = Completer<bool>();
      final harness = _Harness(pendingStop: pendingStop);
      final first = harness.signOut();
      await pumpEventQueue();

      // 2. Act
      await harness.signOut();
      pendingStop.complete(true);
      await first;

      // 3. Assert
      verify(harness.sharingResume.clearIntent()).called(1);
    });

    test('Sad Path: a failing clear does not break "Sair": it still signs '
        'out, forgets the organization and returns Ok(true)', () async {
      // 1. Arrange
      final harness = _Harness(
        storedUser: _storedUser(),
        clearIntentError: StateError('SharedPreferences indisponível'),
      );

      // 2. Act
      final result = await harness.signOut();

      // 3. Assert
      expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', true));
      expect(harness.log, [..._kSignOutSteps, 'move:SessionSignedOut']);
      verifyNever(harness.notices.show(any));
    });

    test('Sad Path: a failing clear does not break the switch of '
        'organization', () async {
      // 1. Arrange
      final harness = _Harness(
        clearIntentError: StateError('SharedPreferences indisponível'),
      );

      // 2. Act
      final result = await harness.signOut.switchOrganization();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(
        harness.session.session.value,
        SessionState.picking([_binding(_kRotaSul)]),
      );
    });
  });
}
