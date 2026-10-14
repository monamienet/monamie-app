import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';

/// Implementação falsa do contrato, com resposta determinística e contagem
/// das consultas recebidas.
class FakeBackgroundRestrictionChecker implements BackgroundRestrictionChecker {
  FakeBackgroundRestrictionChecker({this.result = false, this.error});

  final bool result;
  final Object? error;
  int calls = 0;

  @override
  Future<bool> isRestricted() async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

/// Implementação falsa do launcher: não acessa nenhum canal nativo e
/// contabiliza quantas vezes a tela de configurações foi solicitada.
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

/// Canal de métodos usado pelo permission_handler (`openAppSettings`). O
/// controller não deve acioná-lo diretamente: abrir as configurações é
/// responsabilidade do launcher injetado.
const MethodChannel _permissionChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');

const String _dialogMessageSnippet =
    'O seu aparelho está restringindo o MonAmie em segundo plano.';

Widget _buildTestApp() {
  return const GetMaterialApp(home: Scaffold(body: SizedBox.shrink()));
}

void main() {
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
      final checker = FakeBackgroundRestrictionChecker(result: false);
      final launcher = FakeBackgroundUsageSettingsLauncher();
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
      expect(checker.calls, 1);
      expect(launcher.calls, 0);
      expect(permissionCalls, isEmpty);
    });

    testWidgets(
        'Edge Case: Deve limpar a restrição registrada e não exibir diálogo quando o usuário já a removeu',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: false);
      final launcher = FakeBackgroundUsageSettingsLauncher();
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
      expect(checker.calls, 1);
      expect(launcher.calls, 0);
      expect(permissionCalls, isEmpty);
    });

    testWidgets(
        'Sad Path: Deve exibir o diálogo explicativo com "AGORA NÃO" e "PROSSEGUIR" quando o app está restrito',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker = FakeBackgroundRestrictionChecker(result: true);
      final launcher = FakeBackgroundUsageSettingsLauncher();
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
      expect(checker.calls, 1);
      expect(launcher.calls, 0);
      expect(permissionCalls, isEmpty);
    });

    testWidgets(
        'Sad Path: Deve fechar o diálogo sem abrir as configurações quando o usuário toca em "AGORA NÃO"',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final launcher = FakeBackgroundUsageSettingsLauncher();
      final controller = PermissionsController(
        backgroundRestrictionChecker:
            FakeBackgroundRestrictionChecker(result: true),
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
      expect(launcher.calls, 0);
      expect(permissionCalls, isEmpty);
      expect(controller.isBackgroundRestricted.value, isTrue);
    });

    testWidgets(
        'Happy Path: Deve fechar o diálogo e acionar o launcher injetado uma única vez, sem chamar openAppSettings diretamente, quando o usuário toca em "PROSSEGUIR"',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final launcher = FakeBackgroundUsageSettingsLauncher(result: true);
      final controller = PermissionsController(
        backgroundRestrictionChecker:
            FakeBackgroundRestrictionChecker(result: true),
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
      expect(launcher.calls, 1);
      expect(permissionCalls, isEmpty);
    });

    testWidgets(
        'Sad Path: Deve concluir sem erro e sem recorrer ao openAppSettings quando o launcher não consegue abrir nenhuma tela',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final launcher = FakeBackgroundUsageSettingsLauncher(result: false);
      final controller = PermissionsController(
        backgroundRestrictionChecker:
            FakeBackgroundRestrictionChecker(result: true),
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
      expect(launcher.calls, 1);
      expect(permissionCalls, isEmpty);
    });

    testWidgets(
        'Edge Case: Deve manter o diálogo aberto quando o usuário toca fora dele (barreira não dispensável)',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final launcher = FakeBackgroundUsageSettingsLauncher();
      final controller = PermissionsController(
        backgroundRestrictionChecker:
            FakeBackgroundRestrictionChecker(result: true),
        backgroundUsageSettingsLauncher: launcher,
      );
      controller.openBackgroundUsageSettings();
      await tester.pumpAndSettle();

      // 2. Act
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(launcher.calls, 0);
      expect(permissionCalls, isEmpty);
    });

    testWidgets(
        'Edge Case: Deve exibir um único diálogo e acionar o launcher uma única vez quando a ação é disparada duas vezes seguidas',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final launcher = FakeBackgroundUsageSettingsLauncher();
      final controller = PermissionsController(
        backgroundRestrictionChecker:
            FakeBackgroundRestrictionChecker(result: true),
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
      expect(launcher.calls, 1);
    });

    testWidgets(
        'Sad Path: Deve propagar a exceção do checker sem exibir diálogo nem abrir configurações',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final checker =
          FakeBackgroundRestrictionChecker(error: StateError('falha nativa'));
      final launcher = FakeBackgroundUsageSettingsLauncher();
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
      expect(launcher.calls, 0);
      expect(permissionCalls, isEmpty);
    });
  });
}
