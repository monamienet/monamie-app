import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/provider/user_google_provider.dart';

class UserGoogleRepository {
  final UserGoogleProvider _provider = UserGoogleProvider();

  Future<UserGoogleModel> saveGoogleProfile(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) async {
    UserGoogleModel user = await _provider.saveGoogleProfile(
      email,
      name,
      uid,
      urlImage,
      avatarBase64: avatarBase64,
    );

    return user;
  }

  Future<String> saveUserGoogleModel(UserGoogleModel user) {
    return _provider.saveUserGoogleModel(user);
  }

  Future<UserGoogleModel?> getUserGoogleModel() {
    return _provider.getUserGoogleModel();
  }

  Future<String> deleteUserGoogleModel() {
    return _provider.deleteUserGoogleModel();
  }

  Future<String> clearAllUserGoogle() {
    return _provider.clearAllUserGoogle();
  }

  Future<bool> hasUserGoogle() {
    return _provider.hasUserGoogle();
  }
}
