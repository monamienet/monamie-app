import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_state.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

export 'user_state.dart';

/// The signed-in person (e-mail, name, avatar), from the profile saved at
/// sign-in. Their positions are written by the tracking service, one per
/// group where they publish; nothing is created here.
///
/// Whoever creates it calls [start] once, which reads the profile, and
/// [dispose] once.
class UserController extends ChangeNotifier {
  /// [groupMap] says whether the person publishes in some group;
  /// [repository] reads the profile saved at sign-in (Hive),
  /// [UserGoogleRepository] by default.
  UserController({required this._groupMap, UserGoogleRepository? repository})
    : _injectedRepository = repository;

  final GroupMapState _groupMap;
  final UserGoogleRepository? _injectedRepository;

  late final UserGoogleRepository _repository =
      _injectedRepository ?? UserGoogleRepository();

  UserState _state = const UserState();
  bool _started = false;
  bool _disposed = false;

  /// What the screens show; replaced whole, never changed in place.
  UserState get state => _state;

  UserModel? get user => _state.user;
  UserGoogleModel? get googleUser => _state.googleUser;
  bool get isLoading => _state.isLoading;

  /// Replaces the state, notifying only when it differs.
  void _emit(UserState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  /// Reads the profile. Only the first call does anything.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    _emit(_state.copyWith(isLoading: true));
    try {
      final googleUser = await _repository.getUserGoogleModel();
      debugPrint('Hive user: ${googleUser?.email} / ${googleUser?.name}');
      final email = googleUser?.email ?? '';
      _emit(
        _state.copyWith(
          googleUser: googleUser,
          user: email.isEmpty
              ? null
              : UserModel(email: email, name: googleUser?.name),
        ),
      );
    } finally {
      _emit(_state.copyWith(isLoading: false));
    }
  }

  /// Whether the person shares their location in some group, so the map
  /// shows the sharing switch.
  bool isTrackable() => _state.user?.email != null && _groupMap.canPublish;

  String getUserName() {
    final name = user?.name?.trim();
    return name == null || name.isEmpty ? 'Nome não informado' : name;
  }

  /// Only the first call does anything.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
