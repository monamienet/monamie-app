import 'package:flutter_test/flutter_test.dart';

/// Simulador fiel da engine de regras do Firestore correspondente ao arquivo `firestore.rules`.
class FirestoreRulesSimulator {
  /// Avalia a regra de leitura em `/usuarios/{usuarioEmail}`
  static bool evaluateReadUserDoc({
    required Map<String, dynamic>? authToken,
    required String targetDocEmail,
    required Map<String, dynamic> resourceData,
  }) {
    if (authToken == null || authToken['email'] == null) return false;
    final requesterEmail = authToken['email'].toString();

    // 1. isDocOwner
    if (requesterEmail == targetDocEmail) return true;

    // 2. hasRoleInGroup(resource.data.grupo_ativo)
    final grupoAtivo = resourceData['grupo_ativo'] as String?;
    if (grupoAtivo == null) return false;

    final groupRoles = authToken['group_roles'];
    if (groupRoles is! Map) return false;

    return groupRoles[grupoAtivo] != null;
  }

  /// Avalia a regra de criação/atualização em `/usuarios/{usuarioEmail}`
  static bool evaluateWriteUserDoc({
    required Map<String, dynamic>? authToken,
    required String targetDocEmail,
    required Map<String, dynamic> incomingData,
  }) {
    if (authToken == null || authToken['email'] == null) return false;
    final requesterEmail = authToken['email'].toString();

    // 1. isDocOwner
    if (requesterEmail != targetDocEmail) return false;

    // 2. isObservavel (system-wide)
    final groupRoles = authToken['group_roles'];
    if (groupRoles is! Map) return false;
    final hasObservableRole = groupRoles.values.any(
      (role) => role == 'MEMBER' || role == 'MANAGER',
    );
    if (!hasObservableRole) return false;

    // 3. keys().hasOnly(...)
    const allowedKeys = [
      'email',
      'nome',
      'lat',
      'lng',
      'timestamp',
      'isTracked',
      'grupo_ativo'
    ];
    for (final key in incomingData.keys) {
      if (!allowedKeys.contains(key)) return false;
    }

    // 4. isObservavelInGroup(request.resource.data.grupo_ativo)
    final grupoAtivo = incomingData['grupo_ativo'];
    if (grupoAtivo != null) {
      final roleInTargetGroup = groupRoles[grupoAtivo];
      if (roleInTargetGroup != 'MEMBER' && roleInTargetGroup != 'MANAGER') {
        return false; // Usuário tentando forjar grupo onde não é MEMBER ou MANAGER!
      }
    }

    return true;
  }

  /// Avalia a regra de leitura em `/usuarios/{usuarioEmail}/historico_posicoes/{pontoId}`
  static bool evaluateReadHistory({
    required Map<String, dynamic>? authToken,
    required String targetUserEmail,
    required Map<String, dynamic> parentUserData,
  }) {
    if (authToken == null || authToken['email'] == null) return false;
    final requesterEmail = authToken['email'].toString();

    if (requesterEmail == targetUserEmail) return true;

    final grupoAtivo = parentUserData['grupo_ativo'] as String?;
    if (grupoAtivo == null) return false;

    final groupRoles = authToken['group_roles'];
    if (groupRoles is! Map) return false;

    return groupRoles[grupoAtivo] != null;
  }
}

void main() {
  group('Simulação e Validação das Regras de Segurança (firestore.rules)', () {
    const emailGuardaA = 'guarda.a@monamienet.org';
    const emailGuardaB = 'guarda.b@monamienet.org';
    const emailObservador = 'chefe.seguranca@monamienet.org';
    const emailInvasor = 'estudante.externo@monamienet.org';

    const grupoSeguranca = 'seguranca-operacional@monamienet.org';
    const grupoTransporte = 'transporte-vans@monamienet.org';

    late Map<String, dynamic> tokenGuardaA;
    late Map<String, dynamic> tokenObservadorSeguranca;
    late Map<String, dynamic> tokenInvasorSemGrupo;

    setUp(() {
      tokenGuardaA = {
        'email': emailGuardaA,
        'group_roles': {
          grupoSeguranca: 'MEMBER',
        },
      };

      tokenObservadorSeguranca = {
        'email': emailObservador,
        'group_roles': {
          grupoSeguranca: 'MANAGER',
        },
      };

      tokenInvasorSemGrupo = {
        'email': emailInvasor,
        'group_roles': {
          'grupo-outro@monamienet.org': 'MEMBER',
        },
      };
    });

    // -------------------------------------------------------------
    // LEITURA DE DOCUMENTO DE USUÁRIO
    // -------------------------------------------------------------
    test('Happy Path: LEITURA - O próprio usuário pode ler seu próprio documento sempre', () {
      // 1. Arrange
      final docGuardaA = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaA,
        resourceData: docGuardaA,
      );

      // 3. Assert
      expect(permitido, isTrue);
    });

    test('Happy Path: LEITURA - Observador com papel no mesmo grupo_ativo pode ler o documento', () {
      // 1. Arrange
      final docGuardaA = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: tokenObservadorSeguranca,
        targetDocEmail: emailGuardaA,
        resourceData: docGuardaA,
      );

      // 3. Assert
      expect(permitido, isTrue);
    });

    test('Edge Case: LEITURA - Terceiro não pode ler documento sem grupo_ativo definido', () {
      // 1. Arrange
      final docSemGrupo = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'grupo_ativo': null,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: tokenObservadorSeguranca,
        targetDocEmail: emailGuardaA,
        resourceData: docSemGrupo,
      );

      // 3. Assert
      expect(permitido, isFalse);
    });

    test('Sad Path: LEITURA - Usuário de OUTRO grupo é TERMINANTEMENTE BLOQUEADO', () {
      // 1. Arrange
      final docGuardaA = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: tokenInvasorSemGrupo,
        targetDocEmail: emailGuardaA,
        resourceData: docGuardaA,
      );

      // 3. Assert
      expect(permitido, isFalse, reason: 'Usuário de outro grupo NÃO pode ler coordenadas!');
    });

    test('Sad Path: LEITURA - Requisição sem token de autenticação é bloqueada', () {
      // 1. Arrange
      final docGuardaA = {
        'email': emailGuardaA,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: null,
        targetDocEmail: emailGuardaA,
        resourceData: docGuardaA,
      );

      // 3. Assert
      expect(permitido, isFalse);
    });

    // -------------------------------------------------------------
    // ESCRITA DE DOCUMENTO DE USUÁRIO
    // -------------------------------------------------------------
    test('Happy Path: ESCRITA - Usuário pode atualizar suas próprias coordenadas no seu grupo legítimo', () {
      // 1. Arrange
      final updateValido = {
        'email': emailGuardaA,
        'lat': -22.9045,
        'lng': -43.1330,
        'timestamp': DateTime.now(),
        'isTracked': true,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaA,
        incomingData: updateValido,
      );

      // 3. Assert
      expect(permitido, isTrue);
    });

    test('Edge Case: ESCRITA - Usuário com papel MANAGER no grupo pode atualizar documento', () {
      // 1. Arrange
      final updateManager = {
        'email': emailObservador,
        'lat': -22.9045,
        'lng': -43.1330,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenObservadorSeguranca,
        targetDocEmail: emailObservador,
        incomingData: updateManager,
      );

      // 3. Assert
      expect(permitido, isTrue);
    });

    test('Sad Path: ESCRITA - Usuário é BLOQUEADO se tentar forjar grupo onde não é MEMBER ou MANAGER', () {
      // 1. Arrange
      final updateFraudulento = {
        'email': emailGuardaA,
        'lat': -22.9045,
        'lng': -43.1330,
        'grupo_ativo': grupoTransporte, // Guarda A pertence a Segurança, não Transporte
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaA,
        incomingData: updateFraudulento,
      );

      // 3. Assert
      expect(permitido, isFalse, reason: 'Firestore deve rejeitar grupos forjados!');
    });

    test('Sad Path: ESCRITA - Usuário é BLOQUEADO ao tentar atualizar documento de outra pessoa', () {
      // 1. Arrange
      final updateAlheio = {
        'email': emailGuardaB,
        'lat': -22.90,
        'lng': -43.13,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaB,
        incomingData: updateAlheio,
      );

      // 3. Assert
      expect(permitido, isFalse);
    });

    test('Sad Path: ESCRITA - Rejeição de campos não permitidos (hasOnly)', () {
      // 1. Arrange
      final updateComCampoInvalido = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'isAdmin': true,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaA,
        incomingData: updateComCampoInvalido,
      );

      // 3. Assert
      expect(permitido, isFalse);
    });

    test('Sad Path: ESCRITA - Requisição sem autenticação é rejeitada', () {
      // 1. Arrange
      final update = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: null,
        targetDocEmail: emailGuardaA,
        incomingData: update,
      );

      // 3. Assert
      expect(permitido, isFalse);
    });

    // -------------------------------------------------------------
    // HISTÓRICO DE POSIÇÕES
    // -------------------------------------------------------------
    test('Happy Path: HISTÓRICO - Membro do grupo ativo pode ler histórico de posições', () {
      // 1. Arrange
      final parentDoc = {
        'email': emailGuardaA,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateReadHistory(
        authToken: tokenObservadorSeguranca,
        targetUserEmail: emailGuardaA,
        parentUserData: parentDoc,
      );

      // 3. Assert
      expect(permitido, isTrue);
    });

    test('Sad Path: HISTÓRICO - Usuário de outro grupo NÃO pode ler histórico de posições', () {
      // 1. Arrange
      final parentDoc = {
        'email': emailGuardaA,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateReadHistory(
        authToken: tokenInvasorSemGrupo,
        targetUserEmail: emailGuardaA,
        parentUserData: parentDoc,
      );

      // 3. Assert
      expect(permitido, isFalse);
    });

    test('Sad Path: HISTÓRICO - Requisição sem autenticação é rejeitada', () {
      // 1. Arrange
      final parentDoc = {
        'email': emailGuardaA,
        'grupo_ativo': grupoSeguranca,
      };

      // 2. Act
      final permitido = FirestoreRulesSimulator.evaluateReadHistory(
        authToken: null,
        targetUserEmail: emailGuardaA,
        parentUserData: parentDoc,
      );

      // 3. Assert
      expect(permitido, isFalse);
    });
  });
}
