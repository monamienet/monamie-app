import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/domain/models/sharing_notification.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

/// What [StartSharing] did when it did not fail.
class SharingStart {
  /// Nothing started, and nothing more to say: the battery settings or the
  /// GPS warning were shown instead.
  const SharingStart.notStarted() : started = false, notice = null;

  /// The tracking service started; [notice], when set, is a remark to show
  /// (no GPS fix yet).
  const SharingStart.started({this.notice}) : started = true;

  final bool started;
  final UserNotice? notice;
}

/// Turns sharing on: the checks that cross the permissions, the GPS, the
/// person's memberships and the tracking service, in this order.
///
/// 1. With the battery mode "Restrito" Android drops the service's
///    foreground status as soon as the app leaves the screen: the battery
///    settings open instead.
/// 2. With the GPS off the person hears so, and nothing starts.
/// 3. The rules only accept positions from people who publish in a group
///    (the service publishes in every one of them): [Err] with
///    [SharingNotAllowed] otherwise.
/// 4. A first fix is asked for (5 s at most), so the map shows the person at
///    once; without one the service still starts, with a
///    [WaitingForGpsNotice].
/// 5. The tracking service starts, with its notification.
///
/// The caller (the sharing switch) guards against a second call while one
/// runs, follows the service's events and records that sharing is on.
class StartSharing {
  StartSharing({
    required this._permissions,
    required this._location,
    required this._memberships,
    required this._service,
  });

  final PermissionsRepository _permissions;
  final DeviceLocation _location;
  final MembershipRepository _memberships;
  final BackgroundTrackingService _service;

  /// Runs the checks and starts the service, which shows [notification]
  /// while it runs. [onPosition] gets the first fix, as soon as it arrives
  /// (before the service starts).
  Future<Result<SharingStart>> call({
    required void Function(LatLng position) onPosition,
    required SharingNotification notification,
  }) async {
    // No modo de bateria "Restrito" o Android remove o status de foreground
    // do serviço assim que o app sai da tela; não adianta iniciar.
    if (await _permissions.refreshBackgroundRestriction()) {
      await _permissions.openBackgroundUsageSettings();
      return const Ok(SharingStart.notStarted());
    }

    // Verifica se GPS está ativado.
    final gpsEnabled = await _location.isServiceEnabled();
    if (!gpsEnabled) {
      _permissions.notifyGpsDisabled();
      // Interrompe a execução para não iniciar o serviço sem GPS
      return const Ok(SharingStart.notStarted());
    }

    // The rules only accept positions from people who publish in a group;
    // the service publishes in every one of them.
    if (!_memberships.canPublish) {
      debugPrint('[StartSharing] The user publishes in no group.');
      return const Err(Failure.sharingNotAllowed());
    }

    // Tenta obter a posição GPS atual para sincronizar imediatamente
    UserNotice? notice;
    try {
      onPosition(
        await _location.currentPosition().timeout(const Duration(seconds: 5)),
      );
    } catch (e) {
      debugPrint('[StartSharing] Erro ao obter posição atual imediata: $e');
      // The service still starts: the person hears that the satellites
      // are still syncing.
      notice = const UserNotice.waitingForGps();
    }

    await _service.start(
      notificationTitle: notification.title,
      notificationContent: notification.content,
    );
    return Ok(SharingStart.started(notice: notice));
  }
}
