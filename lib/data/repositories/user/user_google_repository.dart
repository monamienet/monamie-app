import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/services/user_profile_hive_service.dart';

/// The signed-in person's Google profile on the device, read and kept
/// through [UserProfileHiveService].
class UserGoogleRepository {
  UserGoogleRepository({required this._service});

  final UserProfileHiveService _service;

  Future<UserGoogleModel> saveGoogleProfile(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) async {
    UserGoogleModel user = await _service.saveGoogleProfile(
      email,
      name,
      uid,
      urlImage,
      avatarBase64: avatarBase64,
    );

    return user;
  }

  Future<String> saveUserGoogleModel(UserGoogleModel user) {
    return _service.saveUserGoogleModel(user);
  }

  Future<UserGoogleModel?> getUserGoogleModel() {
    return _service.getUserGoogleModel();
  }

  Future<String> deleteUserGoogleModel() {
    return _service.deleteUserGoogleModel();
  }

  Future<String> clearAllUserGoogle() {
    return _service.clearAllUserGoogle();
  }

  Future<bool> hasUserGoogle() {
    return _service.hasUserGoogle();
  }
}
