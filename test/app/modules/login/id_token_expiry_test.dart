import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/login/id_token_expiry.dart';

String _b64(String text) =>
    base64Url.encode(utf8.encode(text)).replaceAll('=', '');

/// Builds a token whose payload is the given JSON text.
String _tokenWithPayload(String payloadJson) =>
    '${_b64('{"alg":"none"}')}.${_b64(payloadJson)}.sig';

String _tokenExpiringAt(int expSeconds) =>
    _tokenWithPayload('{"exp":$expSeconds}');

void main() {
  final now = DateTime.utc(2026, 10, 27, 12);
  final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;

  group('idTokenIsFresh - Suíte de Testes Unitários', () {
    test('Happy Path: Deve ser fresco quando o exp está bem no futuro', () {
      // 1. Arrange
      final token = _tokenExpiringAt(nowSeconds + 3600);

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isTrue);
    });

    test('Happy Path: Deve aceitar um horário local no lugar de UTC', () {
      // 1. Arrange
      final token = _tokenExpiringAt(nowSeconds + 3600);

      // 2. Act
      final fresh = idTokenIsFresh(token, now.toLocal());

      // 3. Assert
      expect(fresh, isTrue);
    });

    test(
      'Edge Case: Não deve ser fresco quando o exp é exatamente agora + margem',
      () {
        // 1. Arrange
        final token = _tokenExpiringAt(nowSeconds + 300);

        // 2. Act
        final fresh = idTokenIsFresh(token, now);

        // 3. Assert
        expect(fresh, isFalse);
      },
    );

    test(
      'Edge Case: Deve ser fresco quando o exp passa um segundo de agora + margem',
      () {
        // 1. Arrange
        final token = _tokenExpiringAt(nowSeconds + 301);

        // 2. Act
        final fresh = idTokenIsFresh(token, now);

        // 3. Assert
        expect(fresh, isTrue);
      },
    );

    test('Edge Case: Deve respeitar uma margem personalizada', () {
      // 1. Arrange
      final token = _tokenExpiringAt(nowSeconds + 600);

      // 2. Act
      final fresh = idTokenIsFresh(
        token,
        now,
        margin: const Duration(minutes: 20),
      );

      // 3. Assert
      expect(fresh, isFalse);
    });

    test(
      'Edge Case: Deve ser fresco com margem zero quando o exp é um segundo à frente',
      () {
        // 1. Arrange
        final token = _tokenExpiringAt(nowSeconds + 1);

        // 2. Act
        final fresh = idTokenIsFresh(token, now, margin: Duration.zero);

        // 3. Assert
        expect(fresh, isTrue);
      },
    );

    test('Edge Case: Deve aceitar exp decimal', () {
      // 1. Arrange
      final token = _tokenWithPayload('{"exp":${nowSeconds + 3600}.5}');

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isTrue);
    });

    test(
      'Edge Case: Deve aceitar payload com preenchimento base64 explícito',
      () {
        // 1. Arrange
        final payload = base64Url.encode(
          utf8.encode('{"exp":${nowSeconds + 3600},"sub":"a"}'),
        );
        final token = '${_b64('{}')}.$payload.sig';

        // 2. Act
        final fresh = idTokenIsFresh(token, now);

        // 3. Assert
        expect(fresh, isTrue);
      },
    );

    test('Sad Path: Não deve ser fresco quando o exp já passou', () {
      // 1. Arrange
      final token = _tokenExpiringAt(nowSeconds - 10);

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isFalse);
    });

    test('Sad Path: Não deve ser fresco quando o token é null', () {
      // 1. Arrange
      const String? token = null;

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isFalse);
    });

    test('Sad Path: Não deve ser fresco quando o token tem duas partes', () {
      // 1. Arrange
      final token = '${_b64('{}')}.${_b64('{"exp":${nowSeconds + 3600}}')}';

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isFalse);
    });

    test('Sad Path: Não deve ser fresco quando o token tem quatro partes', () {
      // 1. Arrange
      final token = '${_tokenExpiringAt(nowSeconds + 3600)}.extra';

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isFalse);
    });

    test(
      'Sad Path: Não deve ser fresco quando o payload não é base64 válido',
      () {
        // 1. Arrange
        const token = 'a.@@@@.c';

        // 2. Act
        final fresh = idTokenIsFresh(token, now);

        // 3. Assert
        expect(fresh, isFalse);
      },
    );

    test('Sad Path: Não deve ser fresco quando o payload não é JSON', () {
      // 1. Arrange
      final token = '${_b64('{}')}.${_b64('not json')}.sig';

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isFalse);
    });

    test(
      'Sad Path: Não deve ser fresco quando o payload é JSON mas não é um objeto',
      () {
        // 1. Arrange
        final token = _tokenWithPayload('[1,2,3]');

        // 2. Act
        final fresh = idTokenIsFresh(token, now);

        // 3. Assert
        expect(fresh, isFalse);
      },
    );

    test('Sad Path: Não deve ser fresco quando falta o exp', () {
      // 1. Arrange
      final token = _tokenWithPayload('{"sub":"abc"}');

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isFalse);
    });

    test('Sad Path: Não deve ser fresco quando o exp não é numérico', () {
      // 1. Arrange
      final token = _tokenWithPayload('{"exp":"${nowSeconds + 3600}"}');

      // 2. Act
      final fresh = idTokenIsFresh(token, now);

      // 3. Assert
      expect(fresh, isFalse);
    });
  });
}
