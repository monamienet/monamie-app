import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/app/data/services/method_channel_background_usage_settings_launcher.dart';

/// Canal nativo registrado em `MainActivity.kt` (o mesmo do checker de
/// restrição), declarado aqui pelo nome para validar o contrato de forma
/// independente da implementação.
const MethodChannel _nativeChannel = MethodChannel(
  'monamie/background_restriction',
);

/// Canal de métodos do permission_handler, usado pelo `openAppSettings()`.
const MethodChannel _permissionChannel = MethodChannel(
  'flutter.baseflow.com/permissions/methods',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Registra um handler falso para [channel] e acumula as chamadas recebidas.
  List<MethodCall> mockChannel(
    MethodChannel channel,
    Future<Object?> Function(MethodCall) reply,
  ) {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return reply(call);
        });
    return calls;
  }

  /// Simula o `openAppSettings()` do permission_handler devolvendo [opened].
  List<MethodCall> mockOpenAppSettings({required bool opened}) {
    return mockChannel(_permissionChannel, (call) async {
      if (call.method == 'openAppSettings') return opened;
      return null;
    });
  }

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_nativeChannel, null);
    messenger.setMockMethodCallHandler(_permissionChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('MethodChannelBackgroundUsageSettingsLauncher - Suíte de Testes Unitários', () {
    test(
      'Happy Path: Deve implementar o contrato BackgroundUsageSettingsLauncher',
      () {
        // 1. Arrange
        // (sem pré-condições)

        // 2. Act
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 3. Assert
        expect(launcher, isA<BackgroundUsageSettingsLauncher>());
      },
    );

    test(
      'Happy Path: Deve retornar true quando o Android abre a tela de uso da bateria',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        mockChannel(_nativeChannel, (_) async => true);
        // Um fallback indevido seria detectado: ele devolveria false.
        mockOpenAppSettings(opened: false);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isTrue);
      },
    );

    test(
      'Happy Path: Deve invocar uma única vez openBackgroundUsageSettings, sem argumentos, no canal monamie/background_restriction',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final nativeCalls = mockChannel(_nativeChannel, (_) async => true);
        mockOpenAppSettings(opened: true);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        await launcher.open();

        // 3. Assert
        expect(nativeCalls, hasLength(1));
        expect(nativeCalls.single.method, 'openBackgroundUsageSettings');
        expect(nativeCalls.single.arguments, isNull);
      },
    );

    test(
      'Happy Path: Deve dispensar o openAppSettings quando o Android confirma a abertura da tela de uso da bateria',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        mockChannel(_nativeChannel, (_) async => true);
        final permissionCalls = mockOpenAppSettings(opened: true);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        await launcher.open();

        // 3. Assert
        expect(permissionCalls, isEmpty);
      },
    );

    test(
      'Edge Case: Deve recorrer ao openAppSettings e retornar o resultado dele quando a plataforma nativa responde null',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        mockChannel(_nativeChannel, (_) async => null);
        final permissionCalls = mockOpenAppSettings(opened: true);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isTrue);
        expect(permissionCalls.map((call) => call.method), ['openAppSettings']);
      },
    );

    test(
      'Edge Case: Deve ir direto ao openAppSettings, sem consultar o canal nativo, quando a plataforma é iOS',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final nativeCalls = mockChannel(_nativeChannel, (_) async => true);
        final permissionCalls = mockOpenAppSettings(opened: true);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isTrue);
        expect(nativeCalls, isEmpty);
        expect(permissionCalls.map((call) => call.method), ['openAppSettings']);
      },
    );

    test(
      'Edge Case: Deve retornar o resultado negativo do openAppSettings, sem consultar o canal nativo, quando a plataforma é Linux',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final nativeCalls = mockChannel(_nativeChannel, (_) async => true);
        final permissionCalls = mockOpenAppSettings(opened: false);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isFalse);
        expect(nativeCalls, isEmpty);
        expect(permissionCalls.map((call) => call.method), ['openAppSettings']);
      },
    );

    test(
      'Sad Path: Deve recorrer ao openAppSettings e retornar o resultado dele quando o Android informa que não abriu a tela',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        mockChannel(_nativeChannel, (_) async => false);
        final permissionCalls = mockOpenAppSettings(opened: true);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isTrue);
        expect(permissionCalls.map((call) => call.method), ['openAppSettings']);
      },
    );

    test(
      'Sad Path: Deve recorrer ao openAppSettings sem lançar exceção quando a plataforma lança PlatformException',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        mockChannel(
          _nativeChannel,
          (_) async => throw PlatformException(
            code: 'ERROR',
            message: 'Falha ao abrir a tela de uso da bateria',
          ),
        );
        final permissionCalls = mockOpenAppSettings(opened: true);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isTrue);
        expect(permissionCalls.map((call) => call.method), ['openAppSettings']);
      },
    );

    test(
      'Sad Path: Deve recorrer ao openAppSettings sem lançar exceção quando o canal nativo não está registrado (MissingPluginException)',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_nativeChannel, null);
        final permissionCalls = mockOpenAppSettings(opened: true);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isTrue);
        expect(permissionCalls.map((call) => call.method), ['openAppSettings']);
      },
    );

    test(
      'Sad Path: Deve recorrer ao openAppSettings quando o handler nativo não implementa o método (notImplemented)',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        mockChannel(
          _nativeChannel,
          (_) async => throw MissingPluginException(),
        );
        final permissionCalls = mockOpenAppSettings(opened: true);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isTrue);
        expect(permissionCalls.map((call) => call.method), ['openAppSettings']);
      },
    );

    test(
      'Sad Path: Deve retornar false quando nem a tela nativa nem o openAppSettings conseguem ser abertos',
      () async {
        // 1. Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        mockChannel(_nativeChannel, (_) async => false);
        mockOpenAppSettings(opened: false);
        final launcher = MethodChannelBackgroundUsageSettingsLauncher();

        // 2. Act
        final opened = await launcher.open();

        // 3. Assert
        expect(opened, isFalse);
      },
    );
  });
}
