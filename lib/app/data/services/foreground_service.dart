import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';
import 'package:monamie_app/app/data/partner/partner_session.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';

Timer? _heartbeatTimer;
StreamSubscription<Position>? _positionSubscription;
StreamSubscription<User?>? _authSubscription;
int interval = 5;
int distance = 10;
int heartbeatInterval = 5;
Position? _lastRecordedPosition;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // [DEFAULT] is the central project (from google-services.json); the
  // partner's app was created natively by MonAmieApplication.
  await Firebase.initializeApp();
  // The UI stored the bound partner; without one there is nowhere to write.
  if (await PartnerSession().restore() == null) {
    debugPrint('[ForegroundService] No partner bound — stopping the service.');
    service.stopSelf();
    return;
  }

  // Verificar se o auth state está disponível no isolate do background.
  // No Android, o Firebase Auth persiste credenciais via SharedPreferences
  // no nível nativo, que são compartilhadas entre Flutter engines no
  // mesmo processo. Forçamos um refresh do token para garantir que os
  // custom claims (share, watch, owns) estejam presentes.
  final currentUser = CurrentPartnerFirebase.instance.auth.currentUser;
  if (currentUser != null) {
    try {
      await currentUser.getIdToken(true);
      debugPrint(
        '[ForegroundService] Auth disponível no background: '
        '${currentUser.email}',
      );
    } catch (e) {
      debugPrint('[ForegroundService] Erro ao refresh token: $e');
    }
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
  _authSubscription = CurrentPartnerFirebase.instance.auth
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
      await updateLocation(
        service,
        event['email'],
        event['name'],
        event['grupoAtivo'] as String?,
      );
    }
  });

  service.invoke('ready');
}

void _stopTracking(ServiceInstance service) {
  _authSubscription?.cancel();
  _authSubscription = null;
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

/// Contagem de erros consecutivos de permissão, usada para evitar
/// spam de tentativas quando os claims não estão disponíveis.
int _consecutivePermissionErrors = 0;
const int _maxConsecutivePermissionErrors = 3;

// TODO: passar UserModel para essa função em vez de email, nome.
Future<void> updateLocation(
  ServiceInstance service,
  String email,
  String name, [
  String? grupoAtivo,
]) async {
  _lastRecordedPosition = null;

  // Configuração do GPS
  late LocationSettings locationSettings;

  if (Platform.isAndroid) {
    locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high, // TODO: testar outros valores aqui
      distanceFilter: distance, // Só atualiza se mover mais de 10 metros
      intervalDuration: Duration(minutes: interval),
    );
  } else if (Platform.isIOS) {
    locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.other,
      distanceFilter: distance,
      pauseLocationUpdatesAutomatically: true,
      showBackgroundLocationIndicator: true,
    );
  } else {
    locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distance,
    );
  }

  _heartbeatTimer?.cancel();
  _heartbeatTimer = Timer.periodic(Duration(minutes: heartbeatInterval), (
    timer,
  ) async {
    if (await FirebaseProvider().doesDocumentExist(email)) {
      try {
        await FirebaseProvider().updateHeartbeat(email);
      } catch (e) {
        debugPrint('[ForegroundService] Erro no heartbeat: $e');
      }
    }
  });

  // Tenta obter e sincronizar a localização inicial imediatamente
  try {
    final initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
    if (await FirebaseProvider().doesDocumentExist(email)) {
      try {
        await FirebaseProvider().updateLocationAndTimestamp(
          email: email,
          nome: name,
          lat: initialPosition.latitude,
          lng: initialPosition.longitude,
          timestamp: DateTime.now(),
          grupoAtivo: grupoAtivo,
        );
        _lastRecordedPosition = initialPosition;
        _consecutivePermissionErrors = 0;
      } catch (e) {
        debugPrint(
          '[ForegroundService] Erro ao sincronizar posição inicial no Firestore: $e',
        );
      }
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
        // print("\n\n${position.accuracy}\n\n");
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
          if (distanceMoved < distance) {
            service.invoke('updateLocationLocally', {'position': position});
            return;
          }
        }

        // Atualiza firebase
        if (await FirebaseProvider().doesDocumentExist(email)) {
          try {
            await FirebaseProvider().updateLocationAndTimestamp(
              email: email,
              nome: name,
              lat: position.latitude,
              lng: position.longitude,
              timestamp: DateTime.now(),
              grupoAtivo: grupoAtivo,
            );
            _lastRecordedPosition = position;
            // Reset do contador em caso de sucesso
            _consecutivePermissionErrors = 0;
          } catch (e) {
            if (e.toString().contains('permission-denied')) {
              _consecutivePermissionErrors++;
              debugPrint(
                '[ForegroundService] PERMISSION_DENIED ao atualizar localização '
                '(tentativa $_consecutivePermissionErrors/$_maxConsecutivePermissionErrors). '
                'O claim share pode estar ausente no token.',
              );
              // Tentar refresh do token para recuperar claims
              try {
                await CurrentPartnerFirebase.instance.auth.currentUser
                    ?.getIdToken(true);
              } catch (_) {}
            } else {
              debugPrint(
                '[ForegroundService] Erro ao atualizar localização: $e',
              );
            }
          }
        }

        // Envia para o app principal
        service.invoke('updateLocationLocally', {'position': position});
      });
}
