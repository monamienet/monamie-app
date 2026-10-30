import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

void main() {
  group('UserModel - Testes Unitários de Inicialização e Serialização', () {
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
          nome: 'Vigilante Silva',
          lat: -22.9000,
          lng: -43.1300,
          timestamp: dataHora,
          isTracked: true,
          grupoAtivo: 'vigilancia-praia-vermelha@monamienet.org',
        );

        // 2. Act
        final map = user.toMap();

        // 3. Assert
        expect(map, {
          'email': 'seguranca@monamienet.org',
          'nome': 'Vigilante Silva',
          'lat': -22.9000,
          'lng': -43.1300,
          'timestamp': dataHora,
          'isTracked': true,
          'grupo_ativo': 'vigilancia-praia-vermelha@monamienet.org',
        });
      },
    );

    test(
      'Edge Case: toMap() NÃO deve incluir o campo grupo_ativo quando for nulo',
      () {
        // 1. Arrange
        final user = UserModel(
          email: 'gestor@monamienet.org',
          nome: 'Gestor Teste',
          isTracked: false,
          grupoAtivo: null,
        );

        // 2. Act
        final map = user.toMap();

        // 3. Assert
        expect(map.containsKey('grupo_ativo'), isFalse);
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
          'nome': 'Motorista Santos',
          'lat': -22.8900,
          'lng': -43.1200,
          'timestamp': Timestamp.fromDate(timestampEsperado),
          'isTracked': true,
          'grupo_ativo': 'transporte-vans@monamienet.org',
        };

        // 2. Act
        final user = UserModel.fromMap(mapFirestore);

        // 3. Assert
        expect(user.email, 'motorista@monamienet.org');
        expect(user.nome, 'Motorista Santos');
        expect(user.lat, -22.8900);
        expect(user.lng, -43.1200);
        expect(user.timestamp, timestampEsperado);
        expect(user.isTracked, isTrue);
        expect(user.grupoAtivo, 'transporte-vans@monamienet.org');
      },
    );

    test(
      'Edge Case: fromMap() deve tratar ausência de grupo_ativo atribuindo nulo',
      () {
        // 1. Arrange
        final mapSemGrupo = {
          'email': 'usuario.sem.grupo@monamienet.org',
          'nome': 'Usuário Sem Grupo',
          'lat': -22.9050,
          'lng': -43.1310,
          'isTracked': false,
        };

        // 2. Act
        final user = UserModel.fromMap(mapSemGrupo);

        // 3. Assert
        expect(user.grupoAtivo, isNull);
      },
    );

    test(
      'Edge Case: fromMap() deve converter valor numérico para String no grupo_ativo',
      () {
        // 1. Arrange
        final mapComTipoInesperado = {
          'email': 'teste@monamienet.org',
          'grupo_ativo': 12345,
        };

        // 2. Act
        final user = UserModel.fromMap(mapComTipoInesperado);

        // 3. Assert
        expect(user.grupoAtivo, '12345');
      },
    );
  });
}
