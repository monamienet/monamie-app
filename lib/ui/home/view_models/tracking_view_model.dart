import 'dart:async';

import 'package:flutter/foundation.dart';
//import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/data/repositories/observed_day/observed_day_repository.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/domain/use_cases/start_sharing.dart';
import 'package:monamie_app/ui/home/view_models/live_users.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/ui/home/widgets/animated_user_marker.dart';
import 'package:monamie_app/domain/models/location_point.dart';
import 'package:monamie_app/domain/models/user_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:monamie_app/domain/models/sharing_times.dart';
import 'package:monamie_app/ui/home/view_models/tracking_toggle_view_model.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

/// The map of the home screen: the markers of the observed group, the
/// person's own position, the highlighted trails and the sharing switch.
///
/// Each value is its own [ValueListenable] and notifies only when it
/// changes: lists, sets and maps are replaced whole, never changed in
/// place. Whoever creates it calls [start] once, which reads the person's
/// profile and begins listening to the organization's repositories, and
/// [dispose] once, which removes every listener and cancels every timer and
/// trail subscription.
class TrackingViewModel implements TrackingToggleViewModel {
  /// [notices] shows the warnings raised by background changes, which no
  /// screen is waiting for. [memberships] (capabilities, the observed group
  /// and its positions), [observedDay] (the day the map shows) and
  /// [permissions] are the organization's shared state this one reacts to;
  /// [profiles] reads the profile saved at sign-in. [startSharing] turns
  /// sharing on. The data layer comes in too: [service] (the tracking
  /// service), [location] (the GPS) and [positions] (the groups' positions
  /// and trails).
  TrackingViewModel({
    required this._notices,
    required this._memberships,
    required this._observedDay,
    required this._permissions,
    required this._profiles,
    required this._startSharing,
    required this._service,
    required this._location,
    required this._positions,
  });

  final NoticePresenter _notices;
  final MembershipRepository _memberships;
  final ObservedDayRepository _observedDay;
  final PermissionsRepository _permissions;
  final UserGoogleRepository _profiles;
  final StartSharing _startSharing;
  final BackgroundTrackingService _service;
  final DeviceLocation _location;
  final PositionsRepository _positions;

  /// The signed-in person (e-mail and name) from the profile saved at
  /// sign-in, once read by [start]; `null` without one.
  UserModel? _user;

  /// The device's last known position; Niterói until a fix arrives.
  LatLng position = const LatLng(-22.9041, -43.1329);
  final _firebaseUsers = ValueNotifier<List<UserModel>>(const []);
  final _groupUsers = ValueNotifier<List<UserModel>>(const []);
  final _isTrackingEnabled = ValueNotifier<bool>(false);
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
  bool get isObservingToday => _observedDay.isObservingToday;

  /// The people with a marker on the map: those of [firebaseUsers] in the
  /// observed group; on a past day, only those with a historical position
  /// in [animatedMarkerPositions].
  List<UserModel> get markedUsers {
    final observed = {
      for (final member in _memberships.observedMembers.value) member.email,
    };
    return [
      for (final user in _firebaseUsers.value)
        if (observed.contains(user.email) &&
            (isObservingToday ||
                _animatedMarkerPositions.value.containsKey(user.email)))
          user,
    ];
  }

  /// Whether [email]'s place already shows among the group's markers (they
  /// share in a group they watch), so their own marker is not drawn.
  bool isDrawnWithTheGroup(String email) =>
      _memberships.observedMembers.value.any((m) => m.email == email) &&
      _firebaseUsers.value.any((u) => u.email == email);

  /// Whether [user]'s marker is faded at [now]: they stopped sharing, or
  /// their position is older than the validity.
  bool isFaded(UserModel user, DateTime now) =>
      user.isPublishing == false ||
      user.capturedAt == null ||
      now.difference(user.capturedAt!) >= validity;

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

  StreamSubscription<void>? _readySubscription;
  StreamSubscription<LatLng>? _locationSubscription;

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
      _onGroupPositions(_memberships.groupPositions.value);

  /// Recarrega trajetórias destacadas quando o dia observado muda.
  void _onObservedDayChanged() =>
      onObservedDayChanged(_observedDay.observedDay.value);

  /// Atualiza marcadores ao trocar de grupo (membros observados mudaram).
  void _onObservedMembersChanged() =>
      _refreshMarkersForObservedDay(_observedDay.observedDay.value);

  /// The person's capabilities arrive after this view model starts: look
  /// for the device again when they do.
  void _onCapabilitiesChanged() => _initPosition();

  /// The location permission arrives after this view model starts: look
  /// for the device again when it is granted.
  void _onWhenInUsePermissionChanged() {
    if (_permissions.hasWhenInUseLocationPermission.value) _initPosition();
  }

  /// Avisa se o app passou a ser restrito em segundo plano durante uma
  /// jornada ativa: o rastreamento vai parar quando o app sair da tela.
  void _onBackgroundRestrictedChanged() {
    if (_permissions.isBackgroundRestricted.value && _isTrackingEnabled.value) {
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
    final day = _observedDay.observedDay.value;
    final members = _memberships.highlightedObservedUsers.value;

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
    final groupId = _memberships.selectedGroup.value?.id;
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

    for (final member in _memberships.highlightedObservedUsers.value) {
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
    final groupId = _memberships.selectedGroup.value?.id;
    if (groupId == null) return;

    if (isObservingToday) {
      final observedEmails = _memberships.observedMembers.value
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
      for (final member in await _memberships.loadHistoryMembers())
        member.email,
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

      mapController.move(position, 15.0);
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

  /// Takes the observed group's positions (read by [MembershipRepository]).
  void _onGroupPositions(List<UserModel> users) {
    _setList(_groupUsers, users);
    _setList(
      _firebaseUsers,
      liveUsers(users, now: DateTime.now(), validity: validity),
    );
  }

  /// Reads the person's profile, starts listening to the organization's
  /// repositories, reads the observed group's positions, looks for the
  /// device and asks whether the tracking service is running. Only the
  /// first call does anything; every listener added here is removed in
  /// [dispose].
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;

    // Not awaited: the listeners below start at once, as before.
    _loadProfile();

    // The observed group's positions drive the markers and the list.
    _memberships.groupPositions.addListener(_onGroupPositionsChanged);

    // Avisa se o app passou a ser restrito em segundo plano durante uma
    // jornada ativa: o rastreamento vai parar quando o app sair da tela.
    _permissions.isBackgroundRestricted.addListener(
      _onBackgroundRestrictedChanged,
    );

    _onGroupPositions(_memberships.groupPositions.value);

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
    _memberships.highlightedObservedUsers.addListener(
      _onHighlightedUsersChanged,
    );

    // Observa mudanças no observedDay para recarregar trajetórias destacadas
    _observedDay.observedDay.addListener(_onObservedDayChanged);

    // Observa mudanças nos membros observados para atualizar marcadores ao trocar de grupo
    _memberships.observedMembers.addListener(_onObservedMembersChanged);

    _initPosition();
    // The person's capabilities and the location permission arrive after this
    // view model starts: look for the device again when they do.
    _memberships.capabilities.addListener(_onCapabilitiesChanged);
    _permissions.hasWhenInUseLocationPermission.addListener(
      _onWhenInUsePermissionChanged,
    );

    final running = await _service.isRunning();
    _set(_isTrackingEnabled, running);
  }

  /// Reads the profile saved at sign-in: the e-mail and name the tracking
  /// service publishes.
  Future<void> _loadProfile() async {
    try {
      final profile = await _profiles.getUserGoogleModel();
      final email = profile?.email ?? '';
      _user = email.isEmpty
          ? null
          : UserModel(email: email, name: profile?.name);
    } catch (e) {
      debugPrint('[TrackingViewModel] Could not read the profile: $e');
    }
    // The look at the device made by [start] skipped while the profile was
    // unread: a person who can share sees their position now.
    _initPosition();
  }

  /// Whether the person shares their location in some group (the same
  /// test as `UserViewModel.isTrackable`).
  bool get _isTrackable => _user != null && _memberships.canPublish;

  void _setPosition(LatLng value) {
    position = value;
    _set(_ownPosition, value);
  }

  bool _locating = false;

  Future<void> _initPosition() async {
    // One look at a time; only for people who can share.
    if (_disposed || _locating || !_isTrackable) return;
    _locating = true;
    try {
      _setPosition(
        await _location.currentPosition().timeout(const Duration(seconds: 5)),
      );
      // A person who only shares has no group on the map: show them.
      if (!_memberships.canWatch) {
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
  /// not start; ignores a call while another toggle is running.
  @override
  late final Command0<UserNotice?> toggleService = Command0(_toggleService);

  Future<Result<UserNotice?>> _toggleService() async {
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
    }
  }

  Future<Result<UserNotice?>> _startService() async {
    // Without the profile the service would have no one to publish as:
    // refuse before starting it.
    if (_user == null) {
      return const Err(
        'Não foi possível alterar o compartilhamento agora. Tente de novo.',
        title: 'Compartilhamento',
      );
    }
    final result = await _startSharing(onPosition: _setPosition);
    final SharingStart started;
    switch (result) {
      case Err(:final message, :final title, :final error, :final stackTrace):
        return Err(message, title: title, error: error, stackTrace: stackTrace);
      case Ok(:final value) when !value.started:
        return const Ok(null);
      case Ok(:final value):
        started = value;
    }

    await _readySubscription?.cancel();
    await _locationSubscription?.cancel();

    // Este listener ouve o serviço em foreground avisar que está pronto para
    // receber informações do usuário.
    _readySubscription = _service.ready.listen((_) {
      _service.sendUser(email: _user!.email, name: _user!.publishedName);
    });

    // Este listener ouve atualizações da posição por parte do serviço em
    // foreground.
    _locationSubscription = _service.localPositions.listen(
      _setPosition,
      // A malformed event from the service skips one fix; the next one
      // moves the marker again.
      onError: (Object e) =>
          debugPrint('[TrackingViewModel] Unreadable local position: $e'),
    );

    // Atualiza UI (botão).
    _set(_isTrackingEnabled, true);

    // Registra imediatamente que o usuário atual possui ponto no dia de hoje
    _addUserWithPoints(_user!.email);

    // The service turns `isPublishing` on in every group and publishes the
    // positions: this screen writes nothing while sharing.
    return Ok(started.notice);
  }

  Future<void> _stopService() async {
    await _readySubscription?.cancel();
    _readySubscription = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _service.stop();
    _set(_isTrackingEnabled, false);
    try {
      await _positions.markNotPublishing(_user!.email);
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
    _memberships.groupPositions.removeListener(_onGroupPositionsChanged);
    _memberships.highlightedObservedUsers.removeListener(
      _onHighlightedUsersChanged,
    );
    _observedDay.observedDay.removeListener(_onObservedDayChanged);
    _memberships.observedMembers.removeListener(_onObservedMembersChanged);
    _memberships.capabilities.removeListener(_onCapabilitiesChanged);
    _permissions.isBackgroundRestricted.removeListener(
      _onBackgroundRestrictedChanged,
    );
    _permissions.hasWhenInUseLocationPermission.removeListener(
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
      toggleService,
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
