import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:monamie_app/data/services/foreground_service.dart';

/// The tracking service (`flutter_background_service`) as the UI isolate
/// sees it: start, stop and the events the service's own isolate
/// (`foreground_service.dart`) exchanges with the screen.
class BackgroundTrackingService {
  BackgroundTrackingService({required this._service});

  final FlutterBackgroundService _service;

  /// Whether the service is running.
  Future<bool> isRunning() => _service.isRunning();

  /// Configures the service (foreground mode on Android, never started by
  /// itself or on boot) with the notification shown while it runs, and
  /// starts it. The service's isolate begins in [onStart]; it announces
  /// itself on [ready].
  Future<bool> start({
    required String notificationTitle,
    required String notificationContent,
  }) async {
    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        // Esta linha conecta os isolates.
        onStart: onStart,
        // true -> Foreground
        // false -> Background
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: false,
        initialNotificationTitle: notificationTitle,
        initialNotificationContent: notificationContent,
      ),
    );
    return _service.startService();
  }

  /// Asks the service's isolate to stop (`stopService`). Unconfirmed: the
  /// event is lost when the isolate is not listening yet.
  void stop() => _service.invoke('stopService');

  /// Replaces the texts of the notification shown while the service runs
  /// (`setNotificationInfo`), for example after the app's language changed.
  /// The service's isolate applies them with
  /// `AndroidServiceInstance.setForegroundNotificationInfo`.
  void updateNotification({required String title, required String content}) =>
      _service.invoke('setNotificationInfo', {
        'title': title,
        'content': content,
      });

  /// Each time the service's isolate is ready to receive who shares
  /// ([sendUser]).
  Stream<void> get ready => _service.on('ready').map((_) {});

  /// Tells the service's isolate who shares (`setUserInfo`), which starts
  /// publishing their positions.
  void sendUser({required String email, required String name}) =>
      _service.invoke('setUserInfo', {'email': email, 'name': name});

  /// The device's positions as the service reads them
  /// (`updateLocationLocally`), published or not.
  Stream<LatLng> get localPositions => _service
      .on('updateLocationLocally')
      .where((event) => event != null)
      .map((event) {
        final position = Position.fromMap(event!['position']);
        return LatLng(position.latitude, position.longitude);
      });
}
