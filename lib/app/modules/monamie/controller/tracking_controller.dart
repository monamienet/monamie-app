import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
//import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monamie_app/app/data/services/monamie_claims_service.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/modules/monamie/models/animated_user_marker.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';
import 'package:monamie_app/app/modules/monamie/models/location_point.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/services/foreground_service.dart';


class TrackingController extends GetxController with WidgetsBindingObserver {
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
  final Rxn<UserModel> selectedFirebaseUser = Rxn<UserModel>();
  late final MapController mapController;
  final isTrackingEnabled = false.obs;
  final UserController userCtrl = Get.find<UserController>();
  final PermissionsController permissionsCtrl = Get.find<PermissionsController>();
  final Rx<double?> heading = Rx<double?>(null);
  //StreamSubscription<CompassEvent>? _compassSubscription;

  /// Indica se o dia observado no calendário é o dia atual.
  bool get isObservingToday =>
      Get.find<CalendarController>().isObservingToday;

  /// Mapa de usuários com suas posições animadas para renderização suave.
  final Map<String, AnimatedUserMarker> _animatedMarkers =
      <String, AnimatedUserMarker>{};

  /// RxMap reativo dos marcadores animados para trigger rebuilds na UI.
  final RxMap<String, LatLng> animatedMarkerPositions = <String, LatLng>{}.obs;

  /// Emails dos usuários que possuem pelo menos um ponto registrado no dia observado.
  final RxSet<String> usersWithPointsOnObservedDay = <String>{}.obs;

  /// Timer para animar a transição dos marcadores.
  Timer? _markerAnimationTimer;

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
  StreamSubscription<List<UserModel>>? _groupUsersSubscription;

  /// Timer para debounce do listener de highlightedObservedUsers.
  Timer? _highlightedUsersDebounce;

  /// Inicia o worker que observa mudanças em highlightedObservedUsers.
  void _setupHighlightedUsersListener() {
    ever(
      Get.find<GoogleGroupsController>().highlightedObservedUsers,
      (_) {
        // Debounce para evitar múltiplas reações quando toggleHighlight
        // é chamado rapidamente (adiciona/remove um item por vez)
        _highlightedUsersDebounce?.cancel();
        _highlightedUsersDebounce = Timer(
          const Duration(milliseconds: 100),
          _syncHighlightedTrajectories,
        );
      },
    );
  }

  /// Sincroniza as subscriptions de trajetórias com a lista atual de
  /// highlightedObservedUsers.
  void _syncHighlightedTrajectories() {
    final googleGroupsCtrl = Get.find<GoogleGroupsController>();
    final calendarCtrl = Get.find<CalendarController>();
    final day = calendarCtrl.observedDay.value;
    final members = googleGroupsCtrl.highlightedObservedUsers;

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

  /// Inscreve-se na trajetória de um usuário destacado.
  void _subscribeToHighlightedTrajectory(String email, DateTime day) {
    final stream = FirebaseProvider().getTrajectoryForDate(email, day: day);

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

    final googleGroupsCtrl = Get.find<GoogleGroupsController>();
    for (final member in googleGroupsCtrl.highlightedObservedUsers) {
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
    final googleGroupsCtrl = Get.find<GoogleGroupsController>();
    final observedEmails =
        googleGroupsCtrl.observedMembers.map((m) => m.email).toSet();

    if (isObservingToday) {
      // Verifica, no histórico do dia, quais usuários observados possuem pelo
      // menos um ponto registrado hoje. Apenas estes devem aparecer no mapa.
      usersWithPointsOnObservedDay.clear();
      final futures = <Future<void>>[];
      for (final email in observedEmails) {
        futures.add(() async {
          final hasPoints = await FirebaseProvider().hasPointsOnDate(email, day);
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
          animatedMarkerPositions[user.email] = LatLng(user.lat ?? 0.0, user.lng ?? 0.0);
        }
      }
      return;
    }

    // Dia passado: busca a última posição conhecida no histórico para cada
    // usuário observado.
    final futures = <Future<void>>[];
    for (final email in observedEmails) {
      futures.add(() async {
        final point = await FirebaseProvider().getLastKnownPositionForDate(
          email,
          day: day,
        );

        if (point != null) {
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

  void _subscribeToGroupUsers(String groupEmail) {
    _groupUsersSubscription?.cancel();
    _groupUsersSubscription = FirebaseProvider()
        .streamUsersByGroup(groupEmail)
        .listen(
      (users) {
        firebaseUsers.value = users;
      },
      onError: (e) {
        debugPrint('[TrackingController] Erro no stream do grupo $groupEmail: $e');
      },
    );
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    mapController = MapController();

    // Vincula o stream do Firebase aos usuários do grupo observado
    ever(Get.find<GoogleGroupsController>().selectedGroup, (selectedGroup) {
      if (selectedGroup != null) {
        _subscribeToGroupUsers(selectedGroup.email);
      } else {
        _groupUsersSubscription?.cancel();
        _groupUsersSubscription = null;
        firebaseUsers.clear();
      }
    });

    final initialGroup = Get.find<GoogleGroupsController>().selectedGroup.value;
    if (initialGroup != null) {
      _subscribeToGroupUsers(initialGroup.email);
    }
    
    // Escuta mudanças na lista de usuários para atualizar as animações
    ever(firebaseUsers, _onFirebaseUsersUpdated);

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
    ever(Get.find<GoogleGroupsController>().observedMembers, (_) {
      final day = Get.find<CalendarController>().observedDay.value;
      _refreshMarkersForObservedDay(day);
    });

    _initPosition();

    isTrackingEnabled.value = await _service.isRunning();
  }

  Future<void> _initPosition() async {
    if (userCtrl.isTrackable()) {
      position = await Geolocator.getCurrentPosition();
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
        final didUpdate =
            _animatedMarkers[user.email]!.updateTargetPosition(
          user.lat ?? 0.0,
          user.lng ?? 0.0,
        );
        if (didUpdate) {
          shouldAnimateMarkers = true;
        }
      } else {
        // Cria novo marcador animado
        _animatedMarkers[user.email] = AnimatedUserMarker(user: user);
        animatedMarkerPositions[user.email] =
            LatLng(user.lat ?? 0.0, user.lng ?? 0.0);
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
      final renderedPosition =
          entry.value.updateAnimationProgress(_animationProgress);
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

  void openFirebaseUserDetails(UserModel user) {
    selectedFirebaseUser.value = user;
  }

  void closeFirebaseUserDetails() {
    selectedFirebaseUser.value = null;
  }

  Future<void> toggleService() async {
    var isRunning = await _service.isRunning();
  
    if (isRunning) {
      _stopService();
    } else {
      _startService();
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
        initialNotificationTitle: "UM+: Monitoramento de jornada ativo",
        initialNotificationContent:
            "O monitoramento está ligado. Certifique-se de desativá-lo assim que terminar suas atividades.",
      ),
    );
  }

  Future<void> _startService() async {
    // Verifica se GPS está ativado.
    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      permissionsCtrl.notifyGpsDisabled();
      return; // Interrompe a execução para não iniciar o serviço sem GPS
    }

    // Garante que os custom claims (group_roles) estejam presentes
    // e contenham MEMBER ou MANAGER antes de escrever no Firestore.
    final hasClaims = await MonAmieClaimsService.ensureClaims();
    if (!hasClaims) {
      debugPrint(
        '[TrackingController] Claims inválidos — tracking não iniciado.',
      );
      Get.snackbar(
        'Não foi possível iniciar o rastreamento',
        'Suas permissões de grupo não puderam ser verificadas. '
        'Tente atualizar seus grupos e tentar novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    // Determina o grupo operacional ativo para esta jornada
    final googleGroupsCtrl = Get.find<GoogleGroupsController>();
    final observableGroups = await googleGroupsCtrl.getObservableGroupsForUser();

    if (observableGroups.isEmpty) {
      debugPrint('[TrackingController] Usuário não é MEMBER ou MANAGER em nenhum grupo.');
      Get.snackbar(
        'Rastreamento não autorizado',
        'Você não possui papel de participante (MEMBER ou MANAGER) em nenhum grupo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    String? activeGroupEmail;

    if (observableGroups.length == 1) {
      activeGroupEmail = observableGroups.first.email;
    } else {
      // Se tiver mais de um grupo observável, checa se o grupo atualmente selecionado é um deles
      final currentSelected = googleGroupsCtrl.selectedGroup.value;
      if (currentSelected != null &&
          observableGroups.any((g) => g.email.trim().toLowerCase() == currentSelected.email.trim().toLowerCase())) {
        activeGroupEmail = currentSelected.email;
      } else {
        // Exibe BottomSheet para seleção explícita do grupo operacional
        final selected = await Get.bottomSheet<GoogleGroupModel>(
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Iniciar Rastreamento de Jornada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecione o grupo operacional em que você atuará neste turno:',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: observableGroups.length,
                    itemBuilder: (context, index) {
                      final g = observableGroups[index];
                      return ListTile(
                        leading: const Icon(Icons.group, color: Colors.indigo),
                        title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        subtitle: Text(g.email, style: const TextStyle(color: Colors.black54)),
                        onTap: () => Get.back(result: g),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          isDismissible: true,
        );

        if (selected == null) {
          debugPrint('[TrackingController] Usuário cancelou a seleção do grupo.');
          return;
        }
        activeGroupEmail = selected.email;
      }
    }
  
    // Tenta obter a posição GPS atual para sincronizar imediatamente
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('[TrackingController] Erro ao obter posição atual imediata: $e');
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
        "grupoAtivo": activeGroupEmail,
      });
    });
  
    // Este listener ouve atualizações da posição por parte do serviço em
    // foreground.
    _locationSubscription = _service.on('updateLocationLocally').listen((event) {
      if (event != null) {
        position = Position.fromMap(event['position']);
      }
    });
  
    // Atualiza UI (botão).
    isTrackingEnabled.value = true;

    // Registra imediatamente que o usuário atual possui ponto no dia de hoje
    usersWithPointsOnObservedDay.add(userCtrl.user!.email);

    // Informa Firebase que sua posição pode ser visualizada no mapa associada ao grupo ativo.
    // A persistência de localização e histórico é gerenciada exclusivamente pelo ForegroundService.
    try {
      await FirebaseProvider().updateIsTracked(
        userCtrl.user!.email,
        true,
        grupoAtivo: activeGroupEmail,
      );
    } catch (e) {
      debugPrint('[TrackingController] Erro ao atualizar status inicial de rastreamento: $e');
      Get.snackbar(
        'Erro ao iniciar rastreamento',
        'Não foi possível atualizar o status de rastreamento. '
        'Verifique suas permissões de grupo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 5),
      );
      // Reverter estado — o serviço foi iniciado mas o Firestore recusou
      _stopService();
    }
  }
  
  Future<void> _stopService() async {
    await _readySubscription?.cancel();
    _readySubscription = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _service.invoke("stopService");
    isTrackingEnabled.value = false;
    try {
      await FirebaseProvider().updateIsTracked(userCtrl.user!.email, false);
    } catch (e) {
      debugPrint('[TrackingController] Erro ao desativar isTracked: $e');
    }
  }

  @override
  void onClose() {
    //_compassSubscription?.cancel();
    _groupUsersSubscription?.cancel();
    _readySubscription?.cancel();
    _locationSubscription?.cancel();
    _markerAnimationTimer?.cancel();
    mapController.dispose();
    super.onClose();
  }
}
