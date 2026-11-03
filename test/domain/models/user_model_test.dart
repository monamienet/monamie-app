import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/user_model.dart';

void main() {
  group('UserModel - Testes Unitários de Inicialização', () {
    // -------------------------------------------------------------
    // CONSTRUTOR PADRÃO
    // -------------------------------------------------------------
    test(
      'Happy Path: Deve inicializar corretamente com todos os campos válidos preenchidos',
      () {
        // 1. Arrange
        final dataHora = DateTime(2026, 9, 16, 20, 30, 0);

        // 2. Act
        final user = UserModel(
          email: 'servidor.ti@monamienet.org',
          name: 'Servidor Teste',
          lat: -22.9041,
          lng: -43.1329,
          capturedAt: dataHora,
          isPublishing: true,
        );

        // 3. Assert
        expect(user.email, 'servidor.ti@monamienet.org');
        expect(user.name, 'Servidor Teste');
        expect(user.lat, -22.9041);
        expect(user.lng, -43.1329);
        expect(user.capturedAt, dataHora);
        expect(user.isPublishing, isTrue);
      },
    );

    test(
      'Edge Case: Deve inicializar com apenas o email e manter demais campos opcionais como nulos',
      () {
        // 1. Arrange
        const email = 'usuario.minimo@monamienet.org';

        // 2. Act
        final user = UserModel(email: email);

        // 3. Assert
        expect(user.email, email);
        expect(user.name, isNull);
        expect(user.lat, isNull);
        expect(user.lng, isNull);
        expect(user.capturedAt, isNull);
        expect(user.isPublishing, isNull);
      },
    );

    test(
      'Edge Case: Deve inicializar com email como string vazia sem lançar erro',
      () {
        // 1. Arrange
        const emailVazio = '';

        // 2. Act
        final user = UserModel(email: emailVazio);

        // 3. Assert
        expect(user.email, isEmpty);
      },
    );
  });

  group('UserModel - igualdade por conteúdo', () {
    UserModel bia({DateTime? capturedAt}) => UserModel(
      email: 'bia@example.com',
      name: 'Bia',
      lat: -22.9,
      lng: -43.1,
      capturedAt: capturedAt ?? DateTime(2026, 11, 2, 9, 30),
      isPublishing: true,
    );

    test('Happy Path: Deve igualar dois modelos com os mesmos campos', () {
      // 1. Arrange
      final first = bia();

      // 2. Act
      final second = bia();

      // 3. Assert
      expect(second, first);
      expect(second.hashCode, first.hashCode);
    });

    test('Sad Path: Deve diferenciar modelos com outro momento de captura', () {
      // 1. Arrange
      final first = bia();

      // 2. Act
      final moved = bia(capturedAt: DateTime(2026, 11, 2, 9, 45));

      // 3. Assert
      expect(moved, isNot(first));
    });
  });

  group('UserModel.publishedName - Unit Test Suite', () {
    test('Happy Path: Deve publicar o nome sem os espaços das pontas', () {
      // 1. Arrange
      const user = UserModel(email: 'ana@x.com', name: '  Ana Souza ');

      // 2. Act
      final name = user.publishedName;

      // 3. Assert
      expect(name, 'Ana Souza');
    });

    test('Edge Case: Deve publicar "Nome não informado" sem nome', () {
      // 1. Arrange
      const user = UserModel(email: 'ana@x.com');

      // 2. Act
      final name = user.publishedName;

      // 3. Assert
      expect(name, UserModel.noName);
      expect(UserModel.noName, 'Nome não informado');
    });

    test('Sad Path: Deve publicar "Nome não informado" com um nome só de '
        'espaços', () {
      // 1. Arrange
      const user = UserModel(email: 'ana@x.com', name: '   ');

      // 2. Act
      final name = user.publishedName;

      // 3. Assert
      expect(name, UserModel.noName);
    });
  });
}
