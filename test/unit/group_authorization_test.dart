import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';

/// Função pura auxiliar que encapsula a lógica de filtragem implementada
/// em `GoogleGroupsController.getObservableGroupsForUser` para garantir testabilidade
/// determinística e isolada de chamadas estáticas do Firebase Auth.
List<GoogleGroupModel> filterObservableGroups({
  required Map<String, dynamic>? claims,
  required List<GoogleGroupModel> availableGroups,
}) {
  if (claims == null || claims.isEmpty) return [];

  final allowedEmails = claims.entries
      .where((e) => e.value == 'MEMBER' || e.value == 'MANAGER')
      .map((e) => e.key.toString().toLowerCase().trim())
      .toSet();

  return availableGroups
      .where((g) => allowedEmails.contains(g.email.toLowerCase().trim()))
      .toList();
}

/// Função pura auxiliar que encapsula a lógica de resolução de grupo ativo
/// implementada em `TrackingController._startService`.
String? resolveActiveGroupEmail({
  required List<GoogleGroupModel> observableGroups,
  GoogleGroupModel? currentSelectedGroup,
}) {
  if (observableGroups.isEmpty) {
    return null; // Não autorizado a rastrear
  }

  if (observableGroups.length == 1) {
    return observableGroups.first.email; // Auto-seleciona único grupo observável
  }

  // Se houver mais de um grupo observável, verifica se o grupo atualmente selecionado é um deles
  if (currentSelectedGroup != null &&
      observableGroups.any((g) => g.email.trim().toLowerCase() == currentSelectedGroup.email.trim().toLowerCase())) {
    return currentSelectedGroup.email;
  }

  // Requer escolha do usuário (bottomsheet)
  return 'PROMPT_SELECTION';
}

void main() {
  group('Lógica de Autorização e Filtro de Grupos Operacionais (Opção 3)', () {
    late List<GoogleGroupModel> gruposMock;

    setUp(() {
      gruposMock = [
        GoogleGroupModel(
          name: 'Segurança Praia Vermelha',
          email: 'seguranca-pv@id.uff.br',
          description: '',
          members: [],
          subgroups: [],
        ),
        GoogleGroupModel(
          name: 'Transporte Gragoatá',
          email: 'transporte-gragoata@id.uff.br',
          description: '',
          members: [],
          subgroups: [],
        ),
        GoogleGroupModel(
          name: 'Coordenação Geral Harpia',
          email: 'coordenacao-harpia@id.uff.br',
          description: '',
          members: [],
          subgroups: [],
        ),
      ];
    });

    // -------------------------------------------------------------
    // filterObservableGroups
    // -------------------------------------------------------------
    test('Happy Path: Deve retornar grupos onde o usuário possui papel MEMBER ou MANAGER', () {
      // 1. Arrange
      final claimsMembroEManager = {
        'seguranca-pv@id.uff.br': 'MEMBER',
        'transporte-gragoata@id.uff.br': 'MANAGER',
        'coordenacao-harpia@id.uff.br': 'OWNER',
      };

      // 2. Act
      final observaveis = filterObservableGroups(
        claims: claimsMembroEManager,
        availableGroups: gruposMock,
      );

      // 3. Assert
      expect(observaveis.length, 2);
      expect(observaveis.map((g) => g.email), containsAll([
        'seguranca-pv@id.uff.br',
        'transporte-gragoata@id.uff.br',
      ]));
      expect(observaveis.map((g) => g.email), isNot(contains('coordenacao-harpia@id.uff.br')));
    });

    test('Edge Case: Deve ser resiliente a diferenças de maiúsculas/minúsculas e espaços nos emails', () {
      // 1. Arrange
      final claimsComVariacoes = {
        '  SEGURANCA-PV@ID.UFF.BR ': 'MEMBER',
      };

      // 2. Act
      final observaveis = filterObservableGroups(
        claims: claimsComVariacoes,
        availableGroups: gruposMock,
      );

      // 3. Assert
      expect(observaveis.length, 1);
      expect(observaveis.first.email, 'seguranca-pv@id.uff.br');
    });

    test('Edge Case: Deve retornar lista vazia quando availableGroups for uma lista vazia', () {
      // 1. Arrange
      final claims = {'seguranca-pv@id.uff.br': 'MEMBER'};

      // 2. Act
      final observaveis = filterObservableGroups(
        claims: claims,
        availableGroups: [],
      );

      // 3. Assert
      expect(observaveis, isEmpty);
    });

    test('Edge Case: Deve retornar lista vazia quando claims for um mapa vazio', () {
      // 1. Arrange
      final claimsVazio = <String, dynamic>{};

      // 2. Act
      final observaveis = filterObservableGroups(
        claims: claimsVazio,
        availableGroups: gruposMock,
      );

      // 3. Assert
      expect(observaveis, isEmpty);
    });

    test('Sad Path: Deve retornar lista vazia quando claims for nulo', () {
      // 1. Arrange
      const Map<String, dynamic>? claimsNulo = null;

      // 2. Act
      final observaveis = filterObservableGroups(
        claims: claimsNulo,
        availableGroups: gruposMock,
      );

      // 3. Assert
      expect(observaveis, isEmpty);
    });

    test('Sad Path: NÃO deve considerar grupos onde o usuário é apenas OWNER ou METAUSER', () {
      // 1. Arrange
      final claimsApenasProprietario = {
        'coordenacao-harpia@id.uff.br': 'OWNER',
        'transporte-gragoata@id.uff.br': 'METAUSER',
      };

      // 2. Act
      final observaveis = filterObservableGroups(
        claims: claimsApenasProprietario,
        availableGroups: gruposMock,
      );

      // 3. Assert
      expect(observaveis, isEmpty);
    });

    test('Sad Path: Deve retornar lista vazia quando claims contiver apenas emails que não existem nos grupos disponíveis', () {
      // 1. Arrange
      final claimsInexistentes = {
        'grupo.fantasma@id.uff.br': 'MEMBER',
      };

      // 2. Act
      final observaveis = filterObservableGroups(
        claims: claimsInexistentes,
        availableGroups: gruposMock,
      );

      // 3. Assert
      expect(observaveis, isEmpty);
    });

    // -------------------------------------------------------------
    // resolveActiveGroupEmail
    // -------------------------------------------------------------
    test('Happy Path: Resolução de grupo ativo com 1 grupo observável deve auto-selecionar imediatamente', () {
      // 1. Arrange
      final observableGroups = [gruposMock[0]];

      // 2. Act
      final active = resolveActiveGroupEmail(
        observableGroups: observableGroups,
        currentSelectedGroup: null,
      );

      // 3. Assert
      expect(active, 'seguranca-pv@id.uff.br');
    });

    test('Happy Path: Resolução de grupo ativo com múltiplos grupos e grupo atual válido deve usar o atual', () {
      // 1. Arrange
      final observableGroups = [gruposMock[0], gruposMock[1]];
      final currentSelectedGroup = gruposMock[1];

      // 2. Act
      final active = resolveActiveGroupEmail(
        observableGroups: observableGroups,
        currentSelectedGroup: currentSelectedGroup,
      );

      // 3. Assert
      expect(active, 'transporte-gragoata@id.uff.br');
    });

    test('Edge Case: Resolução de grupo ativo com múltiplos grupos sem grupo atual selecionado deve exigir seleção', () {
      // 1. Arrange
      final observableGroups = [gruposMock[0], gruposMock[1]];

      // 2. Act
      final active = resolveActiveGroupEmail(
        observableGroups: observableGroups,
        currentSelectedGroup: null,
      );

      // 3. Assert
      expect(active, 'PROMPT_SELECTION');
    });

    test('Edge Case: Resolução de grupo ativo deve casar grupo selecionado mesmo com variações de maiúsculas e espaços', () {
      // 1. Arrange
      final observableGroups = [gruposMock[0], gruposMock[1]];
      final currentWithSpaces = GoogleGroupModel(
        name: 'Segurança PV',
        email: '  SEGURANCA-PV@ID.UFF.BR  ',
        description: '',
        members: [],
        subgroups: [],
      );

      // 2. Act
      final active = resolveActiveGroupEmail(
        observableGroups: observableGroups,
        currentSelectedGroup: currentWithSpaces,
      );

      // 3. Assert
      expect(active, '  SEGURANCA-PV@ID.UFF.BR  ');
    });

    test('Sad Path: Resolução de grupo ativo com 0 grupos observáveis deve retornar null (não autorizado)', () {
      // 1. Arrange
      final List<GoogleGroupModel> emptyObservables = [];
      final currentSelectedGroup = gruposMock.first;

      // 2. Act
      final active = resolveActiveGroupEmail(
        observableGroups: emptyObservables,
        currentSelectedGroup: currentSelectedGroup,
      );

      // 3. Assert
      expect(active, isNull);
    });

    test('Sad Path: Resolução de grupo ativo com múltiplos grupos e grupo atual NÃO observável deve exigir seleção', () {
      // 1. Arrange
      final observableGroups = [gruposMock[0], gruposMock[1]];
      final currentNonObservable = gruposMock[2]; // Coordenação é OWNER, não observável

      // 2. Act
      final active = resolveActiveGroupEmail(
        observableGroups: observableGroups,
        currentSelectedGroup: currentNonObservable,
      );

      // 3. Assert
      expect(active, 'PROMPT_SELECTION');
    });
  });
}
