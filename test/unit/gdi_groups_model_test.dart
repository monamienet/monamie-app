import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/models/gdi_groups_model.dart';

void main() {
  group('GdiGroups.fromJson - Suíte de Testes Unitários', () {
    test('Happy Path: deve ler description e id como gid', () {
      // 1. Arrange
      final json = {'id': 'g1', 'description': 'desc', 'name': 'N', 'email': 'e@x.com'};

      // 2. Act
      final group = GdiGroups.fromJson(json);

      // 3. Assert
      expect(group.gid, 'g1');
      expect(group.description, 'desc');
      expect(group.name, 'N');
      expect(group.email, 'e@x.com');
    });

    test('Edge Case: deve usar descricao legada quando description ausente', () {
      // 1. Arrange
      final json = {'id': 'g1', 'descricao': 'legado'};

      // 2. Act
      final group = GdiGroups.fromJson(json);

      // 3. Assert
      expect(group.description, 'legado');
    });

    test('Edge Case: description tem prioridade sobre descricao', () {
      // 1. Arrange
      final json = {'description': 'novo', 'descricao': 'legado'};

      // 2. Act
      final group = GdiGroups.fromJson(json);

      // 3. Assert
      expect(group.description, 'novo');
    });

    test('Sad Path: mapa vazio deve resultar em campos nulos', () {
      // 1. Arrange
      final json = <String, dynamic>{};

      // 2. Act
      final group = GdiGroups.fromJson(json);

      // 3. Assert
      expect(group.gid, isNull);
      expect(group.description, isNull);
    });
  });
}

