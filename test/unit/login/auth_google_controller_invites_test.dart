import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';
import 'package:monamie_app/app/data/firebase/partner_firebase.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/partner/partner_binding.dart';
import 'package:monamie_app/app/data/partner/partner_binding_store.dart';
import 'package:monamie_app/app/data/partner/partner_branding_loader.dart';
import 'package:monamie_app/app/data/partner/partner_directory.dart';
import 'package:monamie_app/app/data/partner/partner_local_data.dart';
import 'package:monamie_app/app/data/partner/partner_session.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/modules/admin/teams/team.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/invites/invites_backend.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';

import '../../support/test_partner.dart';

const String _kHomeRoute = '/home-test';
const String _kIdToken = 'google-id-token';
const String _kCentralEmail = 'ana.souza@monamie.net';

const _kOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
);

const _kRotaSul = PartnerCandidate(id: 'rotasul', options: _kOptions);
const _kRotaSulName = 'Rota Sul';
const _kVerdeMar = PartnerCandidate(id: 'verdemar', options: _kOptions);
const _kAzulCeu = PartnerCandidate(id: 'azulceu', options: _kOptions);

/// Display name of each partner the fake branding loader knows.
const Map<String, String> _kPartnerNames = {
  'rotasul': _kRotaSulName,
  'verdemar': 'Verde Mar',
  'azulceu': 'Azul Céu',
};

/// Claims of a person who shares their location in one team.
const Map<String, Object?> _kShareClaims = {
  'share': ['rotasul01'],
  'watch': <String>[],
  'admin': <String>[],
};

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuthGoogleService implements AuthGoogleService {
  _FakeAuthGoogleService(this.log);

  final List<String> log;
  final String? idToken = _kIdToken;
  final Object? signInError = null;
  final Object? logoutError = null;

  int signInCalls = 0;
  int logoutCalls = 0;
  int signOutOfPartnerCalls = 0;

  @override
  Future<String?> signInGoogle() async {
    signInCalls++;
    log.add('signInGoogle');
    final failure = signInError;
    if (failure != null) throw failure;
    return idToken;
  }

  @override
  Future<String?> refreshGoogleIdToken() async => null;

  @override
  Future<String?> centralEmail() async => _kCentralEmail;

  @override
  Future<void> signInToPartner(String idToken) async {
    log.add('signInToPartner');
  }

  @override
  Future<void> signOutOfPartner() async {
    signOutOfPartnerCalls++;
    log.add('signOutOfPartner');
  }

  @override
  Future<void> logoutGoogle() async {
    logoutCalls++;
    log.add('logoutGoogle');
    final failure = logoutError;
    if (failure != null) throw failure;
  }

  @override
  Future<UserGoogleModel?> savePartnerProfile() async =>
      UserGoogleModel(id: 'uid-123', name: 'Ana Souza', email: _kCentralEmail);

  @override
  Future<String?> getFirebaseIdToken() async => null;

  @override
  Stream<String?> get onWebSignIn => const Stream<String?>.empty();

  @override
  Future<void> ensureInitialized() async {}

  @override
  void dispose() {}
}

class _FakeBrandingLoader implements PartnerBrandingLoader {
  @override
  Future<PartnerBinding> load(PartnerCandidate candidate) async =>
      PartnerBinding(
        partner: PartnerConfig(
          id: candidate.id,
          name: _kPartnerNames[candidate.id] ?? candidate.id,
        ),
        options: candidate.options,
      );

  @override
  Future<PartnerConfig> readBranding(PartnerBinding binding) =>
      throw UnimplementedError('readBranding is not used by the sign-in');
}

class _MemoryBindingStore implements PartnerBindingStore {
  PartnerBinding? binding;

  @override
  Future<PartnerBinding?> read() async => binding;

  @override
  Future<void> write(PartnerBinding value) async => binding = value;

  @override
  Future<void> clear() async => binding = null;
}

/// [PartnerSession] that binds without creating a real [FirebaseApp]: it
/// sets [Partner.current] and a fake [PartnerFirebase] whose `syncClaims`
/// returns [claims].
class _FakePartnerSession extends PartnerSession {
  _FakePartnerSession(this.log, {this.claims})
    : super(store: _MemoryBindingStore());

  final List<String> log;
  final Map<String, Object?>? claims;
  final Object? syncError = null;
  int forgetCalls = 0;

  /// Id of every partner bound, in order.
  final boundIds = <String>[];

  @override
  Future<void> bind(PartnerBinding binding, {bool remember = true}) async {
    log.add('bind');
    boundIds.add(binding.partner.id);
    Partner.bind(binding.partner);
    CurrentPartnerFirebase.set(
      _FakePartnerFirebase(claims: claims ?? const {}, error: syncError),
    );
  }

  @override
  Future<void> forget() async {
    forgetCalls++;
    log.add('forget');
    await super.forget();
  }
}

class _FakePartnerFirebase implements PartnerFirebase {
  _FakePartnerFirebase({required this.claims, this.error});

  final Map<String, Object?> claims;
  final Object? error;

  @override
  FirebaseAuth get auth => _FakeFirebaseAuth();

  @override
  FirebaseFunctions get functions => _FakeFunctions(claims, error);

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  FirebaseStorage get storage => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get partnerData =>
      throw UnimplementedError();
}

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'partner-id-token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFunctions implements FirebaseFunctions {
  _FakeFunctions(this.claims, this.error);

  final Map<String, Object?> claims;
  final Object? error;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _FakeCallable(claims, error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCallable implements HttpsCallable {
  _FakeCallable(this.claims, this.error);

  final Map<String, Object?> claims;
  final Object? error;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    final failure = error;
    if (failure != null) throw failure;
    return _FakeCallableResult<T>(claims as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCallableResult<T> implements HttpsCallableResult<T> {
  _FakeCallableResult(this.data);

  @override
  final T data;
}

class _FakeTrackingStopper implements BackgroundTrackingStopper {
  _FakeTrackingStopper(this.log);

  final List<String> log;

  @override
  Future<bool> stop({String? email}) async {
    log.add('stop');
    return true;
  }
}

class _FakePartnerLocalData implements PartnerLocalData {
  @override
  Future<void> clear() async {}
}

class _FakeUserGoogleRepository implements UserGoogleRepository {
  @override
  Future<UserGoogleModel?> getUserGoogleModel() async => null;

  @override
  Future<String> deleteUserGoogleModel() async => 'ok';

  @override
  Future<String> saveUserGoogleModel(UserGoogleModel user) async => 'ok';

  @override
  Future<GdiGroupsGoogle> getGdiGroupsGoogle(String token, String email) =>
      throw StateError('groups gateway unavailable in tests');

  @override
  Future<UserGoogleModel> createUserDoc(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) => throw UnimplementedError();

  @override
  Future<String> clearAllUserGoogle() => throw UnimplementedError();

  @override
  Future<bool> hasUserGoogle() => throw UnimplementedError();
}

/// [PartnerDirectory] that answers the n-th call with `answers[n]` (the last
/// answer repeats) and records the `fresh` flag of every call.
class _SequencedPartnerDirectory implements PartnerDirectory {
  _SequencedPartnerDirectory(this.answers);

  final List<List<PartnerCandidate>> answers;
  final fresh = <bool>[];

  int get calls => fresh.length;

  @override
  Future<List<PartnerCandidate>> partnersOfSignedInUser({
    bool fresh = false,
  }) async {
    final index = this.fresh.length;
    this.fresh.add(fresh);
    return answers[index < answers.length ? index : answers.length - 1];
  }
}

/// [InvitesBackend] whose `accept` records the invite, optionally waits on
/// [gate] and fails with [failure]; `mine` answers [mineResult] or fails
/// with [mineFailure].
class _FakeInvitesBackend implements InvitesBackend {
  final accepted = <String>[];
  Completer<void>? gate;
  Object? failure;
  List<Invite> mineResult = const [];
  Object? mineFailure;

  @override
  Future<Invite> accept(Invite invite) async {
    accepted.add(invite.id);
    await gate?.future;
    if (failure case final failure?) throw failure;
    return invite;
  }

  @override
  Future<List<Invite>> mine() async {
    if (mineFailure case final failure?) throw failure;
    return mineResult;
  }

  @override
  Future<InviteSendResult> send(
    String partnerId, {
    required String partnerName,
    String? team,
    String? firstTeamName,
    required List<({String email, Set<TeamRole> roles})> invites,
  }) => throw UnimplementedError();

  @override
  Future<List<Invite>> listForTeam(String partnerId, String team) =>
      throw UnimplementedError();

  @override
  Future<void> resend(String partnerId, String inviteId) =>
      throw UnimplementedError();

  @override
  Future<void> cancel(String partnerId, String inviteId) =>
      throw UnimplementedError();
}

final _kOtherInvite = Invite(
  id: 'inv2',
  partnerId: 'verdemar',
  partnerName: 'Verde Mar',
  team: '02',
  teamName: 'Equipe Sul',
  email: _kCentralEmail,
  roles: const {TeamRole.watch},
  invitedByName: 'Caio Prado',
  expiresAt: DateTime.utc(2026, 11, 10, 12),
);

final _kInvite = Invite(
  id: 'inv1',
  partnerId: 'rotasul',
  partnerName: _kRotaSulName,
  team: '01',
  teamName: 'Equipe Norte',
  email: _kCentralEmail,
  roles: const {TeamRole.share},
  invitedByName: 'Rita Lima',
  expiresAt: DateTime.utc(2026, 11, 9, 12),
);

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class _Harness {
  _Harness({
    List<List<PartnerCandidate>> answers = const [
      [_kRotaSul],
    ],
  }) {
    directory = _SequencedPartnerDirectory(answers);
    session = _FakePartnerSession(log, claims: _kShareClaims);
    controller = AuthGoogleController(
      authGoogleService: _FakeAuthGoogleService(log),
      userRepository: _FakeUserGoogleRepository(),
      trackingStopper: _FakeTrackingStopper(log),
      partnerDirectory: directory,
      brandingLoader: _FakeBrandingLoader(),
      partnerSession: session,
      partnerLocalData: _FakePartnerLocalData(),
      invitesBackend: backend,
      refreshTheme: () => log.add('refreshTheme'),
    );
  }

  final List<String> log = <String>[];
  final backend = _FakeInvitesBackend();
  late final _SequencedPartnerDirectory directory;
  late final _FakePartnerSession session;
  late final AuthGoogleController controller;
}

Future<void> _pumpApp(WidgetTester tester) async {
  GetPage<dynamic> page(String name) => GetPage(
    name: name,
    page: () => Scaffold(body: Text(name)),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: _kHomeRoute,
      getPages: [
        page(_kHomeRoute),
        page(Routes.NO_ORGANIZATION),
        page(Routes.PARTNER_PICKER),
        page(Routes.MONAMIE),
        page(Routes.WELCOME),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// Starts accepting [_kInvite] and advances the fake clock until it is over.
Future<void> _accept(WidgetTester tester, AuthGoogleController controller) =>
    _drive(tester, controller, () => controller.acceptInvite(_kInvite));

/// Starts [act] and advances the fake clock one second at a time (the
/// retries wait 4 s each) until the controller is no longer busy.
Future<void> _drive(
  WidgetTester tester,
  AuthGoogleController controller,
  Future<void> Function() act,
) async {
  final done = act();
  for (
    var i = 0;
    i < 60 &&
        (controller.acceptingInvite.value != null ||
            controller.isLoading.value);
    i++
  ) {
    await tester.pump(const Duration(seconds: 1));
  }
  await done;
  // Let any snackbar (the groups gateway is unavailable in tests) close:
  // GetX timers cannot be left pending.
  for (var i = 0; i < 30 && Get.isSnackbarOpen; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    Partner.bind(testPartner);
    CurrentPartnerFirebase.debugReset();
  });

  group('AuthGoogleController.acceptInvite - Unit Test Suite', () {
    testWidgets('Happy Path: accepts the invite through the backend', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final harness = _Harness();
      await _pumpApp(tester);

      // 2. Act
      await _accept(tester, harness.controller);

      // 3. Assert
      expect(harness.backend.accepted, ['inv1']);
    });

    testWidgets('Happy Path: sets welcome to the accepted invite', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final harness = _Harness();
      await _pumpApp(tester);

      // 2. Act
      await _accept(tester, harness.controller);

      // 3. Assert
      expect(harness.controller.welcome.value, same(_kInvite));
    });

    testWidgets(
      'Happy Path: with the partner listed at once, asks fresh and continues into the partner',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness();
        await _pumpApp(tester);

        // 2. Act
        await _accept(tester, harness.controller);

        // 3. Assert
        expect(harness.directory.fresh, isNotEmpty);
        expect(harness.directory.fresh, everyElement(isTrue));
        expect(harness.log, containsAllInOrder(['bind', 'signInToPartner']));
        expect(harness.controller.acceptingInvite.value, isNull);
      },
    );

    testWidgets(
      'Edge Case: asks again, fresh, until the partner shows up on the third try',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          answers: const [
            [],
            [],
            [_kRotaSul],
          ],
        );
        await _pumpApp(tester);

        // 2. Act
        await _accept(tester, harness.controller);

        // 3. Assert
        // Three asks to see the partner, at most one more to continue.
        expect(harness.directory.calls, inInclusiveRange(3, 4));
        expect(harness.directory.fresh, everyElement(isTrue));
        expect(harness.log, contains('bind'));
      },
    );

    testWidgets(
      'Edge Case: stops asking after 6 tries when the partner never shows up',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(answers: const [[]]);
        await _pumpApp(tester);

        // 2. Act
        await _accept(tester, harness.controller);

        // 3. Assert
        // Six retries, at most one more to continue the sign-in.
        expect(harness.directory.calls, inInclusiveRange(6, 7));
        expect(harness.log, isNot(contains('bind')));
        expect(Get.currentRoute, Routes.NO_ORGANIZATION);
      },
    );

    test(
      'Edge Case: a second accept while one is in flight does nothing',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.backend.gate = Completer<void>();
        unawaited(harness.controller.acceptInvite(_kInvite));

        // 2. Act
        await harness.controller.acceptInvite(_kInvite);

        // 3. Assert
        expect(harness.backend.accepted, ['inv1']);
        expect(harness.controller.acceptingInvite.value, 'inv1');
      },
    );

    test(
      'Sad Path: an InvitesException sets inviteError and clears acceptingInvite',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.backend.failure = const InvitesException(
          'Este convite expirou. Peça um novo a quem convidou você.',
        );

        // 2. Act
        await harness.controller.acceptInvite(_kInvite);

        // 3. Assert
        expect(
          harness.controller.inviteError.value,
          'Este convite expirou. Peça um novo a quem convidou você.',
        );
        expect(harness.controller.acceptingInvite.value, isNull);
        expect(harness.directory.calls, 0);
      },
    );
  });

  group('AuthGoogleController pending invites on the picker - Unit Test Suite', () {
    testWidgets(
      'Happy Path: recheckPartners with one partner loads the pending invites',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness();
        harness.backend.mineResult = [_kInvite];
        await _pumpApp(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          harness.controller.recheckPartners,
        );

        // 3. Assert
        expect(harness.controller.pendingInvites, [_kInvite]);
        expect(Get.currentRoute, Routes.PARTNER_PICKER);
      },
    );

    testWidgets(
      'Edge Case: recheckPartners with several partners loads every pending invite',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          answers: const [
            [_kRotaSul, _kVerdeMar],
          ],
        );
        harness.backend.mineResult = [_kInvite, _kOtherInvite];
        await _pumpApp(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          harness.controller.recheckPartners,
        );

        // 3. Assert
        expect(harness.controller.pendingInvites, [_kInvite, _kOtherInvite]);
        expect(Get.currentRoute, Routes.PARTNER_PICKER);
        expect(harness.log, isNot(contains('bind')));
      },
    );

    testWidgets(
      'Sad Path: a failing invite read leaves pendingInvites empty and still opens the picker',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness();
        harness.controller.pendingInvites.add(_kOtherInvite);
        harness.backend.mineFailure = Exception('sem rede');
        await _pumpApp(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          harness.controller.recheckPartners,
        );

        // 3. Assert
        expect(harness.controller.pendingInvites, isEmpty);
        expect(Get.currentRoute, Routes.PARTNER_PICKER);
      },
    );
  });

  group(
    'AuthGoogleController.acceptInvite (several organizations) - Unit Test Suite',
    () {
      testWidgets(
        "Happy Path: binds the invite's partner even when another one is listed first",
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(
            answers: const [
              [_kVerdeMar, _kRotaSul],
            ],
          );
          await _pumpApp(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          expect(harness.session.boundIds, ['rotasul']);
        },
      );

      testWidgets('Happy Path: ends on the welcome screen, not the picker', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _Harness(
          answers: const [
            [_kVerdeMar, _kRotaSul],
          ],
        );
        await _pumpApp(tester);

        // 2. Act
        await _accept(tester, harness.controller);

        // 3. Assert
        expect(Get.currentRoute, Routes.WELCOME);
      });

      testWidgets(
        "Edge Case: binds the invite's partner once it shows up on the third try",
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(
            answers: const [
              [_kVerdeMar],
              [_kVerdeMar],
              [_kVerdeMar, _kRotaSul],
            ],
          );
          await _pumpApp(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          expect(harness.session.boundIds, ['rotasul']);
          expect(Get.currentRoute, Routes.WELCOME);
        },
      );

      testWidgets(
        "Sad Path: opens the picker when the invite's partner never shows up among several others",
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(
            answers: const [
              [_kVerdeMar, _kAzulCeu],
            ],
          );
          await _pumpApp(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          expect(harness.directory.calls, inInclusiveRange(6, 7));
          expect(harness.session.boundIds, isEmpty);
          expect(Get.currentRoute, Routes.PARTNER_PICKER);
        },
      );

      testWidgets(
        "Sad Path: opens the picker when the invite's partner never shows up and one other is listed",
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(
            answers: const [
              [_kVerdeMar],
            ],
          );
          await _pumpApp(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          expect(harness.session.boundIds, isEmpty);
          expect(Get.currentRoute, Routes.PARTNER_PICKER);
        },
      );
    },
  );

  group('AuthGoogleController.enterCreatedOrganization - Unit Test Suite', () {
    testWidgets(
      'Happy Path: binds the created partner when several are listed',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          answers: const [
            [_kRotaSul, _kVerdeMar],
          ],
        );
        await _pumpApp(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          () => harness.controller.enterCreatedOrganization('verdemar'),
        );

        // 3. Assert
        expect(harness.session.boundIds, ['verdemar']);
      },
    );

    testWidgets('Happy Path: ends on MonAmie, not the picker', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final harness = _Harness(
        answers: const [
          [_kRotaSul, _kVerdeMar],
        ],
      );
      await _pumpApp(tester);

      // 2. Act
      await _drive(
        tester,
        harness.controller,
        () => harness.controller.enterCreatedOrganization('verdemar'),
      );

      // 3. Assert
      expect(Get.currentRoute, Routes.MONAMIE);
    });

    testWidgets(
      'Edge Case: binds the created partner once it shows up on the third try',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          answers: const [
            [_kRotaSul],
            [_kRotaSul],
            [_kRotaSul, _kVerdeMar],
          ],
        );
        await _pumpApp(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          () => harness.controller.enterCreatedOrganization('verdemar'),
        );

        // 3. Assert
        expect(harness.directory.fresh, everyElement(isTrue));
        expect(harness.session.boundIds, ['verdemar']);
        expect(Get.currentRoute, Routes.MONAMIE);
      },
    );

    testWidgets(
      'Sad Path: opens the picker when the created partner never shows up among several others',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          answers: const [
            [_kRotaSul, _kAzulCeu],
          ],
        );
        await _pumpApp(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          () => harness.controller.enterCreatedOrganization('verdemar'),
        );

        // 3. Assert
        expect(harness.directory.calls, inInclusiveRange(6, 7));
        expect(harness.session.boundIds, isEmpty);
        expect(Get.currentRoute, Routes.PARTNER_PICKER);
      },
    );

    testWidgets(
      'Sad Path: opens the picker when the created partner never shows up and one other is listed',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness();
        await _pumpApp(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          () => harness.controller.enterCreatedOrganization('verdemar'),
        );

        // 3. Assert
        expect(harness.session.boundIds, isEmpty);
        expect(Get.currentRoute, Routes.PARTNER_PICKER);
      },
    );
  });
}
