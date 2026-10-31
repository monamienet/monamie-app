import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

void main() {
  group('UserModel - Testes Unitários de Inicialização e Serialização', () {
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
          groupId: 'ti-suporte@monamienet.org',
        );

        // 3. Assert
        expect(user.email, 'servidor.ti@monamienet.org');
        expect(user.name, 'Servidor Teste');
        expect(user.lat, -22.9041);
        expect(user.lng, -43.1329);
        expect(user.capturedAt, dataHora);
        expect(user.isPublishing, isTrue);
        expect(user.groupId, 'ti-suporte@monamienet.org');
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
        expect(user.groupId, isNull);
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

    // -------------------------------------------------------------
    // toMap()
    // -------------------------------------------------------------
    test(
      'Happy Path: toMap() deve incluir todos os campos quando preenchidos',
      () {
        // 1. Arrange
        final dataHora = DateTime(2026, 9, 16, 21, 0, 0);
        final user = UserModel(
          email: 'seguranca@monamienet.org',
          name: 'Vigilante Silva',
          lat: -22.9000,
          lng: -43.1300,
          capturedAt: dataHora,
          isPublishing: true,
          groupId: 'vigilancia-praia-vermelha@monamienet.org',
        );

        // 2. Act
        final map = user.toMap();

        // 3. Assert
        expect(map, {
          'email': 'seguranca@monamienet.org',
          'name': 'Vigilante Silva',
          'lat': -22.9000,
          'lng': -43.1300,
          'capturedAt': dataHora,
          'isPublishing': true,
          'groupId': 'vigilancia-praia-vermelha@monamienet.org',
        });
      },
    );

    test(
      'Edge Case: toMap() NÃO deve incluir o campo groupId quando for nulo',
      () {
        // 1. Arrange
        final user = UserModel(
          email: 'gestor@monamienet.org',
          name: 'Gestor Teste',
          isPublishing: false,
          groupId: null,
        );

        // 2. Act
        final map = user.toMap();

        // 3. Assert
        expect(map.containsKey('groupId'), isFalse);
      },
    );

    test(
      'Edge Case: toMap() deve omitir todos os campos opcionais quando forem nulos',
      () {
        // 1. Arrange
        final user = UserModel(email: 'apenas.email@monamienet.org');

        // 2. Act
        final map = user.toMap();

        // 3. Assert
        expect(map, {'email': 'apenas.email@monamienet.org'});
      },
    );

    // -------------------------------------------------------------
    // fromMap()
    // -------------------------------------------------------------
    test(
      'Happy Path: fromMap() deve extrair todos os campos de dados válidos do Firestore',
      () {
        // 1. Arrange
        final timestampEsperado = DateTime(2026, 9, 16, 15, 0);
        final mapFirestore = {
          'email': 'motorista@monamienet.org',
          'name': 'Motorista Santos',
          'lat': -22.8900,
          'lng': -43.1200,
          'capturedAt': Timestamp.fromDate(timestampEsperado),
          'isPublishing': true,
          'groupId': 'transporte-vans@monamienet.org',
        };

        // 2. Act
        final user = UserModel.fromMap(mapFirestore);

        // 3. Assert
        expect(user.email, 'motorista@monamienet.org');
        expect(user.name, 'Motorista Santos');
        expect(user.lat, -22.8900);
        expect(user.lng, -43.1200);
        expect(user.capturedAt, timestampEsperado);
        expect(user.isPublishing, isTrue);
        expect(user.groupId, 'transporte-vans@monamienet.org');
      },
    );

    test(
      'Edge Case: fromMap() deve tratar ausência de groupId atribuindo nulo',
      () {
        // 1. Arrange
        final mapSemGrupo = {
          'email': 'usuario.sem.grupo@monamienet.org',
          'name': 'Usuário Sem Grupo',
          'lat': -22.9050,
          'lng': -43.1310,
          'isPublishing': false,
        };

        // 2. Act
        final user = UserModel.fromMap(mapSemGrupo);

        // 3. Assert
        expect(user.groupId, isNull);
      },
    );

    test(
      'Edge Case: fromMap() deve converter valor numérico para String no groupId',
      () {
        // 1. Arrange
        final mapComTipoInesperado = {
          'email': 'teste@monamienet.org',
          'groupId': 12345,
        };

        // 2. Act
        final user = UserModel.fromMap(mapComTipoInesperado);

        // 3. Assert
        expect(user.groupId, '12345');
      },
    );

    test('Edge Case: fromMap() com coordenadas numéricas zero (0.0, 0.0)', () {
      // 1. Arrange
      final mapCoordenadasZero = {
        'email': 'zero@monamienet.org',
        'lat': 0.0,
        'lng': 0.0,
      };

      // 2. Act
      final user = UserModel.fromMap(mapCoordenadasZero);

      // 3. Assert
      expect(user.lat, 0.0);
      expect(user.lng, 0.0);
    });

    test(
      'Sad Path: fromMap() deve lançar TypeError quando lat não for numérico',
      () {
        // 1. Arrange
        final mapComLatInvalida = {
          'email': 'teste.invalido@monamienet.org',
          'lat': 'coordenada_invalida_string',
        };

        // 2. Act
        action() => UserModel.fromMap(mapComLatInvalida);

        // 3. Assert
        expect(action, throwsA(isA<TypeError>()));
      },
    );

    test(
      'Sad Path: fromMap() deve lançar TypeError quando isPublishing não for booleano',
      () {
        // 1. Arrange
        final mapComTrackedInvalido = {
          'email': 'teste.invalido@monamienet.org',
          'isPublishing': 'nao_e_booleano',
        };

        // 2. Act
        action() => UserModel.fromMap(mapComTrackedInvalido);

        // 3. Assert
        expect(action, throwsA(isA<TypeError>()));
      },
    );

    // -------------------------------------------------------------
    // IDEMPOTÊNCIA / RECONSTRUÇÃO
    // -------------------------------------------------------------
    test(
      'Happy Path: UserModel reconstruído a partir de mapa serializado preserva todos os dados',
      () {
        // 1. Arrange
        final mapaOriginal = {
          'email': 'ronda.noturna@monamienet.org',
          'name': 'Ronda Noturna',
          'lat': -22.9100,
          'lng': -43.1400,
          'isPublishing': true,
          'groupId': 'seguranca-valonguinho@monamienet.org',
        };

        // 2. Act
        final reconstruido = UserModel.fromMap(mapaOriginal);

        // 3. Assert
        expect(reconstruido.email, mapaOriginal['email']);
        expect(reconstruido.name, mapaOriginal['name']);
        expect(reconstruido.lat, mapaOriginal['lat']);
        expect(reconstruido.lng, mapaOriginal['lng']);
        expect(reconstruido.isPublishing, mapaOriginal['isPublishing']);
        expect(reconstruido.groupId, mapaOriginal['groupId']);
      },
    );
  });
}
