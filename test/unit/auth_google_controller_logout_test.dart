import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/partner/partner_binding.dart';
import 'package:monamie_app/app/data/partner/partner_binding_store.dart';
import 'package:monamie_app/app/data/partner/partner_local_data.dart';
import 'package:monamie_app/app/data/partner/partner_session.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';

/// Rota fictícia usada como tela inicial (equivalente à tela principal).
const String _kHomeRoute = '/home-test';
const String _kHomePlaceholder = 'home-placeholder';
const String _kLoginPlaceholder = 'login-placeholder';
const String _kStoredEmail = 'ana.souza@monamie.net';

// Entradas do registro compartilhado de chamadas, usado para verificar a
// ordem das operações do logout.
const String _kLogStop = 'stop';
const String _kLogSignOut = 'logoutGoogle';
const String _kLogDeleteUser = 'deleteUserGoogleModel';
const String _kLogNavigateLogin = 'push:${Routes.LOGIN}';

/// Fake do contrato de parada do rastreamento.
class _FakeTrackingStopper implements BackgroundTrackingStopper {
  _FakeTrackingStopper(this.log, {this.result = true, this.pending});

  final List<String> log;
  final bool result;

  /// Quando informado, `stop` só conclui quando este completer completar.
  final Completer<bool>? pending;

  final List<String?> emails = <String?>[];

  int get calls => emails.length;

  @override
  Future<bool> stop({String? email}) {
    emails.add(email);
    log.add(_kLogStop);
    final waiting = pending;
    if (waiting != null) return waiting.future;
    return Future<bool>.value(result);
  }
}

/// Fake do AuthGoogleService. Usa `implements` para não executar o construtor
/// real (que acessa GoogleSignIn e Firebase).
class _FakeAuthGoogleService implements AuthGoogleService {
  _FakeAuthGoogleService(this.log, {this.logoutError});

  final List<String> log;
  final Object? logoutError;
  int logoutCalls = 0;

  @override
  Future<void> logoutGoogle() async {
    logoutCalls++;
    log.add(_kLogSignOut);
    final failure = logoutError;
    if (failure != null) throw failure;
  }

  @override
  Stream<String?> get onWebSignIn => const Stream<String?>.empty();

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<String?> signInGoogle() async => null;

  @override
  Future<void> signInToPartner(String idToken) async {}

  @override
  Future<UserGoogleModel?> savePartnerProfile() async => null;

  @override
  Future<String?> getFirebaseIdToken() async => null;

  @override
  void dispose() {}
}

/// Armazenamento em memória do vínculo com o parceiro (sem SharedPreferences).
class _MemoryBindingStore implements PartnerBindingStore {
  PartnerBinding? binding;

  @override
  Future<PartnerBinding?> read() async => binding;

  @override
  Future<void> write(PartnerBinding value) async => binding = value;

  @override
  Future<void> clear() async => binding = null;
}

/// Dados locais do parceiro sem Hive.
class _FakePartnerLocalData implements PartnerLocalData {
  @override
  Future<void> clear() async {}
}

/// Fake do UserGoogleRepository. Usa `implements` para não instanciar os
/// providers reais (Hive/Firebase).
class _FakeUserGoogleRepository implements UserGoogleRepository {
  _FakeUserGoogleRepository(
    this.log, {
    this.storedUser,
    this.getUserError,
    this.deleteError,
  });

  final List<String> log;
  final UserGoogleModel? storedUser;
  final Object? getUserError;
  final Object? deleteError;
  int deleteCalls = 0;

  @override
  Future<UserGoogleModel?> getUserGoogleModel() async {
    final failure = getUserError;
    if (failure != null) throw failure;
    return storedUser;
  }

  @override
  Future<String> deleteUserGoogleModel() async {
    deleteCalls++;
    log.add(_kLogDeleteUser);
    final failure = deleteError;
    if (failure != null) throw failure;
    return 'ok';
  }

  @override
  Future<UserGoogleModel> createUserDoc(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) => throw UnimplementedError('createUserDoc não é usado no logout');

  @override
  Future<String> saveUserGoogleModel(UserGoogleModel user) =>
      throw UnimplementedError('saveUserGoogleModel não é usado no logout');

  @override
  Future<String> clearAllUserGoogle() =>
      throw UnimplementedError('clearAllUserGoogle não é usado no logout');

  @override
  Future<bool> hasUserGoogle() =>
      throw UnimplementedError('hasUserGoogle não é usado no logout');

  @override
  Future<GdiGroupsGoogle> getGdiGroupsGoogle(String token, String email) =>
      throw UnimplementedError('getGdiGroupsGoogle não é usado no logout');
}

/// Registra no log compartilhado as rotas empilhadas pelo Navigator.
class _LoggingNavigatorObserver extends NavigatorObserver {
  _LoggingNavigatorObserver(this.log);

  final List<String> log;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.add('push:${route.settings.name}');
  }
}

/// Conjunto de dependências falsas de um cenário de logout.
class _Harness {
  _Harness({
    UserGoogleModel? storedUser,
    Object? getUserError,
    Object? deleteError,
    bool stopResult = true,
    Completer<bool>? pendingStop,
    Object? logoutError,
  }) {
    stopper = _FakeTrackingStopper(
      log,
      result: stopResult,
      pending: pendingStop,
    );
    authService = _FakeAuthGoogleService(log, logoutError: logoutError);
    userRepository = _FakeUserGoogleRepository(
      log,
      storedUser: storedUser,
      getUserError: getUserError,
      deleteError: deleteError,
    );
    // O controller é construído sem `Get.put`, de modo que o `onInit` real
    // (que acessa o Google Sign-In) nunca é executado.
    controller = AuthGoogleController(
      partnerSession: PartnerSession(store: _MemoryBindingStore()),
      partnerLocalData: _FakePartnerLocalData(),
      refreshTheme: () {},
      authGoogleService: authService,
      userRepository: userRepository,
      trackingStopper: stopper,
    );
  }

  final List<String> log = <String>[];
  late final _FakeTrackingStopper stopper;
  late final _FakeAuthGoogleService authService;
  late final _FakeUserGoogleRepository userRepository;
  late final AuthGoogleController controller;
}

/// Resultado observável de uma execução completa de `logout()`.
class _LogoutRun {
  _LogoutRun({required this.error, required this.snackbarTitles});

  /// Exceção que escapou de `logout()`, se houver.
  final Object? error;

  /// Títulos dos snackbars exibidos durante o logout.
  final List<String> snackbarTitles;
}

UserGoogleModel _storedUser() =>
    UserGoogleModel(id: 'uid-123', name: 'Ana Souza', email: _kStoredEmail);

/// Monta o app com a rota inicial fictícia e um stub de `Routes.LOGIN`, e
/// limpa do log os pushes feitos durante a montagem.
Future<void> _pumpApp(WidgetTester tester, _Harness harness) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: _kHomeRoute,
      navigatorObservers: [_LoggingNavigatorObserver(harness.log)],
      getPages: [
        GetPage(
          name: _kHomeRoute,
          page: () => const Scaffold(body: Text(_kHomePlaceholder)),
        ),
        GetPage(
          name: Routes.LOGIN,
          page: () => const Scaffold(body: Text(_kLoginPlaceholder)),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  harness.log.clear();
}

String _snackbarTitle(GetSnackBar snackBar) {
  final titleWidget = snackBar.titleText;
  if (titleWidget is Text) return titleWidget.data ?? '';
  return snackBar.title ?? '';
}

/// Executa `logout()` até o fim: captura uma eventual exceção, registra os
/// snackbars exibidos e deixa todos eles fecharem (os timers de 5 s do
/// GetX não podem ficar pendentes ao final do teste).
Future<_LogoutRun> _runLogout(
  WidgetTester tester,
  AuthGoogleController controller,
) async {
  Object? error;
  try {
    await controller.logout();
  } catch (e) {
    error = e;
  }

  // Exibe o snackbar (se houver) e conclui a animação de entrada.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  final titles = tester
      .widgetList<GetSnackBar>(find.byType(GetSnackBar))
      .map(_snackbarTitle)
      .toList();

  // Aguarda o fechamento de todos os snackbars enfileirados.
  for (var i = 0; i < 30 && Get.isSnackbarOpen; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();

  return _LogoutRun(error: error, snackbarTitles: titles);
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('AuthGoogleController.logout - Suíte de Testes Unitários', () {
    // ---------------------------------------------------------------------
    // Happy Path
    // ---------------------------------------------------------------------
    testWidgets(
      'Happy Path: Deve parar o rastreamento informando o e-mail do usuário salvo',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: _storedUser());
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.stopper.emails, [_kStoredEmail]);
      },
    );

    testWidgets(
      'Happy Path: Deve parar o rastreamento antes do signOut, depois limpar o usuário salvo e então navegar para o login',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: _storedUser());
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.log, [
          _kLogStop,
          _kLogSignOut,
          _kLogDeleteUser,
          _kLogNavigateLogin,
        ]);
      },
    );

    testWidgets(
      'Happy Path: Deve navegar para Routes.LOGIN ao concluir o logout',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: _storedUser());
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(Get.currentRoute, Routes.LOGIN);
        expect(find.text(_kLoginPlaceholder), findsOneWidget);
        expect(find.text(_kHomePlaceholder), findsNothing);
      },
    );

    testWidgets(
      'Happy Path: Deve concluir sem exceção e sem snackbar quando o rastreamento parar normalmente',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: _storedUser());
        await _pumpApp(tester, harness);

        // 2. Act
        final run = await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(run.error, isNull);
        expect(run.snackbarTitles, isEmpty);
      },
    );

    testWidgets(
      'Happy Path: Deve finalizar isLoggingOut como false após o logout',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: _storedUser());
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.controller.isLoggingOut.value, isFalse);
      },
    );

    // ---------------------------------------------------------------------
    // Edge Case
    // ---------------------------------------------------------------------
    test('Edge Case: Deve iniciar com isLoggingOut false', () {
      // 1. Arrange
      final log = <String>[];

      // 2. Act
      final controller = AuthGoogleController(
        partnerSession: PartnerSession(store: _MemoryBindingStore()),
        partnerLocalData: _FakePartnerLocalData(),
        refreshTheme: () {},
        authGoogleService: _FakeAuthGoogleService(log),
        userRepository: _FakeUserGoogleRepository(log),
        trackingStopper: _FakeTrackingStopper(log),
      );

      // 3. Assert
      expect(controller.isLoggingOut.value, isFalse);
    });

    testWidgets(
      'Edge Case: Deve chamar stop com e-mail nulo quando não houver usuário salvo',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: null);
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.stopper.emails, [null]);
      },
    );

    testWidgets(
      'Edge Case: Deve prosseguir com signOut, limpeza e navegação quando não houver usuário salvo',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: null);
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.log, [
          _kLogStop,
          _kLogSignOut,
          _kLogDeleteUser,
          _kLogNavigateLogin,
        ]);
      },
    );

    testWidgets(
      'Edge Case: Deve manter isLoggingOut true enquanto a parada do rastreamento estiver em andamento',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          pendingStop: Completer<bool>(),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        unawaited(harness.controller.logout());
        await tester.pump();

        // 3. Assert
        expect(harness.controller.isLoggingOut.value, isTrue);
      },
    );

    testWidgets(
      'Edge Case: Não deve fazer signOut nem limpar o usuário enquanto a parada do rastreamento não concluir',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          pendingStop: Completer<bool>(),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        unawaited(harness.controller.logout());
        await tester.pump();

        // 3. Assert
        expect(harness.authService.logoutCalls, 0);
        expect(harness.userRepository.deleteCalls, 0);
      },
    );

    testWidgets(
      'Edge Case: Deve ignorar um segundo logout enquanto o primeiro estiver em andamento',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          pendingStop: Completer<bool>(),
        );
        await _pumpApp(tester, harness);
        unawaited(harness.controller.logout());
        await tester.pump();

        // 2. Act
        await harness.controller.logout();

        // 3. Assert
        expect(harness.stopper.calls, 1);
      },
    );

    testWidgets(
      'Edge Case: Deve executar stop e logoutGoogle uma única vez quando logout for chamado duas vezes em sequência',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: _storedUser());
        await _pumpApp(tester, harness);

        // 2. Act
        await Future.wait([
          harness.controller.logout(),
          harness.controller.logout(),
        ]);
        await tester.pumpAndSettle();

        // 3. Assert
        expect(harness.stopper.calls, 1);
        expect(harness.authService.logoutCalls, 1);
      },
    );

    // ---------------------------------------------------------------------
    // Sad Path
    // ---------------------------------------------------------------------
    testWidgets(
      'Sad Path: Deve chamar stop com e-mail nulo quando a leitura do usuário salvo lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          getUserError: StateError('box do Hive indisponível'),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.stopper.emails, [null]);
      },
    );

    testWidgets(
      'Sad Path: Deve prosseguir com signOut, limpeza e navegação quando a leitura do usuário salvo lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          getUserError: StateError('box do Hive indisponível'),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.log, [
          _kLogStop,
          _kLogSignOut,
          _kLogDeleteUser,
          _kLogNavigateLogin,
        ]);
      },
    );

    testWidgets(
      'Sad Path: Deve fazer signOut, limpar o usuário e navegar mesmo quando stop não confirmar a parada',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: _storedUser(), stopResult: false);
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.log, [
          _kLogStop,
          _kLogSignOut,
          _kLogDeleteUser,
          _kLogNavigateLogin,
        ]);
        expect(Get.currentRoute, Routes.LOGIN);
      },
    );

    testWidgets(
      'Sad Path: Deve exibir um snackbar de aviso quando stop não confirmar a parada',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(storedUser: _storedUser(), stopResult: false);
        await _pumpApp(tester, harness);

        // 2. Act
        final run = await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(run.snackbarTitles, ['Rastreamento']);
      },
    );

    testWidgets(
      'Sad Path: Não deve apagar o usuário salvo quando logoutGoogle lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          logoutError: Exception('falha de rede no signOut'),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.userRepository.deleteCalls, 0);
      },
    );

    testWidgets(
      'Sad Path: Não deve propagar exceção para fora de logout quando logoutGoogle lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          logoutError: Exception('falha de rede no signOut'),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        final run = await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(run.error, isNull);
      },
    );

    testWidgets(
      'Sad Path: Deve finalizar isLoggingOut como false quando logoutGoogle lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          logoutError: Exception('falha de rede no signOut'),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(harness.controller.isLoggingOut.value, isFalse);
      },
    );

    testWidgets(
      'Sad Path: Deve exibir um snackbar de erro quando logoutGoogle lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          logoutError: Exception('falha de rede no signOut'),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        final run = await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(run.snackbarTitles, ['Erro ao sair']);
      },
    );

    testWidgets(
      'Sad Path: Deve permanecer na tela atual (sem navegar para o login) quando logoutGoogle lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          logoutError: Exception('falha de rede no signOut'),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(Get.currentRoute, _kHomeRoute);
        expect(find.text(_kHomePlaceholder), findsOneWidget);
      },
    );

    testWidgets(
      'Sad Path: Deve finalizar isLoggingOut como false e não propagar exceção quando a limpeza do usuário salvo lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          storedUser: _storedUser(),
          deleteError: StateError('falha ao apagar o box do Hive'),
        );
        await _pumpApp(tester, harness);

        // 2. Act
        final run = await _runLogout(tester, harness.controller);

        // 3. Assert
        expect(run.error, isNull);
        expect(harness.controller.isLoggingOut.value, isFalse);
      },
    );
  });
}
