import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_member_model.dart';

void main() {
  group('GoogleGroupModel & Member - Testes Unitários', () {
    // -------------------------------------------------------------
    // GoogleGroupMember
    // -------------------------------------------------------------
    test('Happy Path: Deve instanciar GoogleGroupMember com propriedades válidas', () {
      // 1. Arrange
      const name = 'Carlos Oliveira';
      const email = 'carlos@id.uff.br';
      const role = GoogleGroupRole.member;

      // 2. Act
      final member = GoogleGroupMember(
        name: name,
        email: email,
        role: role,
      );

      // 3. Assert
      expect(member.name, 'Carlos Oliveira');
      expect(member.email, 'carlos@id.uff.br');
      expect(member.role, GoogleGroupRole.member);
    });

    test('Happy Path: Deve conter todos os papéis previstos no enum GoogleGroupRole', () {
      // 1. Arrange
      final expectedRoles = [
        GoogleGroupRole.owner,
        GoogleGroupRole.manager,
        GoogleGroupRole.member,
      ];

      // 2. Act
      final roles = GoogleGroupRole.values;

      // 3. Assert
      expect(roles, containsAll(expectedRoles));
    });

    // -------------------------------------------------------------
    // GoogleGroupModel - Construtor Padrão
    // -------------------------------------------------------------
    test('Happy Path: Deve instanciar GoogleGroupModel com propriedades corretas', () {
      // 1. Arrange
      final membersList = [
        GoogleGroupMember(
          name: 'Carlos Oliveira',
          email: 'carlos@id.uff.br',
          role: GoogleGroupRole.member,
        ),
        GoogleGroupMember(
          name: 'Ana Souza',
          email: 'ana@id.uff.br',
          role: GoogleGroupRole.manager,
        ),
      ];

      // 2. Act
      final grupo = GoogleGroupModel(
        name: 'Vigilância Campus Gragoatá',
        email: 'vigilancia-gragoata@id.uff.br',
        description: 'Equipe responsável pela vigilância patrimonial do Campus Gragoatá',
        members: membersList,
        subgroups: [],
      );

      // 3. Assert
      expect(grupo.name, 'Vigilância Campus Gragoatá');
      expect(grupo.email, 'vigilancia-gragoata@id.uff.br');
      expect(grupo.description, contains('Gragoatá'));
      expect(grupo.members.length, 2);
      expect(grupo.members.first.role, GoogleGroupRole.member);
      expect(grupo.members.last.role, GoogleGroupRole.manager);
    });

    // -------------------------------------------------------------
    // GoogleGroupModel - fromJson
    // -------------------------------------------------------------
    test('Happy Path: fromJson deve construir o modelo adequadamente a partir de json válido', () {
      // 1. Arrange
      final json = {
        'name': 'Transporte UFF',
        'email': 'transporte@id.uff.br',
        'description': 'Coordenação de frotas',
        'members': <GoogleGroupMember>[],
        'subgroups': <GoogleGroupModel>[],
      };

      // 2. Act
      final model = GoogleGroupModel.fromJson(json);

      // 3. Assert
      expect(model.name, 'Transporte UFF');
      expect(model.email, 'transporte@id.uff.br');
      expect(model.description, 'Coordenação de frotas');
      expect(model.members, isEmpty);
      expect(model.subgroups, isEmpty);
    });

    test('Edge Case: fromJson com strings vazias e coleções vazias deve instanciar modelo vazio', () {
      // 1. Arrange
      final jsonVazio = {
        'name': '',
        'email': '',
        'description': '',
        'members': <GoogleGroupMember>[],
        'subgroups': <GoogleGroupModel>[],
      };

      // 2. Act
      final model = GoogleGroupModel.fromJson(jsonVazio);

      // 3. Assert
      expect(model.name, isEmpty);
      expect(model.email, isEmpty);
      expect(model.description, isEmpty);
      expect(model.members, isEmpty);
      expect(model.subgroups, isEmpty);
    });

    test('Edge Case: fromJson deve converter valores numéricos em String via toString()', () {
      // 1. Arrange
      final jsonNumerico = {
        'name': 12345,
        'email': 67890,
        'description': 99999,
        'members': <GoogleGroupMember>[],
        'subgroups': <GoogleGroupModel>[],
      };

      // 2. Act
      final model = GoogleGroupModel.fromJson(jsonNumerico);

      // 3. Assert
      expect(model.name, '12345');
      expect(model.email, '67890');
      expect(model.description, '99999');
    });

    test('Sad Path: fromJson deve lançar TypeError quando members não for List<GoogleGroupMember>', () {
      // 1. Arrange
      final jsonInvalido = {
        'name': 'Grupo Inválido',
        'email': 'invalido@id.uff.br',
        'description': 'Sem members válidos',
        'members': 'string_invalida_em_vez_de_lista',
        'subgroups': <GoogleGroupModel>[],
      };

      // 2. Act
      action() => GoogleGroupModel.fromJson(jsonInvalido);

      // 3. Assert
      expect(action, throwsA(isA<TypeError>()));
    });

    test('Sad Path: fromJson deve lançar TypeError quando subgroups não for List<GoogleGroupModel>', () {
      // 1. Arrange
      final jsonInvalido = {
        'name': 'Grupo Inválido',
        'email': 'invalido@id.uff.br',
        'description': 'Sem subgroups válidos',
        'members': <GoogleGroupMember>[],
        'subgroups': 'string_invalida_em_vez_de_lista',
      };

      // 2. Act
      action() => GoogleGroupModel.fromJson(jsonInvalido);

      // 3. Assert
      expect(action, throwsA(isA<TypeError>()));
    });
  });
}
