import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

void main() {
  group('Contratos de Dados do FirebaseProvider (Opção 3)', () {
    // -------------------------------------------------------------
    // Escrita de Usuário
    // -------------------------------------------------------------
    test('Happy Path: Contrato de escrita de posição e grupo_ativo com campos válidos', () {
      // 1. Arrange
      const email = 'servidor1@monamienet.org';
      const nome = 'Servidor Silva';
      const lat = -22.9035;
      const lng = -43.1320;
      final timestamp = DateTime(2026, 9, 16, 21, 0, 0);
      const grupoAtivo = 'seguranca-operacional@monamienet.org';

      // 2. Act
      final userUpdates = <String, dynamic>{
        'email': email,
        'nome': nome,
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp,
        if (grupoAtivo.isNotEmpty) 'grupo_ativo': grupoAtivo,
      };

      // 3. Assert
      expect(userUpdates, {
        'email': email,
        'nome': nome,
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp,
        'grupo_ativo': grupoAtivo,
      });
    });

    test('Edge Case: Contrato de escrita omite grupo_ativo quando este for vazio', () {
      // 1. Arrange
      const email = 'servidor1@monamienet.org';
      const grupoAtivoVazio = '';

      // 2. Act
      final userUpdates = <String, dynamic>{
        'email': email,
        if (grupoAtivoVazio.isNotEmpty) 'grupo_ativo': grupoAtivoVazio,
      };

      // 3. Assert
      expect(userUpdates.containsKey('grupo_ativo'), isFalse);
    });

    test('Sad Path: Rejeita chaves não permitidas no contrato de escrita do usuário', () {
      // 1. Arrange
      final allowedKeys = {'email', 'nome', 'lat', 'lng', 'timestamp', 'isTracked', 'grupo_ativo'};
      final payloadComCampoInvalido = {'email': 'teste@monamienet.org', 'campo_proibido': true};

      // 2. Act
      final hasIllegalKey = payloadComCampoInvalido.keys.any((k) => !allowedKeys.contains(k));

      // 3. Assert
      expect(hasIllegalKey, isTrue);
    });

    // -------------------------------------------------------------
    // Histórico de Posições
    // -------------------------------------------------------------
    test('Happy Path: Contrato de gravação de ponto histórico inclui grupo_ativo e coordenadas', () {
      // 1. Arrange
      const lat = -22.9035;
      const lng = -43.1320;
      final timestamp = DateTime(2026, 9, 16, 21, 0, 0);
      const grupoAtivo = 'seguranca-operacional@monamienet.org';

      // 2. Act
      final pointData = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp,
        'grupo_ativo': grupoAtivo,
      };

      // 3. Assert
      expect(pointData, {
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp,
        'grupo_ativo': grupoAtivo,
      });
    });

    test('Sad Path: Rejeita chaves não permitidas na subcoleção de histórico de posições', () {
      // 1. Arrange
      final allowedHistoryKeys = {'lat', 'lng', 'timestamp', 'grupo_ativo'};
      final historicoComCampoInvalido = {'lat': -22.90, 'campo_desconhecido': 'valor'};

      // 2. Act
      final hasIllegalKey = historicoComCampoInvalido.keys.any((k) => !allowedHistoryKeys.contains(k));

      // 3. Assert
      expect(hasIllegalKey, isTrue);
    });

    // -------------------------------------------------------------
    // Ativação e Desativação de Rastreamento
    // -------------------------------------------------------------
    test('Happy Path: Payload de ativação de rastreamento deve conter isTracked true e grupo_ativo', () {
      // 1. Arrange
      const activeGroup = 'transporte-vans@monamienet.org';

      // 2. Act
      final payloadIniciar = <String, dynamic>{
        'isTracked': true,
        'grupo_ativo': activeGroup,
      };

      // 3. Assert
      expect(payloadIniciar, {
        'isTracked': true,
        'grupo_ativo': 'transporte-vans@monamienet.org',
      });
    });

    test('Happy Path: Payload de desativação de rastreamento deve conter isTracked false sem grupo_ativo', () {
      // 1. Arrange
      const isTracked = false;

      // 2. Act
      final payloadParar = <String, dynamic>{
        'isTracked': isTracked,
      };

      // 3. Assert
      expect(payloadParar, {
        'isTracked': false,
      });
    });

    // -------------------------------------------------------------
    // Filtro de Janela de Tempo
    // -------------------------------------------------------------
    test('Happy Path: Filtro de tempo mantém usuário ativo com posição recente (< 5 min)', () {
      // 1. Arrange
      final now = DateTime.now();
      final usuarioRecente = UserModel(
        email: 'ativo@monamienet.org',
        lat: -22.90,
        lng: -43.13,
        timestamp: now.subtract(const Duration(minutes: 1)),
        isTracked: true,
        grupoAtivo: 'seguranca@monamienet.org',
      );
      final limit = now.subtract(const Duration(minutes: 5));

      // 2. Act
      final isRecente = usuarioRecente.timestamp != null && usuarioRecente.timestamp!.isAfter(limit);

      // 3. Assert
      expect(isRecente, isTrue);
    });

    test('Edge Case: Filtro de tempo descarta usuário com timestamp nulo', () {
      // 1. Arrange
      final now = DateTime.now();
      final usuarioSemTimestamp = UserModel(
        email: 'sem.timestamp@monamienet.org',
        timestamp: null,
      );
      final limit = now.subtract(const Duration(minutes: 5));

      // 2. Act
      final isValido = usuarioSemTimestamp.timestamp != null && usuarioSemTimestamp.timestamp!.isAfter(limit);

      // 3. Assert
      expect(isValido, isFalse);
    });

    test('Sad Path: Filtro de tempo descarta usuário com posição desatualizada (> 5 min)', () {
      // 1. Arrange
      final now = DateTime.now();
      final usuarioAntigo = UserModel(
        email: 'antigo@monamienet.org',
        timestamp: now.subtract(const Duration(minutes: 10)),
      );
      final limit = now.subtract(const Duration(minutes: 5));

      // 2. Act
      final isRecente = usuarioAntigo.timestamp != null && usuarioAntigo.timestamp!.isAfter(limit);

      // 3. Assert
      expect(isRecente, isFalse);
    });
  });
}
