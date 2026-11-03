import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/auth/view_models/organization_choice_view_model.dart';
import 'package:monamie_app/utils/result.dart';

import '../../../support/session_double.dart';

@GenerateNiceMocks([
  MockSpec<EnterOrganization>(),
  MockSpec<InvitesRepository>(),
  MockSpec<SignOut>(),
])
import 'organization_choice_view_model_test.mocks.dart';

const _kCentralEmail = 'ana.souza@monamie.net';

const _kLoginErrorTitle = 'Erro de Login';

final _kRotaSul = OrganizationBinding(
  organization: const OrganizationConfig(id: 'rotasul', name: 'Rota Sul'),
  options: const FirebaseOptions(
    apiKey: 'api-key',
    appId: '1:111:android:abc',
    projectId: 'monamienet-rotasul',
    messagingSenderId: '111',
  ),
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

/// An [Err] titled [title] whose message starts with [start].
Matcher _err(String title, String start) => isA<Err<Object?>>()
    .having((err) => err.title, 'title', title)
    .having((err) => err.message, 'message', startsWith(start));

/// The `onEntering` callback passed to the entry.
void Function(String)? _onEntering(Invocation invocation) =>
    invocation.namedArguments[#onEntering] as void Function(String)?;

/// An [OrganizationChoiceViewModel] over a session double that starts on
/// [initial], with the kept [idToken], and mocks: the entry answers [entry]
/// after [pendingEntry] (calling `onEntering` with "Rota Sul" first), the
/// invite accept answers [accept] after [pendingAccept].
class _Harness {
  _Harness({
    SessionState initial = const SessionState.noOrganization(),
    String? idToken = 'google-id-token',
    Result<void> entry = const Ok(null),
    Completer<void>? pendingEntry,
    Result<Invite>? accept,
    Completer<void>? pendingAccept,
  }) : session = SessionDouble(
         initial: initial,
         idToken: idToken,
         signedInEmail: _kCentralEmail,
       ) {
    Future<Result<void>> answer(Invocation invocation) async {
      _onEntering(invocation)?.call('Rota Sul');
      enteringSeen = controller.state.enteringOrganizationName;
      await pendingEntry?.future;
      return entry;
    }

    when(
      enterOrganization.withKeptSignIn(
        enter: anyNamed('enter'),
        welcome: anyNamed('welcome'),
        checkDeletion: anyNamed('checkDeletion'),
        onEntering: anyNamed('onEntering'),
      ),
    ).thenAnswer(answer);
    when(
      enterOrganization.choose(any, onEntering: anyNamed('onEntering')),
    ).thenAnswer(answer);
    when(invites.accept(any)).thenAnswer((invocation) async {
      await pendingAccept?.future;
      return accept ?? Ok(invocation.positionalArguments.single as Invite);
    });
    when(signOut.call()).thenAnswer((_) async => const Ok(true));
    controller = OrganizationChoiceViewModel(
      session: session.repository,
      enterOrganization: enterOrganization,
      signOut: signOut,
      invites: invites,
    );
  }

  final SessionDouble session;
  final enterOrganization = MockEnterOrganization();
  final signOut = MockSignOut();
  final invites = MockInvitesRepository();
  late final OrganizationChoiceViewModel controller;

  /// The organization name the state showed while the entry ran.
  String? enteringSeen;

  /// Verifies the calls of `withKeptSignIn`, capturing `enter` and
  /// `welcome` in pairs.
  List<Object?> keptSignInCalls() => verify(
    enterOrganization.withKeptSignIn(
      enter: captureAnyNamed('enter'),
      welcome: captureAnyNamed('welcome'),
      checkDeletion: anyNamed('checkDeletion'),
      onEntering: anyNamed('onEntering'),
    ),
  ).captured;
}

void main() {
  provideDummy<Result<void>>(const Ok(null));
  provideDummy<Result<bool>>(const Ok(true));
  provideDummy<Result<Invite>>(Ok(_kInvite));

  group('OrganizationChoiceViewModel session - Unit Test Suite', () {
    test('Happy Path: Sem organização opens with the reason, the invites and '
        'the e-mail of the session', () {
      // 1. Arrange
      // 2. Act
      final harness = _Harness(
        initial: SessionState.noOrganization(
          reason: 'Sua conta não tem mais acesso à Rota Sul.',
          invites: [_kInvite],
        ),
      );

      // 3. Assert
      final state = harness.controller.state;
      expect(state.signedInEmail, _kCentralEmail);
      expect(state.noAccessReason, 'Sua conta não tem mais acesso à Rota Sul.');
      expect(state.pendingInvites, [_kInvite]);
      expect(state.organizationChoices, isEmpty);
    });

    test('Happy Path: the picker opens with the choices and the invites of '
        'the session', () {
      // 1. Arrange
      // 2. Act
      final harness = _Harness(
        initial: SessionState.picking([_kRotaSul], invites: [_kInvite]),
      );

      // 3. Assert
      final state = harness.controller.state;
      expect(state.organizationChoices, [_kRotaSul]);
      expect(state.pendingInvites, [_kInvite]);
      expect(state.noAccessReason, isNull);
    });

    test('Edge Case: a new check landing on the picker refreshes what it '
        'shows', () {
      // 1. Arrange
      final harness = _Harness(
        initial: const SessionState.noOrganization(reason: 'Saiu.'),
      );

      // 2. Act
      harness.session.session.value = SessionState.picking(
        [_kRotaSul],
        invites: [_kInvite],
      );

      // 3. Assert
      expect(harness.controller.state.organizationChoices, [_kRotaSul]);
      expect(harness.controller.state.pendingInvites, [_kInvite]);
      expect(harness.controller.state.noAccessReason, isNull);
    });

    test('Edge Case: leaving the screen (any other session) changes '
        'nothing', () {
      // 1. Arrange
      final harness = _Harness(initial: SessionState.picking([_kRotaSul]));
      var notifications = 0;
      harness.controller.addListener(() => notifications++);

      // 2. Act
      harness.session.session.value = const SessionState.bound();

      // 3. Assert
      expect(notifications, 0);
      expect(harness.controller.state.organizationChoices, [_kRotaSul]);
    });

    test('Edge Case: a sign-out running shows isLoggingOut', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.session.leaving.value = SessionExit.signOut;

      // 3. Assert
      expect(harness.controller.state.isLoggingOut, isTrue);
      harness.session.leaving.value = null;
      expect(harness.controller.state.isLoggingOut, isFalse);
    });

    test('Sad Path: a disposed view model stops following the session', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.dispose();

      // 2. Act
      harness.session.session.value = SessionState.picking([_kRotaSul]);

      // 3. Assert
      expect(harness.controller.state.organizationChoices, isEmpty);
    });
  });

  group('OrganizationChoiceViewModel.logout - Unit Test Suite', () {
    test('Happy Path: "Trocar" signs out and returns its result', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final result = await harness.controller.logout.execute();

      // 3. Assert
      expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', true));
      verify(harness.signOut.call()).called(1);
    });

    test('Sad Path: a failing sign-out returns its Err', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.signOut.call(),
      ).thenAnswer((_) async => const Err('Falhou.', title: 'Erro ao sair'));

      // 2. Act
      final result = await harness.controller.logout.execute();

      // 3. Assert
      expect(result, _err('Erro ao sair', 'Falhou.'));
    });
  });

  group(
    'OrganizationChoiceViewModel.recheckOrganizations - Unit Test Suite',
    () {
      test('Happy Path: asks the entry again with the kept sign-in', () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        final result = await harness.controller.recheckOrganizations.execute();

        // 3. Assert
        expect(result, isA<Ok<void>>());
        expect(harness.keptSignInCalls(), [null, null]);
      });

      test('Happy Path: clears noAccessReason', () async {
        // 1. Arrange
        final harness = _Harness(
          initial: const SessionState.noOrganization(reason: 'Saiu.'),
        );

        // 2. Act
        await harness.controller.recheckOrganizations.execute();

        // 3. Assert
        expect(harness.controller.state.noAccessReason, isNull);
      });

      test(
        'Edge Case: isEntering and the organization being entered show while '
        'it runs, and clear after',
        () async {
          // 1. Arrange
          final harness = _Harness();

          // 2. Act
          await harness.controller.recheckOrganizations.execute();

          // 3. Assert
          expect(harness.enteringSeen, 'Rota Sul');
          expect(harness.controller.isEntering, isFalse);
          expect(harness.controller.state.enteringOrganizationName, isNull);
        },
      );

      test(
        'Edge Case: a call while one runs is ignored (reentrancy)',
        () async {
          // 1. Arrange
          final pendingEntry = Completer<void>();
          final harness = _Harness(pendingEntry: pendingEntry);
          final first = harness.controller.recheckOrganizations.execute();
          expect(harness.controller.isEntering, isTrue);

          // 2. Act
          final second = await harness.controller.recheckOrganizations
              .execute();

          // 3. Assert
          expect(second, isNull);
          expect(harness.keptSignInCalls(), hasLength(2));
          pendingEntry.complete();
          await first;
        },
      );

      test(
        'Sad Path: a failing check returns why and turns isEntering off',
        () async {
          // 1. Arrange
          final harness = _Harness(
            entry: Err(
              'Não foi possível entrar agora',
              error: Exception('sem rede'),
            ),
          );

          // 2. Act
          final result = await harness.controller.recheckOrganizations
              .execute();

          // 3. Assert
          expect(
            result,
            _err(_kLoginErrorTitle, 'Não foi possível verificar agora'),
          );
          expect(harness.controller.isEntering, isFalse);
        },
      );
    },
  );

  group('OrganizationChoiceViewModel.chooseOrganization - Unit Test Suite', () {
    test('Happy Path: enters the organization picked', () async {
      // 1. Arrange
      final harness = _Harness(initial: SessionState.picking([_kRotaSul]));

      // 2. Act
      final result = await harness.controller.chooseOrganization.execute(
        _kRotaSul,
      );

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(
        harness.enterOrganization.choose(
          _kRotaSul,
          onEntering: anyNamed('onEntering'),
        ),
      ).called(1);
      expect(harness.enteringSeen, 'Rota Sul');
      expect(harness.controller.isEntering, isFalse);
    });

    test('Edge Case: without a kept sign-in nothing happens', () async {
      // 1. Arrange
      final harness = _Harness(idToken: null);

      // 2. Act
      final result = await harness.controller.chooseOrganization.execute(
        _kRotaSul,
      );

      // 3. Assert
      expect(result, isNull);
      verifyNever(
        harness.enterOrganization.choose(
          any,
          onEntering: anyNamed('onEntering'),
        ),
      );
    });

    test('Edge Case: a second choice while one runs does nothing', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);
      final first = harness.controller.chooseOrganization.execute(_kRotaSul);

      // 2. Act
      final second = await harness.controller.chooseOrganization.execute(
        _kRotaSul,
      );

      // 3. Assert
      expect(second, isNull);
      verify(
        harness.enterOrganization.choose(
          any,
          onEntering: anyNamed('onEntering'),
        ),
      ).called(1);
      pendingEntry.complete();
      await first;
    });

    test('Edge Case: a choice while a new check runs is ignored', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);
      final recheck = harness.controller.recheckOrganizations.execute();

      // 2. Act
      final choice = await harness.controller.chooseOrganization.execute(
        _kRotaSul,
      );

      // 3. Assert
      expect(choice, isNull);
      verifyNever(
        harness.enterOrganization.choose(
          any,
          onEntering: anyNamed('onEntering'),
        ),
      );
      pendingEntry.complete();
      await recheck;
    });

    test('Edge Case: a new check while a choice runs is ignored', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);
      final choice = harness.controller.chooseOrganization.execute(_kRotaSul);
      expect(harness.controller.isEntering, isTrue);

      // 2. Act
      final recheck = await harness.controller.recheckOrganizations.execute();

      // 3. Assert
      expect(recheck, isNull);
      verifyNever(
        harness.enterOrganization.withKeptSignIn(
          enter: anyNamed('enter'),
          welcome: anyNamed('welcome'),
          checkDeletion: anyNamed('checkDeletion'),
          onEntering: anyNamed('onEntering'),
        ),
      );
      pendingEntry.complete();
      await choice;
    });

    test('Sad Path: a failing entry says which organization could not be '
        'entered', () async {
      // 1. Arrange
      final harness = _Harness(
        entry: Err('Não foi possível entrar agora', error: Exception('x')),
      );

      // 2. Act
      final result = await harness.controller.chooseOrganization.execute(
        _kRotaSul,
      );

      // 3. Assert
      expect(
        result,
        _err(_kLoginErrorTitle, 'Não foi possível entrar em Rota Sul'),
      );
      expect(harness.controller.isEntering, isFalse);
    });
  });

  group('OrganizationChoiceViewModel.acceptInvite - Unit Test Suite', () {
    test('Happy Path: accepts the invite through the repository', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.controller.acceptInvite.execute(_kInvite);

      // 3. Assert
      verify(harness.invites.accept(_kInvite)).called(1);
    });

    test("Happy Path: then enters the invite's organization with the invite "
        'to welcome', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.controller.acceptInvite.execute(_kInvite);

      // 3. Assert
      expect(harness.keptSignInCalls(), ['rotasul', _kInvite]);
      expect(harness.controller.acceptingInvite, isNull);
      expect(harness.controller.state.inviteError, isEmpty);
    });

    test('Edge Case: acceptingInvite holds the invite while it runs', () async {
      // 1. Arrange
      final pendingAccept = Completer<void>();
      final harness = _Harness(pendingAccept: pendingAccept);

      // 2. Act
      final accepting = harness.controller.acceptInvite.execute(_kInvite);

      // 3. Assert
      expect(harness.controller.acceptingInvite, 'inv1');
      pendingAccept.complete();
      await accepting;
      expect(harness.controller.acceptingInvite, isNull);
    });

    test(
      'Edge Case: a second accept while one is in flight does nothing',
      () async {
        // 1. Arrange
        final pendingAccept = Completer<void>();
        final harness = _Harness(pendingAccept: pendingAccept);
        final first = harness.controller.acceptInvite.execute(_kInvite);

        // 2. Act
        final second = await harness.controller.acceptInvite.execute(_kInvite);

        // 3. Assert
        expect(second, isNull);
        verify(harness.invites.accept(_kInvite)).called(1);
        expect(harness.controller.acceptingInvite, 'inv1');
        pendingAccept.complete();
        await first;
      },
    );

    test('Edge Case: an accept while an organization is being entered is '
        'ignored', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);
      final choice = harness.controller.chooseOrganization.execute(_kRotaSul);

      // 2. Act
      final accept = await harness.controller.acceptInvite.execute(_kInvite);

      // 3. Assert
      expect(accept, isNull);
      expect(harness.controller.acceptingInvite, isNull);
      verifyNever(harness.invites.accept(any));
      pendingEntry.complete();
      await choice;
    });

    test('Sad Path: a refused invite sets inviteError, clears acceptingInvite '
        'and enters nothing', () async {
      // 1. Arrange
      final harness = _Harness(
        accept: const Err(
          'Este convite expirou. Peça um novo a quem convidou você.',
        ),
      );

      // 2. Act
      final result = await harness.controller.acceptInvite.execute(_kInvite);

      // 3. Assert
      expect(
        result,
        isA<Err<void>>().having(
          (err) => err.message,
          'message',
          'Este convite expirou. Peça um novo a quem convidou você.',
        ),
      );
      expect(
        harness.controller.state.inviteError,
        'Este convite expirou. Peça um novo a quem convidou você.',
      );
      expect(harness.controller.acceptingInvite, isNull);
      verifyNever(
        harness.enterOrganization.withKeptSignIn(
          enter: anyNamed('enter'),
          welcome: anyNamed('welcome'),
          checkDeletion: anyNamed('checkDeletion'),
          onEntering: anyNamed('onEntering'),
        ),
      );
      expect(harness.session.moves, isEmpty);
    });

    test('Sad Path: an entry failing after joining shows a generic '
        'message', () async {
      // 1. Arrange
      final harness = _Harness(
        entry: Err('Não foi possível entrar agora', error: Exception('x')),
      );

      // 2. Act
      final result = await harness.controller.acceptInvite.execute(_kInvite);

      // 3. Assert
      expect(
        result,
        isA<Err<void>>().having(
          (err) => err.message,
          'message',
          'Não foi possível aceitar agora. Verifique a conexão e tente de novo.',
        ),
      );
      expect(
        harness.controller.state.inviteError,
        'Não foi possível aceitar agora. Verifique a conexão e tente de novo.',
      );
      expect(harness.controller.acceptingInvite, isNull);
    });

    test('Sad Path: a new accept clears the last error', () async {
      // 1. Arrange
      final harness = _Harness(accept: const Err('Este convite expirou.'));
      await harness.controller.acceptInvite.execute(_kInvite);
      when(harness.invites.accept(any)).thenAnswer((_) async => Ok(_kInvite));

      // 2. Act
      await harness.controller.acceptInvite.execute(_kInvite);

      // 3. Assert
      expect(harness.controller.state.inviteError, isEmpty);
    });
  });
}
