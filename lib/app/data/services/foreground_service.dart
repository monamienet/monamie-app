import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/groups/firestore_membership_source.dart';
import 'package:monamie_app/app/data/organization/organization_session.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/data/tracking/firestore_tracking_settings_repository.dart';
import 'package:monamie_app/app/data/tracking/group_publisher.dart';
import 'package:monamie_app/app/data/tracking/sharing_times.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

Timer? _heartbeatTimer;
StreamSubscription<Position>? _positionSubscription;
StreamSubscription<User?>? _authSubscription;

/// The administrators' tracking settings (`config/tracking`), applied to the
/// position stream; a change restarts the stream with the new values.
TrackingSettings _settings = TrackingSettings.defaults;
StreamSubscription<TrackingSettings>? _settingsSubscription;
Position? _lastRecordedPosition;

/// The groups where the person is a `publisher`, followed live from their
/// own `groupMemberships` (this isolate cannot ask the screen): every
/// position goes to all of them, one batch per group.
List<String> _publisherGroupIds = const [];
StreamSubscription<Map<String, Object?>>? _membershipSubscription;

/// The plan's minimum period (*período mínimo*: the least time between two
/// positions, Community), read from
/// `organizations/{id}/config/plan` at start. The rules refuse a sooner write.
Duration _minPeriod = Duration.zero;
DateTime? _lastPositionWriteAt;

/// Reads the plan's minimum period; none when the document is missing
/// (Standard) or cannot be read.
Future<Duration> _readMinPeriod() async {
  try {
    final plan = await CurrentOrganizationFirebase.instance.organizationData
        .collection(FirestorePaths.config)
        .doc(FirestorePaths.plan)
        .get()
        .timeout(const Duration(seconds: 5));
    final minutes = plan.data()?['minIntervalMinutes'];
    return minutes is int && minutes > 0
        ? Duration(minutes: minutes)
        : Duration.zero;
  } catch (e) {
    debugPrint('[ForegroundService] Could not read the plan: $e');
    return Duration.zero;
  }
}

/// Whether enough time passed since the last position write, with a few
/// seconds of slack for the difference between device and server clocks.
bool _minPeriodElapsed(DateTime now) {
  final last = _lastPositionWriteAt;
  if (last == null || _minPeriod == Duration.zero) return true;
  return now.difference(last) >= _minPeriod + const Duration(seconds: 10);
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // [DEFAULT] is the central project (from google-services.json); the
  // organization's app was created natively by MonAmieApplication.
  await Firebase.initializeApp();
  // The UI stored the bound organization; without one there is nowhere to write.
  if (await OrganizationSession().restore() == null) {
    debugPrint(
      '[ForegroundService] No organization bound — stopping the service.',
    );
    service.stopSelf();
    return;
  }

  // On Android, Firebase Auth keeps its credentials natively, shared by the
  // Flutter engines of the process, so the person signed in on the screen
  // is signed in here too.
  final currentUser = CurrentOrganizationFirebase.instance.auth.currentUser;
  if (currentUser != null) {
    debugPrint(
      '[ForegroundService] Auth disponível no background: '
      '${currentUser.email}',
    );
  } else {
    debugPrint(
      '[ForegroundService] AVISO: currentUser é nulo no background isolate. '
      'Escritas no Firestore podem falhar com PERMISSION_DENIED.',
    );
  }

  // Rede de segurança do logout: o app para o serviço antes do signOut, mas se
  // a parada não for confirmada a tempo o próprio isolate se encerra ao ver o
  // usuário sair. O FirebaseAuth nativo é compartilhado entre as engines do
  // processo, então o signOut do app chega aqui. Só a transição de logado
  // para deslogado dispara a parada; um usuário nulo na partida não muda o
  // comportamento anterior.
  var hadUser = currentUser != null;
  await _authSubscription?.cancel();
  _authSubscription = CurrentOrganizationFirebase.instance.auth
      .authStateChanges()
      .listen((user) {
        if (user != null) {
          hadUser = true;
        } else if (hadUser) {
          debugPrint(
            '[ForegroundService] Usuário deslogado — encerrando serviço.',
          );
          _stopTracking(service);
        }
      });

  service.on('stopService').listen((event) {
    _stopTracking(service);
  });

  service.on('setUserInfo').listen((event) async {
    if (event != null) {
      await updateLocation(service, event['email'], event['name']);
    }
  });

  service.invoke('ready');
}

void _stopTracking(ServiceInstance service) {
  _authSubscription?.cancel();
  _authSubscription = null;
  _settingsSubscription?.cancel();
  _settingsSubscription = null;
  _membershipSubscription?.cancel();
  _membershipSubscription = null;
  _publisherGroupIds = const [];
  _heartbeatTimer?.cancel();
  _heartbeatTimer = null;
  _positionSubscription?.cancel();
  _positionSubscription = null;
  _lastRecordedPosition = null;
  service.stopSelf();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Rounds in a row where every group refused the position for lack of
/// permission; past the limit the service stops trying until the person's
/// groups change.
int _consecutivePermissionErrors = 0;
const int _maxConsecutivePermissionErrors = 3;

/// Follows the person's publisher groups; completes once the first answer
/// arrives (or after a few seconds without one).
Future<void> _followPublisherGroups(String email) async {
  if (_membershipSubscription != null) return;
  final first = Completer<void>();
  _membershipSubscription = const FirestoreMembershipSource()
      .groupRoles(
        CurrentOrganizationFirebase.instance.organizationData.id,
        email,
      )
      .listen(
        (roles) {
          _publisherGroupIds = groupsWithRole(roles, GroupRoles.publisher);
          // New groups deserve new attempts.
          _consecutivePermissionErrors = 0;
          debugPrint('[ForegroundService] Publishing in: $_publisherGroupIds');
          if (!first.isCompleted) first.complete();
        },
        onError: (Object e) {
          debugPrint('[ForegroundService] Could not read the groups: $e');
          if (!first.isCompleted) first.complete();
        },
      );
  await first.future.timeout(const Duration(seconds: 5), onTimeout: () {});
}

/// Publishes [position] in every publisher group; returns whether some group
/// took it.
Future<bool> _publish(String email, String name, Position position) async {
  final published = PublishedPosition(
    email: email,
    name: name,
    lat: position.latitude,
    lng: position.longitude,
    capturedAt: DateTime.now(),
  );
  final writer = FirebaseProvider();
  final outcome = await publishToGroups(
    _publisherGroupIds,
    (groupId) => writer.publish(groupId, published),
  );
  for (final MapEntry(:key, :value) in outcome.failed.entries) {
    debugPrint('[ForegroundService] Not published in $key: $value');
  }
  if (!outcome.noneSucceeded) {
    _consecutivePermissionErrors = 0;
    return true;
  }
  if (outcome.anyPermissionDenied) {
    _consecutivePermissionErrors++;
    debugPrint(
      '[ForegroundService] PERMISSION_DENIED em todos os grupos '
      '(tentativa $_consecutivePermissionErrors/$_maxConsecutivePermissionErrors).',
    );
  }
  return false;
}

Future<void> updateLocation(
  ServiceInstance service,
  String email,
  String name,
) async {
  _lastRecordedPosition = null;

  // Follow the administrators' settings: the first value applies now, later ones
  // restart this function with the new period and radius.
  if (_settingsSubscription == null) {
    final first = Completer<void>();
    _settingsSubscription = const FirestoreTrackingSettingsRepository()
        .watch()
        .listen(
          (settings) {
            final changed = first.isCompleted && settings != _settings;
            _settings = settings;
            if (!first.isCompleted) first.complete();
            if (changed) {
              debugPrint(
                '[ForegroundService] New settings: every '
                '${settings.periodMinutes} min, ${settings.radiusMeters} m.',
              );
              updateLocation(service, email, name);
            }
          },
          onError: (Object e) {
            debugPrint('[ForegroundService] Could not read the settings: $e');
            if (!first.isCompleted) first.complete();
          },
        );
    await first.future.timeout(const Duration(seconds: 5), onTimeout: () {});
  }
  await _followPublisherGroups(email);

  // Sharing is on in every group, even before a new position is accepted
  // (the plan's interval may hold it back). A group where the person never
  // published has no position to update yet: the first publish creates it.
  await publishToGroups(
    _publisherGroupIds,
    (groupId) => FirebaseProvider().setPublishing(groupId, email, true),
  );

  final period = _settings.periodMinutes;
  final radius = _settings.radiusMeters;

  // Configuração do GPS
  late LocationSettings locationSettings;

  if (Platform.isAndroid) {
    locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high, // TODO: testar outros valores aqui
      distanceFilter: radius,
      intervalDuration: Duration(minutes: period),
    );
  } else if (Platform.isIOS) {
    locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.other,
      distanceFilter: radius,
      pauseLocationUpdatesAutomatically: true,
      showBackgroundLocationIndicator: true,
    );
  } else {
    locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: radius,
    );
  }

  _heartbeatTimer?.cancel();
  _heartbeatTimer = Timer.periodic(heartbeat, (timer) async {
    final outcome = await publishToGroups(
      _publisherGroupIds,
      (groupId) => FirebaseProvider().heartbeat(groupId, email),
    );
    if (outcome.failed.isNotEmpty) {
      debugPrint(
        '[ForegroundService] Heartbeat failed in ${outcome.failed.keys}',
      );
    }
  });

  _minPeriod = await _readMinPeriod();

  // Tenta obter e sincronizar a localização inicial imediatamente
  try {
    final initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
    if (_minPeriodElapsed(DateTime.now()) &&
        await _publish(email, name, initialPosition)) {
      _lastRecordedPosition = initialPosition;
      _lastPositionWriteAt = DateTime.now();
    }
    service.invoke('updateLocationLocally', {'position': initialPosition});
  } catch (e) {
    debugPrint(
      '[ForegroundService] Erro ao obter posição inicial no serviço: $e',
    );
  }

  await _positionSubscription?.cancel();
  _positionSubscription =
      Geolocator.getPositionStream(locationSettings: locationSettings).listen((
        Position position,
      ) async {
        // TODO: Filtro de precisão: Se o erro for maior que 20 metros, ignorar
        // e.g.: if (position.accuracy > 20) return;

        // Se muitos erros de permissão consecutivos, parar de tentar
        if (_consecutivePermissionErrors >= _maxConsecutivePermissionErrors) {
          debugPrint(
            '[ForegroundService] Muitos erros de permissão consecutivos '
            '($_consecutivePermissionErrors). Parando tentativas de escrita.',
          );
          return;
        }

        // Evita duplicatas se a posição for essencialmente idêntica à última registrada
        // (por exemplo, primeiro evento do stream emitindo o mesmo fix da posição inicial).
        if (_lastRecordedPosition != null) {
          final distanceMoved = Geolocator.distanceBetween(
            _lastRecordedPosition!.latitude,
            _lastRecordedPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          if (distanceMoved < radius) {
            service.invoke('updateLocationLocally', {'position': position});
            return;
          }
        }

        // The plan limits how often a position may be written.
        if (!_minPeriodElapsed(DateTime.now())) {
          service.invoke('updateLocationLocally', {'position': position});
          return;
        }

        if (await _publish(email, name, position)) {
          _lastRecordedPosition = position;
          _lastPositionWriteAt = DateTime.now();
        }

        // Envia para o app principal
        service.invoke('updateLocationLocally', {'position': position});
      });
}
