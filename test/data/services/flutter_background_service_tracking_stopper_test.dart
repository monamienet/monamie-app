import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/data/services/flutter_background_service_tracking_stopper.dart';

@GenerateNiceMocks([
  MockSpec<BackgroundTrackingService>(),
  MockSpec<PositionsRepository>(),
])
import 'flutter_background_service_tracking_stopper_test.mocks.dart';

/// Tempos curtos para manter a suíte rápida. Os testes usam tempo real
/// porque o `Stopwatch` do stopper não é controlado por relógios falsos.
const Duration _kTimeout = Duration(milliseconds: 200);
const Duration _kPollInterval = Duration(milliseconds: 10);

/// Limite generoso para considerar que `stop` "não travou": bem acima do
/// pior caso esperado (espera pela parada + espera por `markNotPublishing`),
/// mas finito.
const Duration _kHangGuard = Duration(seconds: 3);

const String _kEmail = 'ana.souza@monamie.net';

/// Sentinela devolvida quando `stop` não conclui dentro de [_kHangGuard].
const Object _kDidNotComplete = 'stop-nao-concluiu';

/// Mock do `BackgroundTrackingService` cujo `isRunning()` segue um estado
/// guardado aqui e que para depois de [stopAfterInvokes] pedidos `stop()`
/// (o evento `stopService`) recebidos (`null` = nunca para).
///
/// [isRunningError] é lançado por toda chamada a `isRunning()` (plugin
/// indisponível). Com [throwOnIsRunningAfterInvoke], `isRunning()` passa a
/// lançar depois do primeiro `stopService` recebido.
MockBackgroundTrackingService _mockService({
  bool running = false,
  int? stopAfterInvokes = 1,
  Object? isRunningError,
  bool throwOnIsRunningAfterInvoke = false,
}) {
  final service = MockBackgroundTrackingService();
  var stopServiceInvocations = 0;
  when(service.isRunning()).thenAnswer((_) async {
    if (isRunningError != null) throw isRunningError;
    if (throwOnIsRunningAfterInvoke && stopServiceInvocations > 0) {
      throw StateError('canal do plugin indisponível');
    }
    return running;
  });
  when(service.stop()).thenAnswer((_) {
    stopServiceInvocations++;
    final threshold = stopAfterInvokes;
    if (threshold != null && stopServiceInvocations >= threshold) {
      running = false;
    }
  });
  return service;
}

/// Quantas vezes `stop()` (o evento `stopService`) foi enviado a
/// [service]; falha se não houve nenhuma.
int _stopRequests(MockBackgroundTrackingService service) =>
    verify(service.stop()).callCount;

/// Registro das chamadas a `PositionsRepository.markNotPublishing`, com
/// comportamento configurável (sucesso, erro ou nunca completar).
class _MarkNotPublishingSpy {
  _MarkNotPublishingSpy({this.error, this.neverCompletes = false});

  final Object? error;
  final bool neverCompletes;
  final List<String> emails = <String>[];

  Future<void> call(String email) {
    emails.add(email);
    if (neverCompletes) return Completer<void>().future;
    final failure = error;
    if (failure != null) return Future<void>.error(failure);
    return Future<void>.value();
  }
}

FlutterBackgroundServiceTrackingStopper _buildStopper(
  MockBackgroundTrackingService service,
  _MarkNotPublishingSpy markNotPublishing,
) {
  final positions = MockPositionsRepository();
  when(positions.markNotPublishing(any)).thenAnswer(
    (invocation) =>
        markNotPublishing(invocation.positionalArguments[0] as String),
  );
  return FlutterBackgroundServiceTrackingStopper(
    service: service,
    positions: positions,
    timeout: _kTimeout,
    pollInterval: _kPollInterval,
  );
}

/// Executa `stop` limitando a espera a [_kHangGuard]. Devolve o `bool` de
/// `stop` ou [_kDidNotComplete] se ele não concluir a tempo.
Future<Object?> _stopWithinGuard(
  BackgroundTrackingStopper stopper, {
  String? email,
}) {
  return stopper
      .stop(email: email)
      .then<Object?>((stopped) => stopped)
      .timeout(_kHangGuard, onTimeout: () => _kDidNotComplete);
}

void main() {
  group('FlutterBackgroundServiceTrackingStopper - Suíte de Testes Unitários', () {
    // ---------------------------------------------------------------------
    // Happy Path
    // ---------------------------------------------------------------------
    test(
      'Happy Path: Deve retornar true quando o serviço em execução parar após o stopService',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        final stopped = await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(stopped, isTrue);
      },
    );

    test(
      'Happy Path: Deve enviar o evento stopService quando o serviço estiver em execução',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(_stopRequests(service), greaterThan(0));
      },
    );

    test(
      'Happy Path: Deve chamar markNotPublishing uma única vez com o e-mail informado quando o serviço estava em execução',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markNotPublishing = _MarkNotPublishingSpy();
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(markNotPublishing.emails, [_kEmail]);
      },
    );

    test(
      'Happy Path: Deve consultar isRunning novamente até confirmar que o serviço parou',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        await stopper.stop();

        // 3. Assert
        // Uma consulta inicial + ao menos uma consulta de confirmação.
        expect(verify(service.isRunning()).callCount, greaterThanOrEqualTo(2));
      },
    );

    // ---------------------------------------------------------------------
    // Edge Case
    // ---------------------------------------------------------------------
    test(
      'Edge Case: Deve retornar true imediatamente quando o serviço não estiver em execução',
      () async {
        // 1. Arrange
        final service = _mockService(running: false);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        final stopped = await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(stopped, isTrue);
      },
    );

    test(
      'Edge Case: Não deve enviar stopService quando o serviço não estiver em execução',
      () async {
        // 1. Arrange
        final service = _mockService(running: false);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        verifyNever(service.stop());
      },
    );

    test(
      'Edge Case: Não deve chamar markNotPublishing quando o serviço não estiver em execução, mesmo com e-mail',
      () async {
        // 1. Arrange
        final service = _mockService(running: false);
        final markNotPublishing = _MarkNotPublishingSpy();
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(markNotPublishing.emails, isEmpty);
      },
    );

    test(
      'Edge Case: Deve retornar true quando o serviço ignorar o primeiro stopService e parar apenas em um reenvio',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: 3);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        final stopped = await stopper.stop();

        // 3. Assert
        expect(stopped, isTrue);
      },
    );

    test(
      'Edge Case: Deve reenviar stopService enquanto o serviço continuar em execução',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: 3);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        await stopper.stop();

        // 3. Assert
        expect(_stopRequests(service), greaterThanOrEqualTo(3));
      },
    );

    test(
      'Edge Case: Não deve chamar markNotPublishing quando o e-mail for nulo',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markNotPublishing = _MarkNotPublishingSpy();
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        await stopper.stop(email: null);

        // 3. Assert
        expect(markNotPublishing.emails, isEmpty);
      },
    );

    test(
      'Edge Case: Não deve chamar markNotPublishing quando o e-mail for uma string vazia',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markNotPublishing = _MarkNotPublishingSpy();
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        await stopper.stop(email: '');

        // 3. Assert
        expect(markNotPublishing.emails, isEmpty);
      },
    );

    test(
      'Edge Case: Deve chamar markNotPublishing uma única vez mesmo quando a parada do serviço expirar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: null);
        final markNotPublishing = _MarkNotPublishingSpy();
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(markNotPublishing.emails, [_kEmail]);
      },
    );

    test(
      'Edge Case: Deve tratar isRunning lançando durante a confirmação como serviço parado e retornar true',
      () async {
        // 1. Arrange
        final service = _mockService(
          running: true,
          stopAfterInvokes: null,
          throwOnIsRunningAfterInvoke: true,
        );
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        final outcome = await _stopWithinGuard(stopper);

        // 3. Assert
        expect(outcome, isTrue);
      },
    );

    // ---------------------------------------------------------------------
    // Sad Path
    // ---------------------------------------------------------------------
    test(
      'Sad Path: Deve retornar false quando o serviço nunca parar dentro do timeout',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: null);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        final outcome = await _stopWithinGuard(stopper);

        // 3. Assert
        expect(outcome, isFalse);
      },
    );

    test(
      'Sad Path: Deve concluir em tempo limitado quando o serviço nunca parar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: null);
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());
        final stopwatch = Stopwatch();

        // 2. Act
        stopwatch.start();
        final outcome = await _stopWithinGuard(stopper);
        stopwatch.stop();

        // 3. Assert
        expect(outcome, isNot(_kDidNotComplete));
        expect(stopwatch.elapsed, greaterThanOrEqualTo(_kTimeout));
        expect(stopwatch.elapsed, lessThan(_kTimeout * 3));
      },
    );

    test(
      'Sad Path: Não deve lançar e deve retornar true quando markNotPublishing lançar após o serviço parar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markNotPublishing = _MarkNotPublishingSpy(
          error: StateError('Firestore recusou a escrita'),
        );
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        final outcome = await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        expect(outcome, isTrue);
      },
    );

    test(
      'Sad Path: Não deve lançar e deve retornar false quando markNotPublishing lançar e o serviço não parar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: null);
        final markNotPublishing = _MarkNotPublishingSpy(
          error: StateError('Firestore recusou a escrita'),
        );
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        final outcome = await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        expect(outcome, isFalse);
      },
    );

    test(
      'Sad Path: Deve retornar true sem travar quando markNotPublishing nunca completar (aparelho offline)',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markNotPublishing = _MarkNotPublishingSpy(neverCompletes: true);
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        final outcome = await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        expect(outcome, isTrue);
      },
    );

    test(
      'Sad Path: Deve limitar a espera por markNotPublishing ao timeout quando ele nunca completar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markNotPublishing = _MarkNotPublishingSpy(neverCompletes: true);
        final stopper = _buildStopper(service, markNotPublishing);
        final stopwatch = Stopwatch();

        // 2. Act
        stopwatch.start();
        await _stopWithinGuard(stopper, email: _kEmail);
        stopwatch.stop();

        // 3. Assert
        // O serviço para no primeiro ciclo; a espera restante é a de
        // markNotPublishing, que deve ser cortada pelo timeout.
        expect(stopwatch.elapsed, lessThan(_kTimeout * 2));
      },
    );

    test(
      'Sad Path: Deve tratar isRunning lançando (plugin indisponível) como serviço parado e retornar true',
      () async {
        // 1. Arrange
        final service = _mockService(
          running: true,
          isRunningError: MissingPluginException('isServiceRunning'),
        );
        final stopper = _buildStopper(service, _MarkNotPublishingSpy());

        // 2. Act
        final outcome = await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        expect(outcome, isTrue);
      },
    );

    test(
      'Sad Path: Não deve enviar stopService nem chamar markNotPublishing quando isRunning lançar',
      () async {
        // 1. Arrange
        final service = _mockService(
          running: true,
          isRunningError: MissingPluginException('isServiceRunning'),
        );
        final markNotPublishing = _MarkNotPublishingSpy();
        final stopper = _buildStopper(service, markNotPublishing);

        // 2. Act
        await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        verifyNever(service.stop());
        expect(markNotPublishing.emails, isEmpty);
      },
    );
  });
}
