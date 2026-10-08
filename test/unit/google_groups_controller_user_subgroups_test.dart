import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';

void main() {
  group('GoogleGroupsController.userSubgroups - Suíte de Testes Unitários', () {
    test('Happy Path: retorna grupos do usuário que são subgrupos raiz', () {
      // 1. Arrange
      final root = [
        {'type': 'GROUP', 'email': 'sub@x.com'},
        {'type': 'USER', 'email': 'user@x.com'},
      ];
      final userGroups = [
        {'email': 'sub@x.com', 'name': 'Sub', 'description': 'D'},
        {'email': 'other@x.com', 'name': 'Other', 'description': 'O'},
      ];

      // 2. Act
      final result = GoogleGroupsController.userSubgroups(root, userGroups);

      // 3. Assert
      expect(result.length, 1);
      expect(result.first.name, 'Sub');
      expect(result.first.email, 'sub@x.com');
      expect(result.first.description, 'D');
    });

    test('Edge Case: email casa ignorando caixa e espaços', () {
      // 1. Arrange
      final root = [
        {'type': 'GROUP', 'email': '  SUB@x.com '},
      ];
      final userGroups = [
        {'email': 'sub@X.com', 'name': 'Sub'},
      ];

      // 2. Act
      final result = GoogleGroupsController.userSubgroups(root, userGroups);

      // 3. Assert
      expect(result.length, 1);
    });

    test('Edge Case: descrição ausente vira string vazia', () {
      // 1. Arrange
      final root = [
        {'type': 'GROUP', 'email': 'sub@x.com'},
      ];
      final userGroups = [
        {'email': 'sub@x.com', 'name': 'Sub'},
      ];

      // 2. Act
      final result = GoogleGroupsController.userSubgroups(root, userGroups);

      // 3. Assert
      expect(result.first.description, '');
    });

    test('Sad Path: ignora entidades space/ e que não são GROUP', () {
      // 1. Arrange
      final root = [
        {'type': 'GROUP', 'email': 'space/abc'},
        {'type': 'USER', 'email': 'u@x.com'},
      ];
      final userGroups = [
        {'email': 'space/abc', 'name': 'Space'},
        {'email': 'u@x.com', 'name': 'U'},
      ];

      // 2. Act
      final result = GoogleGroupsController.userSubgroups(root, userGroups);

      // 3. Assert
      expect(result, isEmpty);
    });
  });
}

