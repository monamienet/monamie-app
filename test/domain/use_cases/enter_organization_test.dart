import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/organization/organization_binder.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';
import 'package:monamie_app/data/services/firebase/organization_firebase.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/utils/result.dart';

import '../../support/session_double.dart';
import '../../support/test_organization.dart';

@GenerateNiceMocks([
  MockSpec<AccountDeletionRepository>(),
  MockSpec<InvitesRepository>(),
  MockSpec<MembershipService>(),
  MockSpec<OrganizationBinder>(),
  MockSpec<OrganizationBrandingLoader>(),
  MockSpec<OrganizationDirectory>(),
  MockSpec<OrganizationFirebase>(),
  MockSpec<UserGoogleRepository>(),
])
import 'enter_organization_test.mocks.dart';

const _kIdToken = 'google-id-token';

const _kCentralEmail = 'ana.souza@monamie.net';

const _kLoginErrorTitle = 'Erro de Login';

const _kOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
);

const _kRotaSul = OrganizationCandidate(id: 'rotasul', options: _kOptions);

const _kVerdeMar = OrganizationCandidate(id: 'verdemar', options: _kOptions);

const _kAzulCeu = OrganizationCandidate(id: 'azulceu', options: _kOptions);

/// Display name of each organization the fake branding loader knows.
const Map<String, String> _kNames = {
  'rotasul': 'Rota Sul',
  'verdemar': 'Verde Mar',
  'azulceu': 'Azul Céu',
};

/// What the fake branding loader makes of [candidate].
OrganizationBinding _binding(OrganizationCandidate candidate) =>
    OrganizationBinding(
      organization: OrganizationConfig(
        id: candidate.id,
        name: _kNames[candidate.id] ?? candidate.id,
      ),
      options: candidate.options,
    );

final _kInvite = Invite(
  id: 'inv1',
  organizationId: 'rotasul',
  organizationName: 'Rota Sul',
  groupId: '01',
  groupName: 'Equipe Norte',
  email: _kCentralEmail,
  roles: const {GroupRole.publisher},
  inviterName: 'Rita Lima',
  expiresAt: DateTime.utc(2026, 11, 9, 12),
);

final _kOtherInvite = Invite(
  id: 'inv2',
  organizationId: 'verdemar',
  organizationName: 'Verde Mar',
  groupId: '02',
  groupName: 'Equipe Sul',
  email: _kCentralEmail,
  roles: const {GroupRole.subscriber},
  inviterName: 'Caio Prado',
  expiresAt: DateTime.utc(2026, 11, 10, 12),
);

/// An [Err] titled [title].
Matcher _errTitled(String title) =>
    isA<Err<Object?>>().having((err) => err.title, 'title', title);

/// The dependencies of an [EnterOrganization] under test: the session
/// double and mocks whose calls are written to [log] in order.
class _Harness {
  _Harness({
    List<OrganizationCandidate> organizations = const [],
    bool? member = true,
    String? keptOrSignIn = _kIdToken,
    SessionState initial = const SessionState.signedOut(),
    String? idToken,
  }) : session = SessionDouble(initial: initial, idToken: idToken) {
    final repository = session.repository;
    when(repository.keptOrSignIn()).thenAnswer((_) async {
      log.add('keptOrSignIn');
      return keptOrSignIn;
    });
    when(repository.readSignedInEmail()).thenAnswer((_) async {
      log.add('readSignedInEmail');
    });
    when(repository.signInToOrganization(any)).thenAnswer((_) async {
      log.add('signInToOrganization');
    });
    when(repository.signOutOfOrganization()).thenAnswer((_) async {
      log.add('signOutOfOrganization');
    });
    when(repository.saveOrganizationProfile()).thenAnswer(
      (_) async => UserGoogleModel(
        id: 'uid-123',
        name: 'Ana Souza',
        email: _kCentralEmail,
      ),
    );
    when(repository.signOut()).thenAnswer((_) async => log.add('signOut'));

    when(directory.organizationsOfSignedInUser()).thenAnswer((_) async {
      log.add('directory');
      return organizations;
    });
    when(brandingLoader.load(any)).thenAnswer(
      (invocation) async => _binding(
        invocation.positionalArguments.single as OrganizationCandidate,
      ),
    );
    when(binder.bind(any, remember: anyNamed('remember'))).thenAnswer((
      invocation,
    ) async {
      final binding =
          invocation.positionalArguments.single as OrganizationBinding;
      log.add('bind');
      boundIds.add(binding.organization.id);
      Organization.bind(binding.organization);
      CurrentOrganizationFirebase.set(MockOrganizationFirebase());
    });
    when(binder.forget()).thenAnswer((_) async {
      log.add('forget');
      Organization.unbind();
      CurrentOrganizationFirebase.clear();
    });
    when(memberships.isMemberOf(any)).thenAnswer((_) async {
      log.add('isMemberOf');
      return member;
    });
    when(userRepository.saveUserGoogleModel(any)).thenAnswer((_) async {
      log.add('saveUserGoogleModel');
      return 'ok';
    });
    when(deletions.pending()).thenAnswer((_) async => const Ok(null));
    when(invites.mine()).thenAnswer((_) async => const Ok([]));

    enterOrganization = EnterOrganization(
      session: repository,
      directory: directory,
      brandingLoader: brandingLoader,
      binder: binder,
      memberships: memberships,
      userRepository: userRepository,
      deletions: deletions,
      invites: invites,
    );
  }

  final log = <String>[];

  /// Id of every organization bound, in order.
  final boundIds = <String>[];
  final SessionDouble session;
  final directory = MockOrganizationDirectory();
  final brandingLoader = MockOrganizationBrandingLoader();
  final binder = MockOrganizationBinder();
  final memberships = MockMembershipService();
  final userRepository = MockUserGoogleRepository();
  final deletions = MockAccountDeletionRepository();
  final invites = MockInvitesRepository();
  late final EnterOrganization enterOrganization;
}

void main() {
  provideDummy<Result<List<Invite>>>(const Ok([]));
  provideDummy<Result<Invite>>(Ok(_kInvite));
  provideDummy<Result<AccountDeletion?>>(const Ok(null));
  provideDummy<Result<AccountDeletion>>(
    Ok(AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2))),
  );
  provideDummy<Result<void>>(const Ok(null));

  tearDown(() {
    Organization.bind(testOrganization);
    CurrentOrganizationFirebase.debugReset();
  });

  group('EnterOrganization.afterSignIn - Unit Test Suite', () {
    test('Happy Path: keeps the token and reads the e-mail of the central '
        'account', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(harness.session.idToken, _kIdToken);
      verify(harness.session.repository.readSignedInEmail()).called(1);
    });

    test('Happy Path: several organizations end in picking with their '
        'choices', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul, _kVerdeMar]);

      // 2. Act
      final result = await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(
        harness.session.session.value,
        SessionState.picking([_binding(_kRotaSul), _binding(_kVerdeMar)]),
      );
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
    });

    test('Happy Path: a single organization still ends in picking (a sign-in '
        'just made shows where the person enters)', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(
        harness.session.session.value,
        SessionState.picking([_binding(_kRotaSul)]),
      );
    });

    test('Happy Path: the picker opens with every pending invite', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul, _kVerdeMar]);
      when(
        harness.invites.mine(),
      ).thenAnswer((_) async => Ok([_kInvite, _kOtherInvite]));

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(
        harness.session.session.value,
        SessionState.picking(
          [_binding(_kRotaSul), _binding(_kVerdeMar)],
          invites: [_kInvite, _kOtherInvite],
        ),
      );
    });

    test('Edge Case: the single organization is neither bound nor entered '
        'before the choice', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(harness.log, isNot(contains('bind')));
      expect(harness.log, isNot(contains('signInToOrganization')));
      verifyNever(harness.binder.forget());
    });

    test('Edge Case: no organization ends in noOrganization with the pending '
        'invites, still signed in to MonAmie', () async {
      // 1. Arrange
      final harness = _Harness();
      when(harness.invites.mine()).thenAnswer((_) async => Ok([_kInvite]));

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(
        harness.session.session.value,
        SessionState.noOrganization(invites: [_kInvite]),
      );
      verifyNever(harness.session.repository.signOut());
    });

    test('Edge Case: a pending deletion ends in deletionPending without '
        'looking up organizations', () async {
      // 1. Arrange
      final deletion = AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2));
      final harness = _Harness(organizations: [_kRotaSul]);
      when(harness.deletions.pending()).thenAnswer((_) async => Ok(deletion));

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(
        harness.session.session.value,
        SessionState.deletionPending(deletion),
      );
      verify(harness.deletions.pending()).called(1);
      verifyNever(harness.directory.organizationsOfSignedInUser());
    });

    test('Edge Case: checkDeletion false skips the pending deletion (it was '
        'just cancelled)', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);
      when(harness.deletions.pending()).thenAnswer(
        (_) async => Ok(AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2))),
      );

      // 2. Act
      await harness.enterOrganization.afterSignIn(
        _kIdToken,
        checkDeletion: false,
      );

      // 3. Assert
      verifyNever(harness.deletions.pending());
      expect(harness.session.session.value, isA<SessionPicking>());
    });

    test('Edge Case: a call while another entry runs does nothing and '
        'returns Ok', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);
      final lookup = Completer<List<OrganizationCandidate>>();
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) => lookup.future);
      final first = harness.enterOrganization.afterSignIn(_kIdToken);
      await pumpEventQueue();

      // 2. Act
      final second = await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(second, isA<Ok<void>>());
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
      lookup.complete(const []);
      await first;
    });

    test('Edge Case: once an entry ends another one may start', () async {
      // 1. Arrange
      final harness = _Harness();
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      verify(harness.directory.organizationsOfSignedInUser()).called(2);
    });

    test('Sad Path: an unreadable pending deletion does not keep the person '
        'out: the organizations are looked up as usual', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);
      when(harness.deletions.pending()).thenAnswer(
        (_) async => Err(
          'Não foi possível ler a exclusão da conta.',
          error: Exception('offline'),
        ),
      );

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(harness.session.session.value, isA<SessionPicking>());
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
    });

    test('Sad Path: a failing invite read leaves the invites empty and still '
        'opens the picker', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);
      when(harness.invites.mine()).thenAnswer(
        (_) async => Err(
          'Não foi possível carregar os convites.',
          error: Exception('sem rede'),
        ),
      );

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(
        harness.session.session.value,
        SessionState.picking([_binding(_kRotaSul)]),
      );
    });

    test('Sad Path: a failing organization lookup returns the login error '
        'and leaves the session where it was', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => throw Exception('sem rede'));

      // 2. Act
      final result = await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(result, _errTitled(_kLoginErrorTitle));
      expect(
        result,
        isA<Err<void>>().having(
          (err) => err.message,
          'message',
          startsWith('Não foi possível entrar agora'),
        ),
      );
      expect(harness.session.session.value, const SessionState.signedOut());
      expect(harness.session.moves, isEmpty);
    });

    test('Sad Path: after a failed entry another one may start', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => throw Exception('sem rede'));
      await harness.enterOrganization.afterSignIn(_kIdToken);
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => const []);

      // 2. Act
      await harness.enterOrganization.afterSignIn(_kIdToken);

      // 3. Assert
      expect(
        harness.session.session.value,
        const SessionState.noOrganization(),
      );
    });
  });

  group('EnterOrganization.withKeptSignIn - Unit Test Suite', () {
    test('Happy Path: asks again which organizations the person belongs to, '
        'with the kept sign-in', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);

      // 2. Act
      await harness.enterOrganization.withKeptSignIn();

      // 3. Assert
      verify(harness.session.repository.keptOrSignIn()).called(1);
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
      expect(
        harness.session.session.value,
        SessionState.picking([_binding(_kRotaSul)]),
      );
      expect(harness.log, isNot(contains('bind')));
    });

    test('Happy Path: an organization just created and listed among several '
        'is entered without the picker', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul, _kVerdeMar]);

      // 2. Act
      await harness.enterOrganization.withKeptSignIn(enter: 'verdemar');

      // 3. Assert
      expect(harness.boundIds, ['verdemar']);
      expect(harness.session.session.value, const SessionState.bound());
      expect(harness.session.moves, [const SessionState.bound()]);
    });

    test("Happy Path: the accepted invite's organization is bound even when "
        'another one is listed first, and ends in welcome', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kVerdeMar, _kRotaSul]);

      // 2. Act
      await harness.enterOrganization.withKeptSignIn(
        enter: 'rotasul',
        welcome: _kInvite,
      );

      // 3. Assert
      expect(harness.boundIds, ['rotasul']);
      expect(harness.session.session.value, SessionState.welcome(_kInvite));
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
      expect(harness.log, containsAllInOrder(['bind', 'signInToOrganization']));
    });

    test("Edge Case: an invite of another organization than the one entered "
        'ends bound, not in welcome', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul, _kVerdeMar]);

      // 2. Act
      await harness.enterOrganization.withKeptSignIn(
        enter: 'verdemar',
        welcome: _kInvite,
      );

      // 3. Assert
      expect(harness.session.session.value, const SessionState.bound());
    });

    test('Edge Case: an organization not listed is not waited for: Sem '
        'organização after one ask', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.enterOrganization.withKeptSignIn(
        enter: 'rotasul',
        welcome: _kInvite,
      );

      // 3. Assert
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
      expect(harness.log, isNot(contains('bind')));
      expect(
        harness.session.session.value,
        const SessionState.noOrganization(),
      );
    });

    test('Edge Case: checkDeletion false skips the pending deletion', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);

      // 2. Act
      await harness.enterOrganization.withKeptSignIn(checkDeletion: false);

      // 3. Assert
      verifyNever(harness.deletions.pending());
    });

    for (final (others, description) in [
      ([_kVerdeMar, _kAzulCeu], 'among several others'),
      ([_kVerdeMar], 'and one other is listed'),
    ]) {
      test('Sad Path: opens the picker when the organization to enter never '
          'shows up $description', () async {
        // 1. Arrange
        final harness = _Harness(organizations: others);

        // 2. Act
        await harness.enterOrganization.withKeptSignIn(
          enter: 'rotasul',
          welcome: _kInvite,
        );

        // 3. Assert
        verify(harness.directory.organizationsOfSignedInUser()).called(1);
        expect(harness.boundIds, isEmpty);
        expect(harness.session.session.value, isA<SessionPicking>());
      });
    }

    test('Sad Path: no token (the chooser closed) changes nothing', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul], keptOrSignIn: null);

      // 2. Act
      final result = await harness.enterOrganization.withKeptSignIn();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyNever(harness.directory.organizationsOfSignedInUser());
      expect(harness.session.moves, isEmpty);
    });

    test(
      'Sad Path: a failing Google sign-in returns the login error',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.session.repository.keptOrSignIn(),
        ).thenAnswer((_) async => throw Exception('offline'));

        // 2. Act
        final result = await harness.enterOrganization.withKeptSignIn();

        // 3. Assert
        expect(result, _errTitled(_kLoginErrorTitle));
        verifyNever(harness.directory.organizationsOfSignedInUser());
      },
    );
  });

  group('EnterOrganization.choose - Unit Test Suite', () {
    /// A harness on the picker, with the kept token and [invites] shown.
    _Harness onPicker({bool? member = true, List<Invite> invites = const []}) =>
        _Harness(
          organizations: [_kRotaSul],
          member: member,
          idToken: _kIdToken,
          initial: SessionState.picking([
            _binding(_kRotaSul),
          ], invites: invites),
        );

    test('Happy Path: a member ends bound, signed in to the organization with '
        'their profile saved', () async {
      // 1. Arrange
      final harness = onPicker();
      final entering = <String>[];

      // 2. Act
      final result = await harness.enterOrganization.choose(
        _binding(_kRotaSul),
        onEntering: entering.add,
      );

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(harness.session.session.value, const SessionState.bound());
      verify(harness.binder.bind(_binding(_kRotaSul))).called(1);
      verify(
        harness.session.repository.signInToOrganization(_kIdToken),
      ).called(1);
      expect(entering, ['Rota Sul']);
      expect(
        harness.log,
        containsAllInOrder([
          'bind',
          'signInToOrganization',
          'isMemberOf',
          'saveUserGoogleModel',
        ]),
      );
    });

    test('Edge Case: an unreadable membership (null) is not taken as removal '
        'and still ends bound', () async {
      // 1. Arrange
      final harness = onPicker(member: null);

      // 2. Act
      await harness.enterOrganization.choose(_binding(_kRotaSul));

      // 3. Assert
      expect(harness.session.session.value, const SessionState.bound());
      verifyNever(harness.session.repository.signOutOfOrganization());
    });

    test('Edge Case: a membership gone ends in noOrganization saying the '
        'account has no access, with the invites already shown', () async {
      // 1. Arrange
      final harness = onPicker(member: false, invites: [_kInvite]);

      // 2. Act
      final result = await harness.enterOrganization.choose(
        _binding(_kRotaSul),
      );

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(
        harness.session.session.value,
        SessionState.noOrganization(
          reason: 'Sua conta não tem mais acesso à Rota Sul.',
          invites: [_kInvite],
        ),
      );
    });

    test('Edge Case: a membership gone signs out of the organization project '
        'only and forgets the organization', () async {
      // 1. Arrange
      final harness = onPicker(member: false);

      // 2. Act
      await harness.enterOrganization.choose(_binding(_kRotaSul));

      // 3. Assert
      verify(harness.session.repository.signOutOfOrganization()).called(1);
      verifyNever(harness.session.repository.signOut());
      verify(harness.binder.forget()).called(1);
      expect(Organization.current, isNull);
    });

    test('Edge Case: a membership gone never reaches the map, so the '
        "organization's theme is never applied (#78)", () async {
      // 1. Arrange
      final harness = onPicker(member: false);

      // 2. Act
      await harness.enterOrganization.choose(_binding(_kRotaSul));

      // 3. Assert
      expect(harness.session.moves, hasLength(1));
      expect(harness.session.moves.single, isA<SessionNoOrganization>());
    });

    test('Edge Case: without a kept sign-in nothing happens', () async {
      // 1. Arrange
      final harness = _Harness(organizations: [_kRotaSul]);

      // 2. Act
      final result = await harness.enterOrganization.choose(
        _binding(_kRotaSul),
      );

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyNever(harness.binder.bind(any, remember: anyNamed('remember')));
    });

    test('Edge Case: a choice while another entry runs does nothing', () async {
      // 1. Arrange
      final harness = onPicker();
      final lookup = Completer<List<OrganizationCandidate>>();
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) => lookup.future);
      final recheck = harness.enterOrganization.withKeptSignIn();
      await pumpEventQueue();

      // 2. Act
      final result = await harness.enterOrganization.choose(
        _binding(_kRotaSul),
      );

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyNever(harness.binder.bind(any, remember: anyNamed('remember')));
      lookup.complete(const []);
      await recheck;
    });

    test('Sad Path: an entry that fails after binding returns the login '
        'error, forgets the organization and keeps picking with the same '
        'choices', () async {
      // 1. Arrange
      final harness = onPicker();
      when(
        harness.session.repository.saveOrganizationProfile(),
      ).thenAnswer((_) async => null);

      // 2. Act
      final result = await harness.enterOrganization.choose(
        _binding(_kRotaSul),
      );

      // 3. Assert
      expect(result, _errTitled(_kLoginErrorTitle));
      expect(
        harness.session.session.value,
        SessionState.picking([_binding(_kRotaSul)]),
      );
      verify(harness.binder.forget()).called(1);
      expect(Organization.current, isNull);
    });

    test('Sad Path: a failing organization sign-in forgets the '
        'organization', () async {
      // 1. Arrange
      final harness = onPicker();
      when(
        harness.session.repository.signInToOrganization(any),
      ).thenAnswer((_) async => throw StateError('offline'));

      // 2. Act
      final result = await harness.enterOrganization.choose(
        _binding(_kRotaSul),
      );

      // 3. Assert
      expect(result, _errTitled(_kLoginErrorTitle));
      verify(harness.binder.forget()).called(1);
      expect(harness.session.moves, isEmpty);
    });
  });
}
