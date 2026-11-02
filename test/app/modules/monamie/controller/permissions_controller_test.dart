import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';

@GenerateNiceMocks([
  MockSpec<BackgroundRestrictionChecker>(),
  MockSpec<BackgroundUsageSettingsLauncher>(),
])
import 'permissions_controller_test.mocks.dart';

/// Um [MockBackgroundRestrictionChecker] que responde [result] (ou lança
/// [error]) a cada consulta.
MockBackgroundRestrictionChecker mockChecker({
  bool result = false,
  Object? error,
}) {
  final checker = MockBackgroundRestrictionChecker();
  if (error != null) {
    when(checker.isRestricted()).thenAnswer((_) async => throw error);
  } else {
    setRestricted(checker, result);
  }
  return checker;
}

/// Passa a responder [restricted] às consultas de [checker], como depois de
/// o usuário mudar a restrição nas configurações.
void setRestricted(MockBackgroundRestrictionChecker checker, bool restricted) {
  when(checker.isRestricted()).thenAnswer((_) async => restricted);
}

/// Um [MockBackgroundUsageSettingsLauncher] que não acessa nenhum canal
/// nativo e responde [result] ao abrir as configurações.
MockBackgroundUsageSettingsLauncher mockLauncher({bool result = true}) {
  final launcher = MockBackgroundUsageSettingsLauncher();
  when(launcher.open()).thenAnswer((_) async => result);
  return launcher;
}

/// Canal de métodos usado pelo permission_handler (`openAppSettings`). O
/// controller não deve acioná-lo diretamente: abrir as configurações é
/// responsabilidade do launcher injetado.
const MethodChannel _permissionChannel = MethodChannel(
  'flutter.baseflow.com/permissions/methods',
);

const String _dialogMessageSnippet =
    'O seu aparelho está restringindo o aplicativo em segundo plano.';

Widget _buildTestApp() {
  return const GetMaterialApp(home: Scaffold(body: SizedBox.shrink()));
}

/// Valor de `PermissionStatus.granted` no protocolo do permission_handler.
const int _permissionGranted = 1;

const String _snackbarTitle = 'Uso em segundo plano ainda restrito';

/// Leva o usuário às configurações pelo fluxo do controller: o diálogo
/// explicativo aparece (o checker precisa indicar restrição) e o usuário toca
/// em "PROSSEGUIR".
Future<void> _goToSettingsThroughDialog(
  WidgetTester tester,
  PermissionsController controller,
) async {
  final future = controller.openBackgroundUsageSettings();
  await tester.pumpAndSettle();
  await tester.tap(find.text('PROSSEGUIR'));
  await tester.pumpAndSettle();
  await future;
}

/// Conclui o trabalho assíncrono disparado pelo retorno ao app (reconsulta das
/// permissões e da restrição) e renderiza a entrada do snackbar, se houver,
/// sem alcançar os 8 s após os quais ele se fecha sozinho. `pumpAndSettle`
/// não serve aqui: o ícone pulsante mantém frames agendados até o snackbar
/// sumir, e um aviso indevido passaria despercebido.
Future<void> _settleReturnToApp(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// `testWidgets` que, ao final (mesmo quando o teste falha), deixa os
/// snackbars do GetX concluírem o ciclo de vida (8 s na tela + 1 s de saída).
///
/// O flutter_test verifica timers pendentes antes de executar os `tearDown`,
/// e a fila de snackbars do GetX é estática: sem esta limpeza, o timer do
/// snackbar quebraria o teste e a fila ficaria travada para os seguintes.
void _testWidgetsWithSnackbarCleanup(
  String description,
  WidgetTesterCallback body,
) {
  testWidgets(description, (WidgetTester tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpAndSettle();
    }
  });
}

void main() {
  group('background restriction', () {
    group('PermissionsController - Restrição de Segundo Plano', () {
      test('Happy Path: Deve iniciar isBackgroundRestricted como false', () {
        // 1. Arrange
        final checker = mockChecker(result: true);

        // 2. Act
        final controller = PermissionsController(
          backgroundRestrictionChecker: checker,
        );

        // 3. Assert
        expect(controller.isBackgroundRestricted.value, isFalse);
      });

      test(
        'Happy Path: Deve retornar true e atualizar o estado quando o checker confirma a restrição',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
          );

          // 2. Act
          final resultado = await controller.refreshBackgroundRestriction();

          // 3. Assert
          expect(resultado, isTrue);
          expect(controller.isBackgroundRestricted.value, isTrue);
          verify(checker.isRestricted()).called(1);
        },
      );

      test(
        'Happy Path: Deve retornar false e manter o estado quando o checker não detecta restrição',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: false);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
          );

          // 2. Act
          final resultado = await controller.refreshBackgroundRestriction();

          // 3. Assert
          expect(resultado, isFalse);
          expect(controller.isBackgroundRestricted.value, isFalse);
        },
      );

      test(
        'Edge Case: Deve limpar a restrição previamente registrada quando o usuário a remove nas configurações',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: false);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
          );
          controller.isBackgroundRestricted.value = true;

          // 2. Act
          final resultado = await controller.refreshBackgroundRestriction();

          // 3. Assert
          expect(resultado, isFalse);
          expect(controller.isBackgroundRestricted.value, isFalse);
        },
      );

      test(
        'Sad Path: Deve propagar a exceção do checker e preservar o estado anterior',
        () async {
          // 1. Arrange
          final checker = mockChecker(error: StateError('falha nativa'));
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
          );
          controller.isBackgroundRestricted.value = true;

          // 2. Act
          final future = controller.refreshBackgroundRestriction();

          // 3. Assert
          await expectLater(future, throwsA(isA<StateError>()));
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );
    });

    group('PermissionsController - arePermissionsGranted', () {
      PermissionsController buildController({
        required bool always,
        required bool notification,
        required bool restricted,
      }) {
        final controller = PermissionsController(
          backgroundRestrictionChecker: mockChecker(),
        );
        controller.hasAlwaysLocationPermission.value = always;
        controller.hasNotificationPermission.value = notification;
        controller.isBackgroundRestricted.value = restricted;
        return controller;
      }

      test(
        'Happy Path: Deve retornar true com localização sempre, notificação concedida e sem restrição',
        () {
          // 1. Arrange
          final controller = buildController(
            always: true,
            notification: true,
            restricted: false,
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isTrue);
        },
      );

      test(
        'Edge Case: Deve retornar false no estado inicial do controller (nada concedido)',
        () {
          // 1. Arrange
          final controller = PermissionsController(
            backgroundRestrictionChecker: mockChecker(),
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );

      test(
        'Edge Case: Deve ignorar a permissão "durante o uso" quando todas as obrigatórias estão concedidas',
        () {
          // 1. Arrange
          final controller = buildController(
            always: true,
            notification: true,
            restricted: false,
          );
          controller.hasWhenInUseLocationPermission.value = false;

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isTrue);
        },
      );

      test(
        'Sad Path: Deve retornar false quando o app está restrito em segundo plano mesmo com permissões concedidas',
        () {
          // 1. Arrange
          final controller = buildController(
            always: true,
            notification: true,
            restricted: true,
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );

      test(
        'Sad Path: Deve retornar false quando falta a permissão de localização "sempre"',
        () {
          // 1. Arrange
          final controller = buildController(
            always: false,
            notification: true,
            restricted: false,
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );

      test(
        'Sad Path: Deve retornar false quando falta a permissão de notificação',
        () {
          // 1. Arrange
          final controller = buildController(
            always: true,
            notification: false,
            restricted: false,
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );

      test(
        'Sad Path: Deve retornar false quando o refresh detecta restrição após permissões concedidas',
        () async {
          // 1. Arrange
          final controller = PermissionsController(
            backgroundRestrictionChecker: mockChecker(result: true),
          );
          controller.hasAlwaysLocationPermission.value = true;
          controller.hasNotificationPermission.value = true;
          await controller.refreshBackgroundRestriction();

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );
    });
  });

  group('open background usage settings', () {
    group('PermissionsController - openBackgroundUsageSettings', () {
      late List<MethodCall> permissionCalls;

      setUp(() {
        permissionCalls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_permissionChannel, (call) async {
              permissionCalls.add(call);
              if (call.method == 'openAppSettings') return true;
              return null;
            });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_permissionChannel, null);
        Get.reset();
      });

      testWidgets(
        'Happy Path: Deve retornar sem exibir diálogo nem abrir configurações quando o app não está restrito',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: false);
          final launcher = mockLauncher();
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: launcher,
          );

          // 2. Act
          await controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();

          // 3. Assert
          expect(find.byType(AlertDialog), findsNothing);
          expect(Get.isDialogOpen, isFalse);
          expect(controller.isBackgroundRestricted.value, isFalse);
          verify(checker.isRestricted()).called(1);
          verifyNever(launcher.open());
          expect(permissionCalls, isEmpty);
        },
      );

      testWidgets(
        'Edge Case: Deve limpar a restrição registrada e não exibir diálogo quando o usuário já a removeu',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: false);
          final launcher = mockLauncher();
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: launcher,
          );
          controller.isBackgroundRestricted.value = true;

          // 2. Act
          await controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();

          // 3. Assert
          expect(find.byType(AlertDialog), findsNothing);
          expect(controller.isBackgroundRestricted.value, isFalse);
          verify(checker.isRestricted()).called(1);
          verifyNever(launcher.open());
          expect(permissionCalls, isEmpty);
        },
      );

      testWidgets(
        'Sad Path: Deve exibir o diálogo explicativo com "AGORA NÃO" e "PROSSEGUIR" quando o app está restrito',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final launcher = mockLauncher();
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: launcher,
          );

          // 2. Act
          controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();

          // 3. Assert
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(find.textContaining(_dialogMessageSnippet), findsOneWidget);
          expect(find.text('AGORA NÃO'), findsOneWidget);
          expect(find.text('PROSSEGUIR'), findsOneWidget);
          expect(controller.isBackgroundRestricted.value, isTrue);
          verify(checker.isRestricted()).called(1);
          verifyNever(launcher.open());
          expect(permissionCalls, isEmpty);
        },
      );

      testWidgets(
        'Sad Path: Deve fechar o diálogo sem abrir as configurações quando o usuário toca em "AGORA NÃO"',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final launcher = mockLauncher();
          final controller = PermissionsController(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
          );
          final future = controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();

          // 2. Act
          await tester.tap(find.text('AGORA NÃO'));
          await tester.pumpAndSettle();

          // 3. Assert
          await expectLater(future, completes);
          expect(find.byType(AlertDialog), findsNothing);
          verifyNever(launcher.open());
          expect(permissionCalls, isEmpty);
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );

      testWidgets(
        'Happy Path: Deve fechar o diálogo e acionar o launcher injetado uma única vez, sem chamar openAppSettings diretamente, quando o usuário toca em "PROSSEGUIR"',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final launcher = mockLauncher(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
          );
          final future = controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();

          // 2. Act
          await tester.tap(find.text('PROSSEGUIR'));
          await tester.pumpAndSettle();

          // 3. Assert
          await expectLater(future, completes);
          expect(find.byType(AlertDialog), findsNothing);
          verify(launcher.open()).called(1);
          expect(permissionCalls, isEmpty);
        },
      );

      testWidgets(
        'Sad Path: Deve concluir sem erro e sem recorrer ao openAppSettings quando o launcher não consegue abrir nenhuma tela',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final launcher = mockLauncher(result: false);
          final controller = PermissionsController(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
          );
          final future = controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();

          // 2. Act
          await tester.tap(find.text('PROSSEGUIR'));
          await tester.pumpAndSettle();

          // 3. Assert
          await expectLater(future, completes);
          expect(find.byType(AlertDialog), findsNothing);
          verify(launcher.open()).called(1);
          expect(permissionCalls, isEmpty);
        },
      );

      testWidgets(
        'Edge Case: Deve manter o diálogo aberto quando o usuário toca fora dele (barreira não dispensável)',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final launcher = mockLauncher();
          final controller = PermissionsController(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
          );
          controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();

          // 2. Act
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();

          // 3. Assert
          expect(find.byType(AlertDialog), findsOneWidget);
          verifyNever(launcher.open());
          expect(permissionCalls, isEmpty);
        },
      );

      testWidgets(
        'Edge Case: Deve exibir um único diálogo e acionar o launcher uma única vez quando a ação é disparada duas vezes seguidas',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final launcher = mockLauncher();
          final controller = PermissionsController(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
          );
          // Toques rápidos repetidos no botão antes de o diálogo aparecer.
          controller.openBackgroundUsageSettings();
          controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();

          // 2. Act
          await tester.tap(find.text('PROSSEGUIR').last);
          await tester.pumpAndSettle();

          // 3. Assert
          expect(find.byType(AlertDialog), findsNothing);
          verify(launcher.open()).called(1);
        },
      );

      testWidgets(
        'Sad Path: Deve propagar a exceção do checker sem exibir diálogo nem abrir configurações',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(error: StateError('falha nativa'));
          final launcher = mockLauncher();
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: launcher,
          );

          // 2. Act
          final future = controller.openBackgroundUsageSettings();

          // 3. Assert
          await expectLater(future, throwsA(isA<StateError>()));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          verifyNever(launcher.open());
          expect(permissionCalls, isEmpty);
        },
      );
    });
  });

  group('return from settings', () {
    group('PermissionsController - Aviso ao retornar das configurações de bateria', () {
      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_permissionChannel, (call) async {
              if (call.method == 'checkPermissionStatus') {
                return _permissionGranted;
              }
              if (call.method == 'openAppSettings') return true;
              return null;
            });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_permissionChannel, null);
        Get.reset();
      });

      _testWidgetsWithSnackbarCleanup(
        'Happy Path: Deve exibir o snackbar "Uso em segundo plano ainda restrito" quando o usuário volta das configurações e a restrição continua',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
          );
          await _goToSettingsThroughDialog(tester, controller);

          // 2. Act
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _settleReturnToApp(tester);

          // 3. Assert
          expect(find.text(_snackbarTitle), findsOneWidget);
          expect(Get.isSnackbarOpen, isTrue);
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );

      _testWidgetsWithSnackbarCleanup(
        'Happy Path: Deve limpar a restrição sem exibir aviso quando o usuário a remove nas configurações',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
          );
          await _goToSettingsThroughDialog(tester, controller);
          setRestricted(checker, false); // O usuário removeu a restrição.

          // 2. Act
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _settleReturnToApp(tester);

          // 3. Assert
          expect(find.text(_snackbarTitle), findsNothing);
          expect(Get.isSnackbarOpen, isFalse);
          expect(controller.isBackgroundRestricted.value, isFalse);
        },
      );

      _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve exibir o aviso apenas uma vez por ida às configurações, ignorando um segundo retorno ao app',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
          );
          await _goToSettingsThroughDialog(tester, controller);
          // Primeiro retorno: o aviso é exibido e some sozinho após 8 s.
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await tester.pumpAndSettle();

          // 2. Act
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _settleReturnToApp(tester);

          // 3. Assert
          expect(find.text(_snackbarTitle), findsNothing);
          expect(Get.isSnackbarOpen, isFalse);
        },
      );

      _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve exibir o aviso novamente quando o usuário volta às configurações por um novo "PROSSEGUIR"',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
          );
          await _goToSettingsThroughDialog(tester, controller);
          // Primeira ida: o aviso é exibido e some sozinho após 8 s.
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await tester.pumpAndSettle();
          await _goToSettingsThroughDialog(tester, controller);

          // 2. Act
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _settleReturnToApp(tester);

          // 3. Assert
          expect(find.text(_snackbarTitle), findsOneWidget);
          expect(Get.isSnackbarOpen, isTrue);
        },
      );

      _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve ignorar um retorno posterior em que a restrição reaparece depois de um retorno já sem restrição',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
          );
          await _goToSettingsThroughDialog(tester, controller);
          setRestricted(
            checker,
            false,
          ); // Retorno da ida às configurações sem restrição.
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await tester.pumpAndSettle();
          setRestricted(
            checker,
            true,
          ); // A restrição reaparece depois, fora da ida.

          // 2. Act
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _settleReturnToApp(tester);

          // 3. Assert
          expect(find.text(_snackbarTitle), findsNothing);
          expect(Get.isSnackbarOpen, isFalse);
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );

      _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve ignorar o retorno ao app sem ida às configurações pelo controller, mesmo com a restrição ativa',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final launcher = mockLauncher(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: launcher,
          );

          // 2. Act
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _settleReturnToApp(tester);

          // 3. Assert
          expect(find.text(_snackbarTitle), findsNothing);
          expect(Get.isSnackbarOpen, isFalse);
          expect(controller.isBackgroundRestricted.value, isTrue);
          verifyNever(launcher.open());
        },
      );

      _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve ignorar o retorno ao app quando o usuário escolheu "AGORA NÃO" no diálogo',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
          );
          final future = controller.openBackgroundUsageSettings();
          await tester.pumpAndSettle();
          await tester.tap(find.text('AGORA NÃO'));
          await tester.pumpAndSettle();
          await future;

          // 2. Act
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _settleReturnToApp(tester);

          // 3. Assert
          expect(find.text(_snackbarTitle), findsNothing);
          expect(Get.isSnackbarOpen, isFalse);
        },
      );

      _testWidgetsWithSnackbarCleanup(
        'Sad Path: Deve ignorar o retorno ao app quando o launcher não conseguiu abrir nenhuma tela de configurações',
        (WidgetTester tester) async {
          // 1. Arrange
          await tester.pumpWidget(_buildTestApp());
          final checker = mockChecker(result: true);
          final controller = PermissionsController(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: false),
          );
          await _goToSettingsThroughDialog(tester, controller);

          // 2. Act
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _settleReturnToApp(tester);

          // 3. Assert
          expect(find.text(_snackbarTitle), findsNothing);
          expect(Get.isSnackbarOpen, isFalse);
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );
    });
  });
}
