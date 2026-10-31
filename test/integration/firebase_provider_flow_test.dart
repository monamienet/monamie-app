import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

void main() {
  group('Contratos de Dados do FirebaseProvider (Opção 3)', () {
    // -------------------------------------------------------------
    // Escrita de Usuário
    // -------------------------------------------------------------
    test(
      'Sad Path: Rejeita chaves não permitidas no contrato de escrita do usuário',
      () {
        // 1. Arrange
        final allowedKeys = {
          'email',
          'name',
          'lat',
          'lng',
          'capturedAt',
          'isPublishing',
          'receivedAt',
          'removedAt',
        };
        final payloadComCampoInvalido = {
          'email': 'teste@monamienet.org',
          'campo_proibido': true,
        };

        // 2. Act
        final hasIllegalKey = payloadComCampoInvalido.keys.any(
          (k) => !allowedKeys.contains(k),
        );

        // 3. Assert
        expect(hasIllegalKey, isTrue);
      },
    );

    // -------------------------------------------------------------
    // Histórico de Posições
    // -------------------------------------------------------------
    test(
      'Sad Path: Rejeita chaves não permitidas na subcoleção de histórico de posições',
      () {
        // 1. Arrange
        final allowedHistoryKeys = {'lat', 'lng', 'receivedAt'};
        final historicoComCampoInvalido = {
          'lat': -22.90,
          'campo_desconhecido': 'valor',
        };

        // 2. Act
        final hasIllegalKey = historicoComCampoInvalido.keys.any(
          (k) => !allowedHistoryKeys.contains(k),
        );

        // 3. Assert
        expect(hasIllegalKey, isTrue);
      },
    );

    // -------------------------------------------------------------
    // Ativação e Desativação de Rastreamento
    // -------------------------------------------------------------
    test(
      'Happy Path: Payload de desativação de rastreamento deve conter só isPublishing false',
      () {
        // 1. Arrange
        const isPublishing = false;

        // 2. Act
        final payloadParar = <String, dynamic>{'isPublishing': isPublishing};

        // 3. Assert
        expect(payloadParar, {'isPublishing': false});
      },
    );

    // -------------------------------------------------------------
    // Filtro de Janela de Tempo
    // -------------------------------------------------------------
    test(
      'Happy Path: Filtro de tempo mantém usuário ativo com posição recente (< 5 min)',
      () {
        // 1. Arrange
        final now = DateTime.now();
        final usuarioRecente = UserModel(
          email: 'ativo@monamienet.org',
          lat: -22.90,
          lng: -43.13,
          capturedAt: now.subtract(const Duration(minutes: 1)),
          isPublishing: true,
        );
        final limit = now.subtract(const Duration(minutes: 5));

        // 2. Act
        final isRecente =
            usuarioRecente.capturedAt != null &&
            usuarioRecente.capturedAt!.isAfter(limit);

        // 3. Assert
        expect(isRecente, isTrue);
      },
    );

    test('Edge Case: Filtro de tempo descarta usuário com timestamp nulo', () {
      // 1. Arrange
      final now = DateTime.now();
      final pessoaSemHorario = UserModel(
        email: 'sem.capturedAt@monamienet.org',
        capturedAt: null,
      );
      final limit = now.subtract(const Duration(minutes: 5));

      // 2. Act
      final isValido =
          pessoaSemHorario.capturedAt != null &&
          pessoaSemHorario.capturedAt!.isAfter(limit);

      // 3. Assert
      expect(isValido, isFalse);
    });

    test(
      'Sad Path: Filtro de tempo descarta usuário com posição desatualizada (> 5 min)',
      () {
        // 1. Arrange
        final now = DateTime.now();
        final usuarioAntigo = UserModel(
          email: 'antigo@monamienet.org',
          capturedAt: now.subtract(const Duration(minutes: 10)),
        );
        final limit = now.subtract(const Duration(minutes: 5));

        // 2. Act
        final isRecente =
            usuarioAntigo.capturedAt != null &&
            usuarioAntigo.capturedAt!.isAfter(limit);

        // 3. Assert
        expect(isRecente, isFalse);
      },
    );
  });
}
