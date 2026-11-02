import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
//import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/ui/home/view_models/permissions_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/group_map_state.dart';
import 'package:monamie_app/ui/home/view_models/live_users.dart';
import 'package:monamie_app/data/repositories/positions/firebase_provider.dart';
import 'package:monamie_app/ui/home/widgets/animated_user_marker.dart';
import 'package:monamie_app/domain/models/location_point.dart';
import 'package:monamie_app/domain/models/user_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:monamie_app/domain/models/sharing_times.dart';
import 'package:monamie_app/data/services/foreground_service.dart';
import 'package:monamie_app/ui/home/view_models/tracking_toggle_view_model.dart';
import 'package:monamie_app/ui/core/ui/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

/// The map of the home screen: the markers of the observed group, the
/// person's own position, the highlighted trails and the sharing switch.
///
/// Each value is its own [ValueListenable] and notifies only when it
/// changes: lists, sets and maps are replaced whole, never changed in
/// place. Whoever creates it calls [start] once, which begins listening to
/// the other home controllers, and [dispose] once, which removes every
/// listener and cancels every timer and trail subscription.
class TrackingViewModel implements TrackingToggleViewModel {
  /// [notices] shows the warnings raised by background changes, which no
  /// screen is waiting for. [userCtrl], [permissionsCtrl], [calendar] and
  /// [groupMap] are the other home view models this one reacts to. The
  /// plugins come in too: [service] (the tracking service), [location] (the
  /// GPS) and [positions] (the groups' positions and trails).
  TrackingViewModel({
    required this._notices,
    required this.userCtrl,
    required this.permissionsCtrl,
    required this._calendar,
    required this._groupMap,
    required this._service,
    required this._location,
    required this._positions,
  });

  final NoticePresenter _notices;
  final CalendarViewModel _calendar;
  final GroupMapState _groupMap;
  final FlutterBackgroundService _service;
  final DeviceLocation _location;
  final FirebaseProvider _positions;
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
  final _firebaseUsers = ValueNotifier<List<UserModel>>(const []);
  final _groupUsers = ValueNotifier<List<UserModel>>(const []);
  final _isTrackingEnabled = ValueNotifier<bool>(false);
  final _isTrackingLoading = ValueNotifier<bool>(false);
  final _heading = ValueNotifier<double?>(null);
  final _ownPosition = ValueNotifier<LatLng?>(null);
  final _animatedMarkerPositions = ValueNotifier<Map<String, LatLng>>(const {});
  final _usersWithPointsOnObservedDay = ValueNotifier<Set<String>>(const {});
  final _highlightedTrajectories =
      ValueNotifier<Map<String, List<LocationPoint>>>(const {});

  /// The live positions of the observed group: those of [groupUsers] still
  /// within the validity.
  ValueListenable<List<UserModel>> get firebaseUsers => _firebaseUsers;

  /// Every position of the observed group, sharing or not: the group list's
  /// source. [firebaseUsers] is the live part of it.
  ValueListenable<List<UserModel>> get groupUsers => _groupUsers;

  final MapController mapController = MapController();
  @override
  ValueListenable<bool> get isTrackingEnabled => _isTrackingEnabled;
  @override
  ValueListenable<bool> get isTrackingLoading => _isTrackingLoading;
  final UserViewModel userCtrl;
  final PermissionsViewModel permissionsCtrl;

  /// The compass heading, in degrees, or `null` (the compass is off).
  ValueListenable<double?> get heading => _heading;

  /// Where this device is, once a fix is known. It is the person's own
  /// marker on the map, which a person who only shares cannot get from the
  /// group's documents (they observe no group).
  ValueListenable<LatLng?> get ownPosition => _ownPosition;

  bool _started = false;
  bool _disposed = false;

  /// Sets [notifier] (which notifies only when the value differs), unless
  /// disposed: a Firestore answer or a GPS fix may land after [dispose].
  void _set<T>(ValueNotifier<T> notifier, T value) {
    if (!_disposed) notifier.value = value;
  }

  /// Replaces [notifier]'s list with an unmodifiable copy of [value] when
  /// their content differs (the items compare by content).
  void _setList<T>(ValueNotifier<List<T>> notifier, List<T> value) {
    if (_disposed || listEquals(notifier.value, value)) return;
    notifier.value = List.unmodifiable(value);
  }

  /// Replaces the set of [usersWithPointsOnObservedDay] when it differs.
  void _setUsersWithPoints(Set<String> value) {
    if (_disposed || setEquals(_usersWithPointsOnObservedDay.value, value)) {
      return;
    }
    _usersWithPointsOnObservedDay.value = Set.unmodifiable(value);
  }

  void _addUserWithPoints(String email) =>
      _setUsersWithPoints({..._usersWithPointsOnObservedDay.value, email});

  /// Replaces the map of [animatedMarkerPositions] when it differs.
  void _setMarkerPositions(Map<String, LatLng> value) {
    if (_disposed || mapEquals(_animatedMarkerPositions.value, value)) return;
    _animatedMarkerPositions.value = Map.unmodifiable(value);
  }

  void _putMarkerPosition(String email, LatLng position) =>
      _setMarkerPositions({..._animatedMarkerPositions.value, email: position});

  void _removeMarkerPosition(String email) {
    if (!_animatedMarkerPositions.value.containsKey(email)) return;
    _setMarkerPositions({..._animatedMarkerPositions.value}..remove(email));
  }

  /// Replaces the map of [highlightedTrajectories] when its content
  /// differs (the trails compare point by point).
  void _setTrajectories(Map<String, List<LocationPoint>> value) {
    final current = _highlightedTrajectories.value;
    final same =
        current.length == value.length &&
        value.entries.every(
          (e) =>
              current.containsKey(e.key) && listEquals(current[e.key], e.value),
        );
    if (_disposed || same) return;
    _highlightedTrajectories.value =
        Map.unmodifiable(<String, List<LocationPoint>>{
          for (final e in value.entries)
            e.key: List<LocationPoint>.unmodifiable(e.value),
        });
  }
  //StreamSubscription<CompassEvent>? _compassSubscription;

  /// Indica se o dia observado no calendário é o dia atual.
  bool get isObservingToday => _calendar.isObservingToday;

  /// Mapa de usuários com suas posições animadas para renderização suave.
  final Map<String, AnimatedUserMarker> _animatedMarkers =
      <String, AnimatedUserMarker>{};

  /// The rendered position of each marker, by e-mail (animated between
  /// two positions).
  ValueListenable<Map<String, LatLng>> get animatedMarkerPositions =>
      _animatedMarkerPositions;

  /// Emails dos usuários que possuem pelo menos um ponto registrado no dia observado.
  ValueListenable<Set<String>> get usersWithPointsOnObservedDay =>
      _usersWithPointsOnObservedDay;

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
  ValueListenable<Map<String, List<LocationPoint>>>
  get highlightedTrajectories => _highlightedTrajectories;

  /// Subscriptions para as trajetórias dos usuários destacados.
  final Map<String, StreamSubscription<List<LocationPoint>>>
  _highlightedTrajectorySubscriptions = {};

  StreamSubscription<Map<String, dynamic>?>? _readySubscription;
  StreamSubscription<Map<String, dynamic>?>? _locationSubscription;

  /// Timer para debounce do listener de highlightedObservedUsers.
  Timer? _highlightedUsersDebounce;

  /// Reacts to a change of highlightedObservedUsers.
  void _onHighlightedUsersChanged() {
    // Debounce para evitar múltiplas reações quando toggleHighlight
    // é chamado rapidamente (adiciona/remove um item por vez)
    _highlightedUsersDebounce?.cancel();
    _highlightedUsersDebounce = Timer(
      const Duration(milliseconds: 100),
      _syncHighlightedTrajectories,
    );
  }

  /// Reacts to a new observed group's positions.
  void _onGroupPositionsChanged() =>
      _onGroupPositions(_groupMap.groupPositions.value);

  /// Recarrega trajetórias destacadas quando o dia observado muda.
  void _onObservedDayChanged() =>
      onObservedDayChanged(_calendar.observedDay.value);

  /// Atualiza marcadores ao trocar de grupo (membros observados mudaram).
  void _onObservedMembersChanged() =>
      _refreshMarkersForObservedDay(_calendar.observedDay.value);

  /// The person's capabilities arrive after this controller starts: look
  /// for the device again when they do.
  void _onCapabilitiesChanged() => _initPosition();

  /// The location permission arrives after this controller starts: look
  /// for the device again when it is granted.
  void _onWhenInUsePermissionChanged() {
    if (permissionsCtrl.hasWhenInUseLocationPermission.value) _initPosition();
  }

  /// Avisa se o app passou a ser restrito em segundo plano durante uma
  /// jornada ativa: o rastreamento vai parar quando o app sair da tela.
  void _onBackgroundRestrictedChanged() {
    if (permissionsCtrl.isBackgroundRestricted.value &&
        _isTrackingEnabled.value) {
      _notices.show(
        const UserNotice(
          'O aparelho está restringindo o MonAmie em segundo plano. '
          'O rastreamento vai parar quando você sair do aplicativo.',
          title: 'Rastreamento em risco',
        ),
      );
    }
  }

  /// Animates the markers when the live positions change.
  void _onFirebaseUsersChanged() =>
      _onFirebaseUsersUpdated(_firebaseUsers.value);

  /// Sincroniza as subscriptions de trajetórias com a lista atual de
  /// highlightedObservedUsers.
  void _syncHighlightedTrajectories() {
    if (_disposed) return;
    final day = _calendar.observedDay.value;
    final members = _groupMap.highlightedObservedUsers.value;

    final currentEmails = members.map((m) => m.email).toSet();

    // Cancela subscriptions de usuários que não estão mais destacados
    for (final email in _highlightedTrajectorySubscriptions.keys.toList()) {
      if (!currentEmails.contains(email)) {
        _highlightedTrajectorySubscriptions[email]?.cancel();
        _highlightedTrajectorySubscriptions.remove(email);
        if (_highlightedTrajectories.value.containsKey(email)) {
          _setTrajectories({..._highlightedTrajectories.value}..remove(email));
        }
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
    if (_disposed) return;
    final groupId = _groupMap.selectedGroup.value?.id;
    if (groupId == null) return;
    final stream = _positions.getTrajectoryForDate(groupId, email, day: day);

    final subscription = stream.listen((points) {
      _setTrajectories({..._highlightedTrajectories.value, email: points});
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
    _setTrajectories(const {});

    for (final member in _groupMap.highlightedObservedUsers.value) {
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
    if (_disposed) return;
    final groupId = _groupMap.selectedGroup.value?.id;
    if (groupId == null) return;

    if (isObservingToday) {
      final observedEmails = _groupMap.observedMembers.value
          .map((m) => m.email)
          .toSet();
      // Verifica, no histórico do dia, quais usuários observados possuem pelo
      // menos um ponto registrado hoje. Apenas estes devem aparecer no mapa.
      _setUsersWithPoints(const {});
      final futures = <Future<void>>[];
      for (final email in observedEmails) {
        futures.add(() async {
          final hasPoints = await _positions.hasPointsOnDate(
            groupId,
            email,
            day,
          );
          if (hasPoints) {
            _addUserWithPoints(email);
          }
        }());
      }
      await Future.wait(futures);

      // Usuários atualmente ativos no stream também possuem pontos hoje.
      for (final user in _firebaseUsers.value) {
        _addUserWithPoints(user.email);
      }

      // Remove marcadores de usuários que não possuem pontos hoje.
      final toRemoveToday = _animatedMarkers.keys
          .where(
            (email) => !_usersWithPointsOnObservedDay.value.contains(email),
          )
          .toList();
      for (final email in toRemoveToday) {
        _animatedMarkers.remove(email);
        _removeMarkerPosition(email);
      }

      // Atualiza posições IMEDIATAMENTE sem animação para troca de dia
      for (final user in _firebaseUsers.value) {
        if (_usersWithPointsOnObservedDay.value.contains(user.email)) {
          if (_animatedMarkers.containsKey(user.email)) {
            _animatedMarkers[user.email]!.setPositionImmediate(
              user.lat ?? 0.0,
              user.lng ?? 0.0,
            );
          } else {
            _animatedMarkers[user.email] = AnimatedUserMarker(user: user);
          }
          _putMarkerPosition(
            user.email,
            LatLng(user.lat ?? 0.0, user.lng ?? 0.0),
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
    _setUsersWithPoints(const {});
    final futures = <Future<void>>[];
    for (final email in observedEmails) {
      futures.add(() async {
        final point = await _positions.getLastKnownPositionForDate(
          groupId,
          email,
          day: day,
        );

        if (point != null) {
          _addUserWithPoints(email);
          final user = _firebaseUsers.value
              .where((u) => u.email == email)
              .firstOrNull;
          if (_animatedMarkers.containsKey(email)) {
            _animatedMarkers[email]!.updateTargetPosition(point.lat, point.lng);
          } else if (user != null) {
            _animatedMarkers[email] = AnimatedUserMarker(user: user);
          }
          _putMarkerPosition(email, LatLng(point.lat, point.lng));
        } else {
          // Sem registro para o dia: remove o marcador.
          _animatedMarkers.remove(email);
          _removeMarkerPosition(email);
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
      _removeMarkerPosition(email);
    }

    // Atualiza posições IMEDIATAMENTE sem animação para troca de dia
    for (final email in observedEmails) {
      final marker = _animatedMarkers[email];
      final pos = _animatedMarkerPositions.value[email];
      if (marker != null && pos != null) {
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
    _setTrajectories(const {});
  }

  Future<void> centerMapOnCurrentLocation() async {
    if (_disposed) return;
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
      _groupUsers.value,
      now: DateTime.now(),
      validity: validity,
    );
    // Only when someone actually left.
    if (stillLive.length != _firebaseUsers.value.length) {
      _setList(_firebaseUsers, stillLive);
    }
  }

  /// Takes the observed group's positions (read by [GroupMapState]).
  void _onGroupPositions(List<UserModel> users) {
    _setList(_groupUsers, users);
    _setList(
      _firebaseUsers,
      liveUsers(users, now: DateTime.now(), validity: validity),
    );
  }

  /// Starts listening to the other home controllers, reads the observed
  /// group's positions, looks for the device and asks whether the tracking
  /// service is running. Only the first call does anything; every listener
  /// added here is removed in [dispose].
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;

    // The observed group's positions drive the markers and the list.
    _groupMap.groupPositions.addListener(_onGroupPositionsChanged);

    // Avisa se o app passou a ser restrito em segundo plano durante uma
    // jornada ativa: o rastreamento vai parar quando o app sair da tela.
    permissionsCtrl.isBackgroundRestricted.addListener(
      _onBackgroundRestrictedChanged,
    );

    _onGroupPositions(_groupMap.groupPositions.value);

    // Escuta mudanças na lista de usuários para atualizar as animações
    _firebaseUsers.addListener(_onFirebaseUsersChanged);

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
    _groupMap.highlightedObservedUsers.addListener(_onHighlightedUsersChanged);

    // Observa mudanças no observedDay para recarregar trajetórias destacadas
    _calendar.observedDay.addListener(_onObservedDayChanged);

    // Observa mudanças nos membros observados para atualizar marcadores ao trocar de grupo
    _groupMap.observedMembers.addListener(_onObservedMembersChanged);

    _initPosition();
    // The person's capabilities and the location permission arrive after this
    // controller starts: look for the device again when they do.
    _groupMap.capabilities.addListener(_onCapabilitiesChanged);
    permissionsCtrl.hasWhenInUseLocationPermission.addListener(
      _onWhenInUsePermissionChanged,
    );

    final running = await _service.isRunning();
    _set(_isTrackingEnabled, running);
  }

  void _setPosition(Position value) {
    position = value;
    _set(_ownPosition, LatLng(value.latitude, value.longitude));
  }

  bool _locating = false;

  Future<void> _initPosition() async {
    // One look at a time; only for people who can share.
    if (_disposed || _locating || !userCtrl.isTrackable()) return;
    _locating = true;
    try {
      _setPosition(
        await _location.currentPosition().timeout(const Duration(seconds: 5)),
      );
      // A person who only shares has no group on the map: show them.
      if (!_groupMap.canWatch) {
        await centerMapOnCurrentLocation();
      }
    } catch (e) {
      debugPrint('[TrackingViewModel] Erro ao obter posição inicial: $e');
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
    if (_disposed || !isObservingToday) return;

    bool shouldAnimateMarkers = false;

    for (final user in users) {
      // Usuários presentes em firebaseUsers estão ativamente transmitindo hoje
      _addUserWithPoints(user.email);
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
        _putMarkerPosition(
          user.email,
          LatLng(user.lat ?? 0.0, user.lng ?? 0.0),
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
      _removeMarkerPosition(email);
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
  /// One frame: every marker moves, then the map is notified once.
  void _updateAnimatedMarkerPositions() {
    final next = {..._animatedMarkerPositions.value};
    for (final entry in _animatedMarkers.entries) {
      next[entry.key] = entry.value.updateAnimationProgress(_animationProgress);
    }
    _setMarkerPositions(next);
  }

  /// Starts or stops sharing. Completes with [Ok] (holding a [UserNotice]
  /// when sharing started without a GPS fix yet), or [Err] when sharing could
  /// not start; [Ok] with `null` while another toggle is running.
  @override
  Future<Result<UserNotice?>> toggleService() async {
    if (_isTrackingLoading.value) return const Ok(null);

    _set(_isTrackingLoading, true);
    try {
      final isRunning = await _service.isRunning();

      if (isRunning) {
        await _stopService();
        return const Ok(null);
      }
      // The home closed (sign-out, leaving the organization) while asking:
      // nothing may start publishing for an organization that is gone.
      if (_disposed) return const Ok(null);
      return await _startService();
    } catch (e, stackTrace) {
      debugPrint(
        '[TrackingViewModel] Erro ao alternar serviço de rastreamento: $e\n$stackTrace',
      );
      return Err(
        'Não foi possível alterar o compartilhamento agora. Tente de novo.',
        title: 'Compartilhamento',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _set(_isTrackingLoading, false);
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

  Future<Result<UserNotice?>> _startService() async {
    // No modo de bateria "Restrito" o Android remove o status de foreground
    // do serviço assim que o app sai da tela; não adianta iniciar.
    if (await permissionsCtrl.refreshBackgroundRestriction()) {
      await permissionsCtrl.openBackgroundUsageSettings();
      return const Ok(null);
    }

    // Verifica se GPS está ativado.
    bool gpsEnabled = await _location.isServiceEnabled();
    if (!gpsEnabled) {
      permissionsCtrl.notifyGpsDisabled();
      // Interrompe a execução para não iniciar o serviço sem GPS
      return const Ok(null);
    }

    // The rules only accept positions from people who publish in a group;
    // the service publishes in every one of them.
    if (!_groupMap.canPublish) {
      debugPrint('[TrackingViewModel] The user publishes in no group.');
      return const Err(
        'Você não está em campo em nenhum grupo. Peça a um administrador '
        'para liberar o compartilhamento da sua localização.',
        title: 'Compartilhamento não autorizado',
      );
    }

    // Tenta obter a posição GPS atual para sincronizar imediatamente
    UserNotice? notice;
    try {
      _setPosition(
        await _location.currentPosition().timeout(const Duration(seconds: 5)),
      );
    } catch (e) {
      debugPrint(
        '[TrackingViewModel] Erro ao obter posição atual imediata: $e',
      );
      // The service still starts: the person hears that the satellites
      // are still syncing.
      notice = const UserNotice(
        'O monitoramento foi iniciado, mas a sua posição inicial ainda está sendo obtida pelos satélites.',
        title: 'Aguardando sinal de GPS',
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
    _set(_isTrackingEnabled, true);

    // Registra imediatamente que o usuário atual possui ponto no dia de hoje
    _addUserWithPoints(userCtrl.user!.email);

    // The service turns `isPublishing` on in every group and publishes the
    // positions: this screen writes nothing while sharing.
    return Ok(notice);
  }

  Future<void> _stopService() async {
    await _readySubscription?.cancel();
    _readySubscription = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _service.invoke("stopService");
    _set(_isTrackingEnabled, false);
    try {
      await _positions.markNotPublishing(userCtrl.user!.email);
    } catch (e) {
      debugPrint('[TrackingViewModel] Erro ao desativar isPublishing: $e');
    }
  }

  /// Removes every listener added by [start], cancels the timers (marker
  /// animation, highlight debounce, validity recheck) and the trail and
  /// service subscriptions, and releases the values. Only the first call
  /// does anything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _groupMap.groupPositions.removeListener(_onGroupPositionsChanged);
    _groupMap.highlightedObservedUsers.removeListener(
      _onHighlightedUsersChanged,
    );
    _calendar.observedDay.removeListener(_onObservedDayChanged);
    _groupMap.observedMembers.removeListener(_onObservedMembersChanged);
    _groupMap.capabilities.removeListener(_onCapabilitiesChanged);
    permissionsCtrl.isBackgroundRestricted.removeListener(
      _onBackgroundRestrictedChanged,
    );
    permissionsCtrl.hasWhenInUseLocationPermission.removeListener(
      _onWhenInUsePermissionChanged,
    );
    _firebaseUsers.removeListener(_onFirebaseUsersChanged);
    //_compassSubscription?.cancel();
    _readySubscription?.cancel();
    _locationSubscription?.cancel();
    for (final subscription in _highlightedTrajectorySubscriptions.values) {
      subscription.cancel();
    }
    _highlightedTrajectorySubscriptions.clear();
    _highlightedUsersDebounce?.cancel();
    _markerAnimationTimer?.cancel();
    _recheckTimer?.cancel();
    mapController.dispose();
    for (final notifier in <ChangeNotifier>[
      _firebaseUsers,
      _groupUsers,
      _isTrackingEnabled,
      _isTrackingLoading,
      _heading,
      _ownPosition,
      _animatedMarkerPositions,
      _usersWithPointsOnObservedDay,
      _highlightedTrajectories,
    ]) {
      notifier.dispose();
    }
  }
}
