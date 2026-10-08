import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/connections/groups_api_exception.dart';

void main() {
  group('GroupsApiException - Suíte de Testes Unitários', () {
    test('Happy Path: toString deve incluir status e email', () {
      // 1. Arrange
      final exception = GroupsApiException('a@b.com', 403, 'forbidden');

      // 2. Act
      final text = exception.toString();

      // 3. Assert
      expect(text, contains('403'));
      expect(text, contains('a@b.com'));
      expect(text, contains('forbidden'));
    });

    test('Edge Case: corpo com exatamente 200 caracteres não deve ser truncado', () {
      // 1. Arrange
      final body = 'x' * 200;

      // 2. Act
      final exception = GroupsApiException('a@b.com', 500, body);

      // 3. Assert
      expect(exception.body, body);
    });

    test('Sad Path: corpo maior que 200 caracteres deve ser truncado com reticências', () {
      // 1. Arrange
      final body = 'y' * 500;

      // 2. Act
      final exception = GroupsApiException('a@b.com', 500, body);

      // 3. Assert
      expect(exception.body, '${'y' * 200}…');
      expect(exception.body.length, 201);
    });
  });
}

