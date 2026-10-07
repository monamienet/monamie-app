import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/firebase_options.dart';

Timer? _heartbeatTimer;
StreamSubscription<Position>? _positionSubscription;
int interval = 5;
int distance = 10;
int heartbeatInterval = 5;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  await Firebase.initializeApp(
    //name: 'uffmobileplus',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Verificar se o auth state está disponível no isolate do background.
  // No Android, o Firebase Auth persiste credenciais via SharedPreferences
  // no nível nativo, que são compartilhadas entre Flutter engines no
  // mesmo processo. Forçamos um refresh do token para garantir que os
  // custom claims (harpia_roles) estejam presentes.
  final currentUser = FirebaseAuth.instance.currentUser;
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

  service.on('stopService').listen((event) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    service.stopSelf();
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
  _heartbeatTimer = Timer.periodic(Duration(minutes: heartbeatInterval), (timer) async {
    if (await FirebaseProvider().doesDocumentExist(email)) {
      try {
        await FirebaseProvider().updateHeartbeat(email);
      } catch (e) {
        debugPrint('[ForegroundService] Erro no heartbeat: $e');
      }
    }
  });

  await _positionSubscription?.cancel();
  _positionSubscription = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen((Position position) async {
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
        // Reset do contador em caso de sucesso
        _consecutivePermissionErrors = 0;
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          _consecutivePermissionErrors++;
          debugPrint(
            '[ForegroundService] PERMISSION_DENIED ao atualizar localização '
            '(tentativa $_consecutivePermissionErrors/$_maxConsecutivePermissionErrors). '
            'Claims harpia_roles podem estar ausentes no token.',
          );
          // Tentar refresh do token para recuperar claims
          try {
            await FirebaseAuth.instance.currentUser?.getIdToken(true);
          } catch (_) {}
        } else {
          debugPrint('[ForegroundService] Erro ao atualizar localização: $e');
        }
      }
    }

    // Envia para o app principal
    service.invoke('updateLocationLocally', {'position': position});
  });
}

