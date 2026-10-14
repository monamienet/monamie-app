import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';

/// Checker falso com resposta mutável: o cenário começa restrito (para o
/// diálogo aparecer) e passa a responder conforme o que o usuário fez nas
/// configurações antes de voltar ao app.
class FakeBackgroundRestrictionChecker implements BackgroundRestrictionChecker {
  FakeBackgroundRestrictionChecker({this.result = false});

  bool result;
  int calls = 0;

  @override
  Future<bool> isRestricted() async {
    calls++;
    return result;
  }
}

/// Launcher falso: não acessa nenhum canal nativo e contabiliza quantas vezes
/// a tela de configurações foi solicitada.
class FakeBackgroundUsageSettingsLauncher
    implements BackgroundUsageSettingsLauncher {
  FakeBackgroundUsageSettingsLauncher({this.result = true});

  final bool result;
  int calls = 0;

  @override
  Future<bool> open() async {
    calls++;
    return result;
  }
}

/// Canal do permission_handler: o retorno ao app reconsulta as permissões
/// por `checkPermissionStatus`, que precisa receber um status inteiro.
const MethodChannel _permissionChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');

/// Valor de `PermissionStatus.granted` no protocolo do permission_handler.
const int _permissionGranted = 1;

const String _snackbarTitle = 'Uso em segundo plano ainda restrito';

Widget _buildTestApp() {
  return const GetMaterialApp(home: Scaffold(body: SizedBox.shrink()));
}

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
  group('PermissionsController - Aviso ao retornar das configurações de bateria',
      () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_permissionChannel, (call) async {
        if (call.method == 'checkPermissionStatus') return _permissionGranted;
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
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final controller = PermissionsController(
        backgroundRestrictionChecker: checker,
        backgroundUsageSettingsLauncher:
            FakeBackgroundUsageSettingsLauncher(result: true),
      );
      await _goToSettingsThroughDialog(tester, controller);

      // 2. Act
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settleReturnToApp(tester);

      // 3. Assert
      expect(find.text(_snackbarTitle), findsOneWidget);
      expect(Get.isSnackbarOpen, isTrue);
      expect(controller.isBackgroundRestricted.value, isTrue);
    });

    _testWidgetsWithSnackbarCleanup(
        'Happy Path: Deve limpar a restrição sem exibir aviso quando o usuário a remove nas configurações',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final controller = PermissionsController(
        backgroundRestrictionChecker: checker,
        backgroundUsageSettingsLauncher:
            FakeBackgroundUsageSettingsLauncher(result: true),
      );
      await _goToSettingsThroughDialog(tester, controller);
      checker.result = false; // O usuário removeu a restrição.

      // 2. Act
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settleReturnToApp(tester);

      // 3. Assert
      expect(find.text(_snackbarTitle), findsNothing);
      expect(Get.isSnackbarOpen, isFalse);
      expect(controller.isBackgroundRestricted.value, isFalse);
    });

    _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve exibir o aviso apenas uma vez por ida às configurações, ignorando um segundo retorno ao app',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final controller = PermissionsController(
        backgroundRestrictionChecker: checker,
        backgroundUsageSettingsLauncher:
            FakeBackgroundUsageSettingsLauncher(result: true),
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
    });

    _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve exibir o aviso novamente quando o usuário volta às configurações por um novo "PROSSEGUIR"',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final controller = PermissionsController(
        backgroundRestrictionChecker: checker,
        backgroundUsageSettingsLauncher:
            FakeBackgroundUsageSettingsLauncher(result: true),
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
    });

    _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve ignorar um retorno posterior em que a restrição reaparece depois de um retorno já sem restrição',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final controller = PermissionsController(
        backgroundRestrictionChecker: checker,
        backgroundUsageSettingsLauncher:
            FakeBackgroundUsageSettingsLauncher(result: true),
      );
      await _goToSettingsThroughDialog(tester, controller);
      checker.result = false; // Retorno da ida às configurações sem restrição.
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      checker.result = true; // A restrição reaparece depois, fora da ida.

      // 2. Act
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settleReturnToApp(tester);

      // 3. Assert
      expect(find.text(_snackbarTitle), findsNothing);
      expect(Get.isSnackbarOpen, isFalse);
      expect(controller.isBackgroundRestricted.value, isTrue);
    });

    _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve ignorar o retorno ao app sem ida às configurações pelo controller, mesmo com a restrição ativa',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final launcher = FakeBackgroundUsageSettingsLauncher(result: true);
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
      expect(launcher.calls, 0);
    });

    _testWidgetsWithSnackbarCleanup(
        'Edge Case: Deve ignorar o retorno ao app quando o usuário escolheu "AGORA NÃO" no diálogo',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final controller = PermissionsController(
        backgroundRestrictionChecker: checker,
        backgroundUsageSettingsLauncher:
            FakeBackgroundUsageSettingsLauncher(result: true),
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
    });

    _testWidgetsWithSnackbarCleanup(
        'Sad Path: Deve ignorar o retorno ao app quando o launcher não conseguiu abrir nenhuma tela de configurações',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final controller = PermissionsController(
        backgroundRestrictionChecker: checker,
        backgroundUsageSettingsLauncher:
            FakeBackgroundUsageSettingsLauncher(result: false),
      );
      await _goToSettingsThroughDialog(tester, controller);

      // 2. Act
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settleReturnToApp(tester);

      // 3. Assert
      expect(find.text(_snackbarTitle), findsNothing);
      expect(Get.isSnackbarOpen, isFalse);
      expect(controller.isBackgroundRestricted.value, isTrue);
    });
  });
}
