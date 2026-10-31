import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
//import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/data/live_users.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/modules/monamie/models/animated_user_marker.dart';
import 'package:monamie_app/app/modules/monamie/models/location_point.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/tracking/sharing_times.dart';
import 'package:monamie_app/app/data/services/foreground_service.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_toggle_controller.dart';

class TrackingController extends GetxController
    with WidgetsBindingObserver
    implements TrackingToggleController {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  Position position = Position(
    latitude: -22.9041, // latitude em Niterói
    longitude: -43.1329, // longitude em Niterói
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
  RxList<UserModel> firebaseUsers = <UserModel>[].obs;

  /// Every position of the observed group, sharing or not: the group list's
  /// source. [firebaseUsers] is the live part of it.
  final RxList<UserModel> groupUsers = <UserModel>[].obs;
  late final MapController mapController;
  @override
  final isTrackingEnabled = false.obs;
  @override
  final isTrackingLoading = false.obs;
  final UserController userCtrl = Get.find<UserController>();
  final PermissionsController permissionsCtrl =
      Get.find<PermissionsController>();
  final Rx<double?> heading = Rx<double?>(null);

  /// Where this device is, once a fix is known. It is the person's own
  /// marker on the map, which a person who only shares cannot get from the
  /// group's documents (they observe no group).
  final Rxn<LatLng> ownPosition = Rxn<LatLng>();
  //StreamSubscription<CompassEvent>? _compassSubscription;

  /// Indica se o dia observado no calendário é o dia atual.
  bool get isObservingToday => Get.find<CalendarController>().isObservingToday;

  /// Mapa de usuários com suas posições animadas para renderização suave.
  final Map<String, AnimatedUserMarker> _animatedMarkers =
      <String, AnimatedUserMarker>{};

  /// RxMap reativo dos marcadores animados para trigger rebuilds na UI.
  final RxMap<String, LatLng> animatedMarkerPositions = <String, LatLng>{}.obs;

  /// Emails dos usuários que possuem pelo menos um ponto registrado no dia observado.
  final RxSet<String> usersWithPointsOnObservedDay = <String>{}.obs;

  /// Timer para animar a transição dos marcadores.
  Timer? _markerAnimationTimer;

  /// Re-applies the validity every [recheck] (see [_dropUsersNoLongerLive]).
  Timer? _recheckTimer;

  /// Progresso da animação (0.0 a 1.0).
  double _animationProgress = 1.0;

  /// Duração da animação em milissegundos.
  static const int _animationDurationMs = 500;

  /// Trajetórias dos usuários destacados (highlightedObservedUsers).
  /// Chave = email do usuário, valor = lista de pontos da trajetória.
  final RxMap<String, List<LocationPoint>> highlightedTrajectories =
      <String, List<LocationPoint>>{}.obs;

  /// Subscriptions para as trajetórias dos usuários destacados.
  final Map<String, StreamSubscription<List<LocationPoint>>>
  _highlightedTrajectorySubscriptions = {};

  StreamSubscription? _readySubscription;
  StreamSubscription? _locationSubscription;

  GroupMapState get _groupMap => Get.find<GroupMapState>();

  /// Timer para debounce do listener de highlightedObservedUsers.
  Timer? _highlightedUsersDebounce;

  /// Inicia o worker que observa mudanças em highlightedObservedUsers.
  void _setupHighlightedUsersListener() {
    ever(_groupMap.highlightedObservedUsers, (_) {
      // Debounce para evitar múltiplas reações quando toggleHighlight
      // é chamado rapidamente (adiciona/remove um item por vez)
      _highlightedUsersDebounce?.cancel();
      _highlightedUsersDebounce = Timer(
        const Duration(milliseconds: 100),
        _syncHighlightedTrajectories,
      );
    });
  }

  /// Sincroniza as subscriptions de trajetórias com a lista atual de
  /// highlightedObservedUsers.
  void _syncHighlightedTrajectories() {
    final calendarCtrl = Get.find<CalendarController>();
    final day = calendarCtrl.observedDay.value;
    final members = _groupMap.highlightedObservedUsers;

    final currentEmails = members.map((m) => m.email).toSet();

    // Cancela subscriptions de usuários que não estão mais destacados
    for (final email in _highlightedTrajectorySubscriptions.keys.toList()) {
      if (!currentEmails.contains(email)) {
        _highlightedTrajectorySubscriptions[email]?.cancel();
        _highlightedTrajectorySubscriptions.remove(email);
        highlightedTrajectories.remove(email);
      }
    }

    // Inicia novas subscriptions para usuários recém-destacados
    for (final member in members) {
      if (!_highlightedTrajectorySubscriptions.containsKey(member.email)) {
        _subscribeToHighlightedTrajectory(member.email, day);
      }
    }
  }

  /// Inscreve-se na trajetória de um usuário destacado, no grupo observado.
  void _subscribeToHighlightedTrajectory(String email, DateTime day) {
    final groupId = _groupMap.selectedGroup.value?.id;
    if (groupId == null) return;
    final stream = FirebaseProvider().getTrajectoryForDate(
      groupId,
      email,
      day: day,
    );

    final subscription = stream.listen((points) {
      highlightedTrajectories[email] = points;
    });

    _highlightedTrajectorySubscriptions[email] = subscription;
  }

  /// Atualiza as subscriptions de trajetórias destacadas quando o dia
  /// observado muda.
  void onObservedDayChanged(DateTime day) {
    // Recria todas as subscriptions para o novo dia
    for (final sub in _highlightedTrajectorySubscriptions.values) {
      sub.cancel();
    }
    _highlightedTrajectorySubscriptions.clear();
    highlightedTrajectories.clear();

    for (final member in _groupMap.highlightedObservedUsers) {
      _subscribeToHighlightedTrajectory(member.email, day);
    }

    // Recarrega os marcadores para a respectiva localização conhecida no dia.
    _refreshMarkersForObservedDay(day);
  }

  /// Recarrega as posições dos marcadores para o dia observado.
  ///
  /// Quando o dia observado é o atual, restaura as posições em tempo real
  /// vindas do stream de `firebaseUsers`. Quando é um dia passado, busca a
  /// última localização conhecida de cada usuário observado no histórico.
  Future<void> _refreshMarkersForObservedDay(DateTime day) async {
    final groupId = _groupMap.selectedGroup.value?.id;
    if (groupId == null) return;

    if (isObservingToday) {
      final observedEmails = _groupMap.observedMembers
          .map((m) => m.email)
          .toSet();
      // Verifica, no histórico do dia, quais usuários observados possuem pelo
      // menos um ponto registrado hoje. Apenas estes devem aparecer no mapa.
      usersWithPointsOnObservedDay.clear();
      final futures = <Future<void>>[];
      for (final email in observedEmails) {
        futures.add(() async {
          final hasPoints = await FirebaseProvider().hasPointsOnDate(
            groupId,
            email,
            day,
          );
          if (hasPoints) {
            usersWithPointsOnObservedDay.add(email);
          }
        }());
      }
      await Future.wait(futures);

      // Usuários atualmente ativos no stream também possuem pontos hoje.
      for (final user in firebaseUsers) {
        usersWithPointsOnObservedDay.add(user.email);
      }

      // Remove marcadores de usuários que não possuem pontos hoje.
      final toRemoveToday = _animatedMarkers.keys
          .where((email) => !usersWithPointsOnObservedDay.contains(email))
          .toList();
      for (final email in toRemoveToday) {
        _animatedMarkers.remove(email);
        animatedMarkerPositions.remove(email);
      }

      // Atualiza posições IMEDIATAMENTE sem animação para troca de dia
      for (final user in firebaseUsers) {
        if (usersWithPointsOnObservedDay.contains(user.email)) {
          if (_animatedMarkers.containsKey(user.email)) {
            _animatedMarkers[user.email]!.setPositionImmediate(
              user.lat ?? 0.0,
              user.lng ?? 0.0,
            );
          } else {
            _animatedMarkers[user.email] = AnimatedUserMarker(user: user);
          }
          animatedMarkerPositions[user.email] = LatLng(
            user.lat ?? 0.0,
            user.lng ?? 0.0,
          );
        }
      }
      return;
    }

    // Dia passado: busca a última posição conhecida no histórico de cada
    // pessoa que já publicou no grupo, inclusive quem não publica mais.
    final observedEmails = {
      for (final member in await _groupMap.loadHistoryMembers()) member.email,
    };
    usersWithPointsOnObservedDay.clear();
    final futures = <Future<void>>[];
    for (final email in observedEmails) {
      futures.add(() async {
        final point = await FirebaseProvider().getLastKnownPositionForDate(
          groupId,
          email,
          day: day,
        );

        if (point != null) {
          usersWithPointsOnObservedDay.add(email);
          final user = firebaseUsers.firstWhereOrNull((u) => u.email == email);
          if (_animatedMarkers.containsKey(email)) {
            _animatedMarkers[email]!.updateTargetPosition(point.lat, point.lng);
          } else if (user != null) {
            _animatedMarkers[email] = AnimatedUserMarker(user: user);
          }
          animatedMarkerPositions[email] = LatLng(point.lat, point.lng);
        } else {
          // Sem registro para o dia: remove o marcador.
          _animatedMarkers.remove(email);
          animatedMarkerPositions.remove(email);
        }
      }());
    }

    await Future.wait(futures);

    // Remove marcadores de usuários que não estão mais sendo observados.
    final toRemove = _animatedMarkers.keys
        .where((email) => !observedEmails.contains(email))
        .toList();
    for (final email in toRemove) {
      _animatedMarkers.remove(email);
      animatedMarkerPositions.remove(email);
    }

    // Atualiza posições IMEDIATAMENTE sem animação para troca de dia
    for (final email in observedEmails) {
      final marker = _animatedMarkers[email];
      if (marker != null && animatedMarkerPositions.containsKey(email)) {
        final pos = animatedMarkerPositions[email]!;
        marker.setPositionImmediate(pos.latitude, pos.longitude);
      }
    }
  }

  /// Remove todas as trajetórias destacadas.
  void clearHighlightedTrajectories() {
    for (final sub in _highlightedTrajectorySubscriptions.values) {
      sub.cancel();
    }
    _highlightedTrajectorySubscriptions.clear();
    highlightedTrajectories.clear();
  }

  Future<void> centerMapOnCurrentLocation() async {
    try {
      if (!position.latitude.isFinite || !position.longitude.isFinite) {
        return;
      }

      mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      if (kDebugMode) print('Error moving map: $e');
    }
  }

  /// Re-applies [liveUsers] to the last group snapshot, so a person whose
  /// position went stale leaves the map even when no document changed.
  void _dropUsersNoLongerLive() {
    final stillLive = liveUsers(
      groupUsers.toList(),
      now: DateTime.now(),
      validity: validity,
    );
    // Assigning always notifies; do it only when someone actually left.
    if (stillLive.length != firebaseUsers.length) {
      firebaseUsers.value = stillLive;
    }
  }

  /// Takes the observed group's positions (read by [GroupMapState]).
  void _onGroupPositions(List<UserModel> users) {
    groupUsers.value = users.toList();
    firebaseUsers.value = liveUsers(
      users,
      now: DateTime.now(),
      validity: validity,
    );
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    mapController = MapController();

    // The observed group's positions drive the markers and the list.
    ever(_groupMap.groupPositions, _onGroupPositions);

    // Avisa se o app passou a ser restrito em segundo plano durante uma
    // jornada ativa: o rastreamento vai parar quando o app sair da tela.
    ever(permissionsCtrl.isBackgroundRestricted, (bool restricted) {
      if (restricted && isTrackingEnabled.value) {
        Get.snackbar(
          'Rastreamento em risco',
          'O aparelho está restringindo o MonAmie em segundo plano. '
              'O rastreamento vai parar quando você sair do aplicativo.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade100,
          colorText: Colors.black87,
          icon: const Icon(Icons.battery_alert, color: Colors.orange),
          duration: const Duration(seconds: 8),
        );
      }
    });

    _onGroupPositions(_groupMap.groupPositions);

    // Escuta mudanças na lista de usuários para atualizar as animações
    ever(firebaseUsers, _onFirebaseUsersUpdated);

    // O stream só emite quando um documento muda. Quem parou sem conseguir
    // gravar `isPublishing = false` (sem rede, app encerrado) não gera emissão:
    // sem este relógio o marcador ficaria no mapa até alguém mudar.
    _recheckTimer = Timer.periodic(recheck, (_) => _dropUsersNoLongerLive());

    //try {
    //  _compassSubscription = FlutterCompass.events?.listen((event) {
    //    heading.value = event.heading;
    //  });
    //} catch (e) {
    //  if (kDebugMode) print('Compass not available or error: $e');
    //}

    // Configura listener para highlightedObservedUsers
    _setupHighlightedUsersListener();

    // Observa mudanças no observedDay para recarregar trajetórias destacadas
    ever(Get.find<CalendarController>().observedDay, (DateTime day) {
      onObservedDayChanged(day);
    });

    // Observa mudanças nos membros observados para atualizar marcadores ao trocar de grupo
    ever(_groupMap.observedMembers, (_) {
      final day = Get.find<CalendarController>().observedDay.value;
      _refreshMarkersForObservedDay(day);
    });

    _initPosition();
    // The person's capabilities and the location permission arrive after this
    // controller starts: look for the device again when they do.
    ever(_groupMap.capabilities, (_) {
      _initPosition();
    });
    ever(permissionsCtrl.hasWhenInUseLocationPermission, (granted) {
      if (granted) _initPosition();
    });

    isTrackingEnabled.value = await _service.isRunning();
  }

  void _setPosition(Position value) {
    position = value;
    ownPosition.value = LatLng(value.latitude, value.longitude);
  }

  bool _locating = false;

  Future<void> _initPosition() async {
    // One look at a time; only for people who can share.
    if (_locating || !userCtrl.isTrackable()) return;
    _locating = true;
    try {
      _setPosition(
        await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 5),
        ),
      );
      // A person who only shares has no group on the map: show them.
      if (!_groupMap.canWatch) {
        await centerMapOnCurrentLocation();
      }
    } catch (e) {
      debugPrint('[TrackingController] Erro ao obter posição inicial: $e');
    } finally {
      _locating = false;
    }
  }

  /// Chamado quando a lista de usuários do Firebase é atualizada.
  /// Inicializa ou atualiza as animações dos marcadores.
  ///
  /// Quando o dia observado não é o atual, as posições em tempo real são
  /// ignoradas para não sobrescrever as localizações históricas exibidas.
  void _onFirebaseUsersUpdated(List<UserModel> users) {
    // Mantém o cache de usuários sempre atualizado, mas só reposiciona os
    // marcadores quando observamos o dia atual.
    if (!isObservingToday) return;

    bool shouldAnimateMarkers = false;

    for (final user in users) {
      // Usuários presentes em firebaseUsers estão ativamente transmitindo hoje
      usersWithPointsOnObservedDay.add(user.email);
      final exists = _animatedMarkers.containsKey(user.email);

      if (exists) {
        // Atualiza posição existente
        final didUpdate = _animatedMarkers[user.email]!.updateTargetPosition(
          user.lat ?? 0.0,
          user.lng ?? 0.0,
        );
        if (didUpdate) {
          shouldAnimateMarkers = true;
        }
      } else {
        // Cria novo marcador animado
        _animatedMarkers[user.email] = AnimatedUserMarker(user: user);
        animatedMarkerPositions[user.email] = LatLng(
          user.lat ?? 0.0,
          user.lng ?? 0.0,
        );
      }
    }

    // Remove marcadores que não estão mais na lista
    final emailsToRemove = <String>[];
    for (final email in _animatedMarkers.keys) {
      if (!users.any((u) => u.email == email)) {
        emailsToRemove.add(email);
      }
    }
    for (final email in emailsToRemove) {
      _animatedMarkers.remove(email);
      animatedMarkerPositions.remove(email);
    }

    // Inicia a animação se necessário
    if (shouldAnimateMarkers) {
      _startMarkerAnimation();
    }
  }

  /// Inicia o timer de animação dos marcadores.
  void _startMarkerAnimation() {
    _markerAnimationTimer?.cancel();
    _animationProgress = 0.0;

    _markerAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60fps
      (timer) {
        // Incrementa o progresso
        _animationProgress += 16.0 / _animationDurationMs;

        if (_animationProgress >= 1.0) {
          _animationProgress = 1.0;
          timer.cancel();
          _markerAnimationTimer = null;
        }

        _updateAnimatedMarkerPositions();
      },
    );
  }

  /// Atualiza as posições animadas dos marcadores com base no progresso da animação.
  void _updateAnimatedMarkerPositions() {
    for (final entry in _animatedMarkers.entries) {
      final renderedPosition = entry.value.updateAnimationProgress(
        _animationProgress,
      );
      animatedMarkerPositions[entry.key] = renderedPosition;
    }
  }

  /// Método utilizado para escolher a cor dos pins, determinando uma cor
  /// especial para o pin correspondente à localização do próprio usuário
  /// e outra para os demais.
  Color setMarkerColor(UserModel someUser) {
    final currentUserEmail = userCtrl.user?.email;

    return someUser.email == currentUserEmail
        ? Colors.indigo
        : Colors.lightBlue;
  }

  @override
  Future<void> toggleService() async {
    if (isTrackingLoading.value) return;

    isTrackingLoading.value = true;
    try {
      final isRunning = await _service.isRunning();

      if (isRunning) {
        await _stopService();
      } else {
        await _startService();
      }
    } catch (e, stackTrace) {
      debugPrint(
        '[TrackingController] Erro ao alternar serviço de rastreamento: $e\n$stackTrace',
      );
    } finally {
      isTrackingLoading.value = false;
    }
  }

  Future<void> _setPlatformSpecifics() async {
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
        initialNotificationTitle: "Sua localização está sendo compartilhada",
        initialNotificationContent:
            "O compartilhamento está ligado. Para preservar sua privacidade, certifique-se de desativá-lo assim que terminar suas atividades.",
      ),
    );
  }

  Future<void> _startService() async {
    // No modo de bateria "Restrito" o Android remove o status de foreground
    // do serviço assim que o app sai da tela; não adianta iniciar.
    if (await permissionsCtrl.refreshBackgroundRestriction()) {
      await permissionsCtrl.openBackgroundUsageSettings();
      return;
    }

    // Verifica se GPS está ativado.
    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      permissionsCtrl.notifyGpsDisabled();
      return; // Interrompe a execução para não iniciar o serviço sem GPS
    }

    // The rules only accept positions from people who publish in a group;
    // the service publishes in every one of them.
    if (!_groupMap.canPublish) {
      debugPrint('[TrackingController] The user publishes in no group.');
      Get.snackbar(
        'Compartilhamento não autorizado',
        'Você não está em campo em nenhum grupo. Peça a um administrador '
            'para liberar o compartilhamento da sua localização.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    // Tenta obter a posição GPS atual para sincronizar imediatamente
    try {
      _setPosition(
        await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint(
        '[TrackingController] Erro ao obter posição atual imediata: $e',
      );
      Get.snackbar(
        'Aguardando sinal de GPS',
        'O monitoramento foi iniciado, mas a sua posição inicial ainda está sendo obtida pelos satélites.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.black87,
        icon: const Icon(Icons.satellite_alt, color: Colors.orange),
        duration: const Duration(seconds: 5),
      );
    }

    await _setPlatformSpecifics();
    await _readySubscription?.cancel();
    await _locationSubscription?.cancel();
    await _service.startService();

    // Este listener ouve o serviço em foreground avisar que está pronto para
    // receber informações do usuário.
    _readySubscription = _service.on('ready').listen((event) async {
      _service.invoke("setUserInfo", {
        "email": userCtrl.user!.email,
        "name": userCtrl.getUserName(),
      });
    });

    // Este listener ouve atualizações da posição por parte do serviço em
    // foreground.
    _locationSubscription = _service.on('updateLocationLocally').listen((
      event,
    ) {
      if (event != null) {
        _setPosition(Position.fromMap(event['position']));
      }
    });

    // Atualiza UI (botão).
    isTrackingEnabled.value = true;

    // Registra imediatamente que o usuário atual possui ponto no dia de hoje
    usersWithPointsOnObservedDay.add(userCtrl.user!.email);

    // The service turns `isPublishing` on in every group and publishes the
    // positions: this screen writes nothing while sharing.
  }

  Future<void> _stopService() async {
    await _readySubscription?.cancel();
    _readySubscription = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _service.invoke("stopService");
    isTrackingEnabled.value = false;
    try {
      await FirebaseProvider().markNotPublishing(userCtrl.user!.email);
    } catch (e) {
      debugPrint('[TrackingController] Erro ao desativar isPublishing: $e');
    }
  }

  @override
  void onClose() {
    //_compassSubscription?.cancel();
    _readySubscription?.cancel();
    _locationSubscription?.cancel();
    _markerAnimationTimer?.cancel();
    _recheckTimer?.cancel();
    mapController.dispose();
    super.onClose();
  }
}
