import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/method_channel_background_restriction_checker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannelBackgroundRestrictionChecker.channel;

  /// Registra um handler falso para o canal e acumula as chamadas recebidas.
  List<MethodCall> mockChannel(Future<Object?> Function(MethodCall) reply) {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return reply(call);
    });
    return calls;
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('MethodChannelBackgroundRestrictionChecker - Suíte de Testes Unitários',
      () {
    test('Happy Path: Deve implementar o contrato BackgroundRestrictionChecker',
        () {
      // 1. Arrange
      // (sem pré-condições)

      // 2. Act
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 3. Assert
      expect(checker, isA<BackgroundRestrictionChecker>());
    });

    test('Happy Path: Deve expor o canal com o nome monamie/background_restriction',
        () {
      // 1. Arrange
      // (sem pré-condições)

      // 2. Act
      final nomeDoCanal = MethodChannelBackgroundRestrictionChecker.channel.name;

      // 3. Assert
      expect(nomeDoCanal, 'monamie/background_restriction');
    });

    test('Happy Path: Deve retornar true quando o Android confirma a restrição',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockChannel((_) async => true);
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      final restrito = await checker.isRestricted();

      // 3. Assert
      expect(restrito, isTrue);
    });

    test('Happy Path: Deve retornar false quando o Android informa que não há restrição',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockChannel((_) async => false);
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      final restrito = await checker.isRestricted();

      // 3. Assert
      expect(restrito, isFalse);
    });

    test('Happy Path: Deve invocar exatamente uma vez o método isBackgroundRestricted sem argumentos',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final chamadas = mockChannel((_) async => true);
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      await checker.isRestricted();

      // 3. Assert
      expect(chamadas, hasLength(1));
      expect(chamadas.single.method, 'isBackgroundRestricted');
      expect(chamadas.single.arguments, isNull);
    });

    test('Edge Case: Deve retornar false quando a plataforma nativa responde null',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockChannel((_) async => null);
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      final restrito = await checker.isRestricted();

      // 3. Assert
      expect(restrito, isFalse);
    });

    test('Edge Case: Deve retornar false sem consultar o canal quando a plataforma é iOS',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final chamadas = mockChannel((_) async => true);
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      final restrito = await checker.isRestricted();

      // 3. Assert
      expect(restrito, isFalse);
      expect(chamadas, isEmpty);
    });

    test('Edge Case: Deve retornar false sem consultar o canal quando a plataforma é Linux',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final chamadas = mockChannel((_) async => true);
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      final restrito = await checker.isRestricted();

      // 3. Assert
      expect(restrito, isFalse);
      expect(chamadas, isEmpty);
    });

    test('Sad Path: Deve retornar false sem lançar exceção quando a plataforma lança PlatformException',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockChannel(
        (_) async => throw PlatformException(
          code: 'ERROR',
          message: 'Falha ao consultar ActivityManager',
        ),
      );
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      final restrito = await checker.isRestricted();

      // 3. Assert
      expect(restrito, isFalse);
    });

    test('Sad Path: Deve retornar false sem lançar exceção quando o canal nativo não está registrado (MissingPluginException)',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      final restrito = await checker.isRestricted();

      // 3. Assert
      expect(restrito, isFalse);
    });

    test('Sad Path: Deve retornar false quando o handler nativo não implementa o método (notImplemented)',
        () async {
      // 1. Arrange
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockChannel((_) async => throw MissingPluginException());
      final checker = MethodChannelBackgroundRestrictionChecker();

      // 2. Act
      final restrito = await checker.isRestricted();

      // 3. Assert
      expect(restrito, isFalse);
    });
  });
}
