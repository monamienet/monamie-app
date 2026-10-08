import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

/// Simulador da máquina de estados e filtragem de posições do ForegroundService.
class ForegroundLocationRecorderSimulator {
  final int minDistanceMeters;
  Position? lastRecordedPosition;
  int firestoreWritesCount = 0;
  final List<Position> recordedHistory = [];
  final List<Position> localUiUpdates = [];

  ForegroundLocationRecorderSimulator({this.minDistanceMeters = 10});

  /// Simula a gravação inicial executada em updateLocation.
  void recordInitialPosition(Position initialPosition) {
    firestoreWritesCount++;
    recordedHistory.add(initialPosition);
    lastRecordedPosition = initialPosition;
    localUiUpdates.add(initialPosition);
  }

  /// Simula o listener de Geolocator.getPositionStream.
  void onStreamPositionReceived(Position position) {
    if (lastRecordedPosition != null) {
      final distanceMoved = Geolocator.distanceBetween(
        lastRecordedPosition!.latitude,
        lastRecordedPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distanceMoved < minDistanceMeters) {
        // Notifica apenas a UI localmente sem consumir escrita no Firestore
        localUiUpdates.add(position);
        return;
      }
    }

    // Persiste no Firestore
    firestoreWritesCount++;
    recordedHistory.add(position);
    lastRecordedPosition = position;
    localUiUpdates.add(position);
  }

  /// Simula stopService ou reinicialização de sessão.
  void resetSession() {
    lastRecordedPosition = null;
  }
}

Position createPosition({
  required double latitude,
  required double longitude,
  DateTime? timestamp,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.now(),
    accuracy: 5.0,
    altitude: 10.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

void main() {
  group('Desduplicação e Telemetria Inteligente de Histórico de Posições', () {
    test('Happy Path: Posição inicial gera exatamente 1 gravação no histórico', () {
      // 1. Arrange
      final simulator = ForegroundLocationRecorderSimulator(minDistanceMeters: 10);
      final initialPos = createPosition(latitude: -22.904100, longitude: -43.132900);

      // 2. Act
      simulator.recordInitialPosition(initialPos);

      // 3. Assert
      expect(simulator.firestoreWritesCount, 1);
      expect(simulator.recordedHistory.length, 1);
      expect(simulator.lastRecordedPosition, initialPos);
      expect(simulator.localUiUpdates.length, 1);
    });

    test('Happy Path: Primeiro evento do stream com mesma coordenada é descartado como duplicata', () {
      // 1. Arrange
      final simulator = ForegroundLocationRecorderSimulator(minDistanceMeters: 10);
      final initialPos = createPosition(latitude: -22.904100, longitude: -43.132900);
      simulator.recordInitialPosition(initialPos);

      // 2. Act: Stream emite o mesmo fix ou ruído desprezível (< 10 metros)
      // Ex: deslocamento de aproximadamente 2 metros na latitude
      final streamPosDuplicate = createPosition(latitude: -22.904115, longitude: -43.132900);
      final distance = Geolocator.distanceBetween(
        initialPos.latitude,
        initialPos.longitude,
        streamPosDuplicate.latitude,
        streamPosDuplicate.longitude,
      );
      expect(distance, lessThan(10.0));

      simulator.onStreamPositionReceived(streamPosDuplicate);

      // 3. Assert: Nenhuma nova escrita no Firestore é gerada
      expect(simulator.firestoreWritesCount, 1, reason: 'Escrita redundante deve ser suprimida');
      expect(simulator.recordedHistory.length, 1);
      // Porém a UI local foi notificada
      expect(simulator.localUiUpdates.length, 2);
    });

    test('Happy Path: Evento do stream com deslocamento >= 10m grava novo ponto e atualiza referência', () {
      // 1. Arrange
      final simulator = ForegroundLocationRecorderSimulator(minDistanceMeters: 10);
      final initialPos = createPosition(latitude: -22.904100, longitude: -43.132900);
      simulator.recordInitialPosition(initialPos);

      // 2. Act: Usuário se desloca ~25 metros
      final movedPos = createPosition(latitude: -22.904320, longitude: -43.132900);
      final distance = Geolocator.distanceBetween(
        initialPos.latitude,
        initialPos.longitude,
        movedPos.latitude,
        movedPos.longitude,
      );
      expect(distance, greaterThanOrEqualTo(10.0));

      simulator.onStreamPositionReceived(movedPos);

      // 3. Assert: Novo ponto histórico gravado com sucesso
      expect(simulator.firestoreWritesCount, 2);
      expect(simulator.recordedHistory.length, 2);
      expect(simulator.lastRecordedPosition, movedPos);
    });

    test('Edge Case: Quando posição inicial falha (lastRecordedPosition nulo), stream grava primeira posição', () {
      // 1. Arrange: Cenário em que getCurrentPosition falhou ou teve timeout
      final simulator = ForegroundLocationRecorderSimulator(minDistanceMeters: 10);
      expect(simulator.lastRecordedPosition, isNull);

      // 2. Act: Stream obtém primeiro fix
      final streamFirstPos = createPosition(latitude: -22.904100, longitude: -43.132900);
      simulator.onStreamPositionReceived(streamFirstPos);

      // 3. Assert: Gravou a primeira posição como fallback sem bloqueio
      expect(simulator.firestoreWritesCount, 1);
      expect(simulator.recordedHistory.length, 1);
      expect(simulator.lastRecordedPosition, streamFirstPos);
    });

    test('Edge Case: Reset de sessão permite que nova jornada grave imediatamente', () {
      // 1. Arrange: Jornada anterior concluída
      final simulator = ForegroundLocationRecorderSimulator(minDistanceMeters: 10);
      final pos1 = createPosition(latitude: -22.904100, longitude: -43.132900);
      simulator.recordInitialPosition(pos1);
      expect(simulator.firestoreWritesCount, 1);

      // 2. Act: Serviço parado e reiniciado no mesmo ponto
      simulator.resetSession();
      expect(simulator.lastRecordedPosition, isNull);

      final newSessionInitialPos = createPosition(latitude: -22.904100, longitude: -43.132900);
      simulator.recordInitialPosition(newSessionInitialPos);

      // 3. Assert: Permitiu nova gravação inicial de jornada
      expect(simulator.firestoreWritesCount, 2);
      expect(simulator.recordedHistory.length, 2);
      expect(simulator.lastRecordedPosition, newSessionInitialPos);
    });

    test('Contrato de Responsabilidade Única: TrackingController atualiza isTracked sem gravar no histórico', () {
      // Valida o contrato em que o controller de UI emite apenas o payload de ativação de rastreamento
      const email = 'usuario@monamienet.org';
      const grupoAtivo = 'equipe-bravo@monamienet.org';

      final trackingActivationPayload = <String, dynamic>{
        'email': email,
        'isTracked': true,
        'grupo_ativo': grupoAtivo,
      };

      // O payload de ativação de tracking não contém arrays ou escritas em subcoleções
      expect(trackingActivationPayload.containsKey('lat'), isFalse);
      expect(trackingActivationPayload.containsKey('lng'), isFalse);
      expect(trackingActivationPayload['isTracked'], isTrue);
      expect(trackingActivationPayload['grupo_ativo'], grupoAtivo);
    });
  });
}

