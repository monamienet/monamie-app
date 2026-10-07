import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

void main() {
  group('UserModel Tests (widget_test)', () {
    test('Happy Path: Deve serializar campos do UserModel no toMap()', () {
      // 1. Arrange
      final now = DateTime(2026, 9, 18, 12, 0, 0);
      final user = UserModel(
        email: 'guarda1@id.uff.br',
        nome: 'Guarda Teste',
        lat: -22.9041,
        lng: -43.1329,
        timestamp: now,
        isTracked: true,
        grupoAtivo: 'seguranca-gragoata@id.uff.br',
      );

      // 2. Act
      final map = user.toMap();

      // 3. Assert
      expect(map['email'], 'guarda1@id.uff.br');
      expect(map['nome'], 'Guarda Teste');
      expect(map['lat'], -22.9041);
      expect(map['lng'], -43.1329);
      expect(map['isTracked'], true);
      expect(map['grupo_ativo'], 'seguranca-gragoata@id.uff.br');
    });

    test('Happy Path: Deve desserializar dados completos no fromMap()', () {
      // 1. Arrange
      final dataMap = {
        'email': 'guarda1@id.uff.br',
        'nome': 'Guarda Teste',
        'lat': -22.9041,
        'lng': -43.1329,
        'isTracked': true,
        'grupo_ativo': 'seguranca-gragoata@id.uff.br',
      };

      // 2. Act
      final deserialized = UserModel.fromMap(dataMap);

      // 3. Assert
      expect(deserialized.email, 'guarda1@id.uff.br');
      expect(deserialized.nome, 'Guarda Teste');
      expect(deserialized.lat, -22.9041);
      expect(deserialized.lng, -43.1329);
      expect(deserialized.isTracked, true);
      expect(deserialized.grupoAtivo, 'seguranca-gragoata@id.uff.br');
    });

    test('Edge Case: Deve lidar com grupo_ativo ausente no fromMap() mantendo grupoAtivo nulo', () {
      // 1. Arrange
      final mapSemGrupo = {
        'email': 'observador@id.uff.br',
        'nome': 'Observador Teste',
      };

      // 2. Act
      final userWithoutGroup = UserModel.fromMap(mapSemGrupo);

      // 3. Assert
      expect(userWithoutGroup.grupoAtivo, isNull);
    });

    test('Edge Case: toMap() não deve incluir chave grupo_ativo quando este for nulo', () {
      // 1. Arrange
      final userWithoutGroup = UserModel(
        email: 'observador@id.uff.br',
        nome: 'Observador Teste',
        grupoAtivo: null,
      );

      // 2. Act
      final map = userWithoutGroup.toMap();

      // 3. Assert
      expect(map.containsKey('grupo_ativo'), isFalse);
    });

    test('Sad Path: fromMap() deve lançar TypeError quando campo numérico receber tipo incompatível', () {
      // 1. Arrange
      final mapInvalido = {
        'email': 'erro@id.uff.br',
        'lat': 'lat_invalida_string',
      };

      // 2. Act
      action() => UserModel.fromMap(mapInvalido);

      // 3. Assert
      expect(action, throwsA(isA<TypeError>()));
    });
  });
}
