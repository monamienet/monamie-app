import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

void main() {
  group('UserModel - Testes Unitários de Inicialização e Serialização', () {
    // -------------------------------------------------------------
    // CONSTRUTOR PADRÃO
    // -------------------------------------------------------------
    test('Happy Path: Deve inicializar corretamente com todos os campos válidos preenchidos', () {
      // 1. Arrange
      final dataHora = DateTime(2026, 9, 16, 20, 30, 0);

      // 2. Act
      final user = UserModel(
        email: 'servidor.ti@id.uff.br',
        nome: 'Servidor Teste',
        lat: -22.9041,
        lng: -43.1329,
        timestamp: dataHora,
        isTracked: true,
        grupoAtivo: 'ti-suporte@id.uff.br',
      );

      // 3. Assert
      expect(user.email, 'servidor.ti@id.uff.br');
      expect(user.nome, 'Servidor Teste');
      expect(user.lat, -22.9041);
      expect(user.lng, -43.1329);
      expect(user.timestamp, dataHora);
      expect(user.isTracked, isTrue);
      expect(user.grupoAtivo, 'ti-suporte@id.uff.br');
    });

    test('Edge Case: Deve inicializar com apenas o email e manter demais campos opcionais como nulos', () {
      // 1. Arrange
      const email = 'usuario.minimo@id.uff.br';

      // 2. Act
      final user = UserModel(email: email);

      // 3. Assert
      expect(user.email, email);
      expect(user.nome, isNull);
      expect(user.lat, isNull);
      expect(user.lng, isNull);
      expect(user.timestamp, isNull);
      expect(user.isTracked, isNull);
      expect(user.grupoAtivo, isNull);
    });

    test('Edge Case: Deve inicializar com email como string vazia sem lançar erro', () {
      // 1. Arrange
      const emailVazio = '';

      // 2. Act
      final user = UserModel(email: emailVazio);

      // 3. Assert
      expect(user.email, isEmpty);
    });

    // -------------------------------------------------------------
    // toMap()
    // -------------------------------------------------------------
    test('Happy Path: toMap() deve incluir todos os campos quando preenchidos', () {
      // 1. Arrange
      final dataHora = DateTime(2026, 9, 16, 21, 0, 0);
      final user = UserModel(
        email: 'seguranca@id.uff.br',
        nome: 'Vigilante Silva',
        lat: -22.9000,
        lng: -43.1300,
        timestamp: dataHora,
        isTracked: true,
        grupoAtivo: 'vigilancia-praia-vermelha@id.uff.br',
      );

      // 2. Act
      final map = user.toMap();

      // 3. Assert
      expect(map, {
        'email': 'seguranca@id.uff.br',
        'nome': 'Vigilante Silva',
        'lat': -22.9000,
        'lng': -43.1300,
        'timestamp': dataHora,
        'isTracked': true,
        'grupo_ativo': 'vigilancia-praia-vermelha@id.uff.br',
      });
    });

    test('Edge Case: toMap() NÃO deve incluir o campo grupo_ativo quando for nulo', () {
      // 1. Arrange
      final user = UserModel(
        email: 'gestor@id.uff.br',
        nome: 'Gestor Teste',
        isTracked: false,
        grupoAtivo: null,
      );

      // 2. Act
      final map = user.toMap();

      // 3. Assert
      expect(map.containsKey('grupo_ativo'), isFalse);
    });

    test('Edge Case: toMap() deve omitir todos os campos opcionais quando forem nulos', () {
      // 1. Arrange
      final user = UserModel(email: 'apenas.email@id.uff.br');

      // 2. Act
      final map = user.toMap();

      // 3. Assert
      expect(map, {'email': 'apenas.email@id.uff.br'});
    });

    // -------------------------------------------------------------
    // fromMap()
    // -------------------------------------------------------------
    test('Happy Path: fromMap() deve extrair todos os campos de dados válidos do Firestore', () {
      // 1. Arrange
      final timestampEsperado = DateTime(2026, 9, 16, 15, 0);
      final mapFirestore = {
        'email': 'motorista@id.uff.br',
        'nome': 'Motorista Santos',
        'lat': -22.8900,
        'lng': -43.1200,
        'timestamp': Timestamp.fromDate(timestampEsperado),
        'isTracked': true,
        'grupo_ativo': 'transporte-vans@id.uff.br',
      };

      // 2. Act
      final user = UserModel.fromMap(mapFirestore);

      // 3. Assert
      expect(user.email, 'motorista@id.uff.br');
      expect(user.nome, 'Motorista Santos');
      expect(user.lat, -22.8900);
      expect(user.lng, -43.1200);
      expect(user.timestamp, timestampEsperado);
      expect(user.isTracked, isTrue);
      expect(user.grupoAtivo, 'transporte-vans@id.uff.br');
    });

    test('Edge Case: fromMap() deve tratar ausência de grupo_ativo atribuindo nulo', () {
      // 1. Arrange
      final mapSemGrupo = {
        'email': 'usuario.sem.grupo@id.uff.br',
        'nome': 'Usuário Sem Grupo',
        'lat': -22.9050,
        'lng': -43.1310,
        'isTracked': false,
      };

      // 2. Act
      final user = UserModel.fromMap(mapSemGrupo);

      // 3. Assert
      expect(user.grupoAtivo, isNull);
    });

    test('Edge Case: fromMap() deve converter valor numérico para String no grupo_ativo', () {
      // 1. Arrange
      final mapComTipoInesperado = {
        'email': 'teste@id.uff.br',
        'grupo_ativo': 12345,
      };

      // 2. Act
      final user = UserModel.fromMap(mapComTipoInesperado);

      // 3. Assert
      expect(user.grupoAtivo, '12345');
    });

    test('Edge Case: fromMap() com coordenadas numéricas zero (0.0, 0.0)', () {
      // 1. Arrange
      final mapCoordenadasZero = {
        'email': 'zero@id.uff.br',
        'lat': 0.0,
        'lng': 0.0,
      };

      // 2. Act
      final user = UserModel.fromMap(mapCoordenadasZero);

      // 3. Assert
      expect(user.lat, 0.0);
      expect(user.lng, 0.0);
    });

    test('Sad Path: fromMap() deve lançar TypeError quando lat não for numérico', () {
      // 1. Arrange
      final mapComLatInvalida = {
        'email': 'teste.invalido@id.uff.br',
        'lat': 'coordenada_invalida_string',
      };

      // 2. Act
      action() => UserModel.fromMap(mapComLatInvalida);

      // 3. Assert
      expect(action, throwsA(isA<TypeError>()));
    });

    test('Sad Path: fromMap() deve lançar TypeError quando isTracked não for booleano', () {
      // 1. Arrange
      final mapComTrackedInvalido = {
        'email': 'teste.invalido@id.uff.br',
        'isTracked': 'nao_e_booleano',
      };

      // 2. Act
      action() => UserModel.fromMap(mapComTrackedInvalido);

      // 3. Assert
      expect(action, throwsA(isA<TypeError>()));
    });

    // -------------------------------------------------------------
    // IDEMPOTÊNCIA / RECONSTRUÇÃO
    // -------------------------------------------------------------
    test('Happy Path: UserModel reconstruído a partir de mapa serializado preserva todos os dados', () {
      // 1. Arrange
      final mapaOriginal = {
        'email': 'ronda.noturna@id.uff.br',
        'nome': 'Ronda Noturna',
        'lat': -22.9100,
        'lng': -43.1400,
        'isTracked': true,
        'grupo_ativo': 'seguranca-valonguinho@id.uff.br',
      };

      // 2. Act
      final reconstruido = UserModel.fromMap(mapaOriginal);

      // 3. Assert
      expect(reconstruido.email, mapaOriginal['email']);
      expect(reconstruido.nome, mapaOriginal['nome']);
      expect(reconstruido.lat, mapaOriginal['lat']);
      expect(reconstruido.lng, mapaOriginal['lng']);
      expect(reconstruido.isTracked, mapaOriginal['isTracked']);
      expect(reconstruido.grupoAtivo, mapaOriginal['grupo_ativo']);
    });
  });
}
