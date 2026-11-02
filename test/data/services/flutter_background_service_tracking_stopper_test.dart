import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/data/services/flutter_background_service_tracking_stopper.dart';

@GenerateNiceMocks([MockSpec<FlutterBackgroundService>()])
import 'flutter_background_service_tracking_stopper_test.mocks.dart';

/// Tempos curtos para manter a suíte rápida. Os testes usam tempo real
/// porque o `Stopwatch` do stopper não é controlado por relógios falsos.
const Duration _kTimeout = Duration(milliseconds: 200);
const Duration _kPollInterval = Duration(milliseconds: 10);

/// Limite generoso para considerar que `stop` "não travou": bem acima do
/// pior caso esperado (espera pela parada + espera por `markUntracked`),
/// mas finito.
const Duration _kHangGuard = Duration(seconds: 3);

const String _kEmail = 'ana.souza@monamie.net';

/// Sentinela devolvida quando `stop` não conclui dentro de [_kHangGuard].
const Object _kDidNotComplete = 'stop-nao-concluiu';

/// Mock do `FlutterBackgroundService` cujo `isRunning()` segue um estado
/// guardado aqui e que para depois de [stopAfterInvokes] eventos
/// `stopService` recebidos via `invoke` (`null` = nunca para).
///
/// [isRunningError] é lançado por toda chamada a `isRunning()` (plugin
/// indisponível). Com [throwOnIsRunningAfterInvoke], `isRunning()` passa a
/// lançar depois do primeiro `stopService` recebido.
MockFlutterBackgroundService _mockService({
  bool running = false,
  int? stopAfterInvokes = 1,
  Object? isRunningError,
  bool throwOnIsRunningAfterInvoke = false,
}) {
  final service = MockFlutterBackgroundService();
  var stopServiceInvocations = 0;
  when(service.isRunning()).thenAnswer((_) async {
    if (isRunningError != null) throw isRunningError;
    if (throwOnIsRunningAfterInvoke && stopServiceInvocations > 0) {
      throw StateError('canal do plugin indisponível');
    }
    return running;
  });
  when(service.invoke(any, any)).thenAnswer((invocation) {
    if (invocation.positionalArguments[0] != 'stopService') return;
    stopServiceInvocations++;
    final threshold = stopAfterInvokes;
    if (threshold != null && stopServiceInvocations >= threshold) {
      running = false;
    }
  });
  return service;
}

/// Os métodos enviados a [service] via `invoke`, em ordem; falha se não
/// houve nenhum.
List<Object?> _invokedMethods(MockFlutterBackgroundService service) =>
    verify(service.invoke(captureAny, any)).captured;

/// Registro das chamadas ao callback `markUntracked`, com comportamento
/// configurável (sucesso, erro ou nunca completar).
class _MarkUntrackedSpy {
  _MarkUntrackedSpy({this.error, this.neverCompletes = false});

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
  MockFlutterBackgroundService service,
  _MarkUntrackedSpy markUntracked,
) {
  return FlutterBackgroundServiceTrackingStopper(
    service: service,
    markUntracked: markUntracked.call,
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
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

        // 2. Act
        final stopped = await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(stopped, isTrue);
      },
    );

    test(
      'Happy Path: Deve enviar o evento stopService via invoke quando o serviço estiver em execução',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        final invoked = _invokedMethods(service);
        expect(invoked, isNotEmpty);
        expect(invoked, everyElement('stopService'));
      },
    );

    test(
      'Happy Path: Deve chamar markUntracked uma única vez com o e-mail informado quando o serviço estava em execução',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markUntracked = _MarkUntrackedSpy();
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(markUntracked.emails, [_kEmail]);
      },
    );

    test(
      'Happy Path: Deve consultar isRunning novamente até confirmar que o serviço parou',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

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
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

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
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        verifyNever(service.invoke(any, any));
      },
    );

    test(
      'Edge Case: Não deve chamar markUntracked quando o serviço não estiver em execução, mesmo com e-mail',
      () async {
        // 1. Arrange
        final service = _mockService(running: false);
        final markUntracked = _MarkUntrackedSpy();
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(markUntracked.emails, isEmpty);
      },
    );

    test(
      'Edge Case: Deve retornar true quando o serviço ignorar o primeiro stopService e parar apenas em um reenvio',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: 3);
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

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
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

        // 2. Act
        await stopper.stop();

        // 3. Assert
        expect(
          _invokedMethods(service).where((m) => m == 'stopService'),
          hasLength(greaterThanOrEqualTo(3)),
        );
      },
    );

    test(
      'Edge Case: Não deve chamar markUntracked quando o e-mail for nulo',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markUntracked = _MarkUntrackedSpy();
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        await stopper.stop(email: null);

        // 3. Assert
        expect(markUntracked.emails, isEmpty);
      },
    );

    test(
      'Edge Case: Não deve chamar markUntracked quando o e-mail for uma string vazia',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markUntracked = _MarkUntrackedSpy();
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        await stopper.stop(email: '');

        // 3. Assert
        expect(markUntracked.emails, isEmpty);
      },
    );

    test(
      'Edge Case: Deve chamar markUntracked uma única vez mesmo quando a parada do serviço expirar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: null);
        final markUntracked = _MarkUntrackedSpy();
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        await stopper.stop(email: _kEmail);

        // 3. Assert
        expect(markUntracked.emails, [_kEmail]);
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
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

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
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

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
        final stopper = _buildStopper(service, _MarkUntrackedSpy());
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
      'Sad Path: Não deve lançar e deve retornar true quando markUntracked lançar após o serviço parar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markUntracked = _MarkUntrackedSpy(
          error: StateError('Firestore recusou a escrita'),
        );
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        final outcome = await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        expect(outcome, isTrue);
      },
    );

    test(
      'Sad Path: Não deve lançar e deve retornar false quando markUntracked lançar e o serviço não parar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true, stopAfterInvokes: null);
        final markUntracked = _MarkUntrackedSpy(
          error: StateError('Firestore recusou a escrita'),
        );
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        final outcome = await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        expect(outcome, isFalse);
      },
    );

    test(
      'Sad Path: Deve retornar true sem travar quando markUntracked nunca completar (aparelho offline)',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markUntracked = _MarkUntrackedSpy(neverCompletes: true);
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        final outcome = await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        expect(outcome, isTrue);
      },
    );

    test(
      'Sad Path: Deve limitar a espera por markUntracked ao timeout quando ele nunca completar',
      () async {
        // 1. Arrange
        final service = _mockService(running: true);
        final markUntracked = _MarkUntrackedSpy(neverCompletes: true);
        final stopper = _buildStopper(service, markUntracked);
        final stopwatch = Stopwatch();

        // 2. Act
        stopwatch.start();
        await _stopWithinGuard(stopper, email: _kEmail);
        stopwatch.stop();

        // 3. Assert
        // O serviço para no primeiro ciclo; a espera restante é a de
        // markUntracked, que deve ser cortada pelo timeout.
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
        final stopper = _buildStopper(service, _MarkUntrackedSpy());

        // 2. Act
        final outcome = await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        expect(outcome, isTrue);
      },
    );

    test(
      'Sad Path: Não deve enviar stopService nem chamar markUntracked quando isRunning lançar',
      () async {
        // 1. Arrange
        final service = _mockService(
          running: true,
          isRunningError: MissingPluginException('isServiceRunning'),
        );
        final markUntracked = _MarkUntrackedSpy();
        final stopper = _buildStopper(service, markUntracked);

        // 2. Act
        await _stopWithinGuard(stopper, email: _kEmail);

        // 3. Assert
        verifyNever(service.invoke(any, any));
        expect(markUntracked.emails, isEmpty);
      },
    );
  });
}
