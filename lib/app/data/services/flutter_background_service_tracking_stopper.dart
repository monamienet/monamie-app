import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';

/// Para o serviço do `flutter_background_service` enviando o evento
/// `stopService` ao isolate de rastreamento (ver `foreground_service.dart`).
///
/// O envio não tem confirmação: se o isolate ainda não registrou o listener,
/// o evento é descartado em silêncio. Por isso ele é reenviado a cada
/// [pollInterval] até `isRunning()` retornar `false` ou o [timeout] expirar.
class FlutterBackgroundServiceTrackingStopper
    implements BackgroundTrackingStopper {
  FlutterBackgroundServiceTrackingStopper({
    FlutterBackgroundService? service,
    Future<void> Function(String email)? markUntracked,
    this.timeout = const Duration(seconds: 5),
    this.pollInterval = const Duration(milliseconds: 250),
  }) : _injectedService = service,
       _markUntracked =
           markUntracked ??
           ((email) => FirebaseProvider().markNotPublishing(email));

  final FlutterBackgroundService? _injectedService;
  final Future<void> Function(String email) _markUntracked;

  /// Tempo máximo de espera pela parada do serviço e, separadamente, pela
  /// escrita de `isPublishing` (que nunca completa enquanto o aparelho está
  /// offline).
  final Duration timeout;
  final Duration pollInterval;

  FlutterBackgroundService get _service =>
      _injectedService ?? FlutterBackgroundService();

  @override
  Future<bool> stop({String? email}) async {
    if (!await _isRunning()) return true;

    final stopwatch = Stopwatch()..start();
    var stopped = false;
    while (!stopped && stopwatch.elapsed < timeout) {
      _service.invoke('stopService');
      await Future<void>.delayed(pollInterval);
      stopped = !await _isRunning();
    }

    if (!stopped) {
      debugPrint(
        '[BackgroundTrackingStopper] O serviço não parou em '
        '${timeout.inMilliseconds} ms.',
      );
    }

    if (email != null && email.isNotEmpty) {
      try {
        await _markUntracked(email).timeout(timeout);
      } catch (e) {
        debugPrint(
          '[BackgroundTrackingStopper] Erro ao desativar isPublishing: $e',
        );
      }
    }

    return stopped;
  }

  Future<bool> _isRunning() async {
    try {
      return await _service.isRunning();
    } catch (e) {
      // Plataformas sem o plugin (ex.: web) não têm serviço a parar.
      debugPrint('[BackgroundTrackingStopper] isRunning indisponível: $e');
      return false;
    }
  }
}
