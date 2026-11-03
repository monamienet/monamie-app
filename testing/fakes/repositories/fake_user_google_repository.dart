import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';

import 'fake_outcomes.dart';

/// [UserGoogleRepository] over one in-memory [user], instead of Hive.
class FakeUserGoogleRepository
    with FakeOutcomes
    implements UserGoogleRepository {
  FakeUserGoogleRepository({this.user});

  /// The Google profile kept on the "device", or `null`.
  UserGoogleModel? user;

  @override
  Future<UserGoogleModel> saveGoogleProfile(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) =>
      run('saveGoogleProfile', [email, name, uid, urlImage, avatarBase64], () {
        final saved = UserGoogleModel(
          id: uid,
          name: name,
          email: email,
          urlImage: urlImage,
          avatarBase64: avatarBase64,
        );
        user = saved;
        return saved;
      });

  @override
  Future<String> saveUserGoogleModel(UserGoogleModel model) =>
      run('saveUserGoogleModel', [model], () {
        user = model;
        return 'success';
      });

  @override
  Future<UserGoogleModel?> getUserGoogleModel() =>
      run('getUserGoogleModel', const [], () => user);

  @override
  Future<String> deleteUserGoogleModel() =>
      run('deleteUserGoogleModel', const [], () {
        user = null;
        return 'success';
      });

  @override
  Future<String> clearAllUserGoogle() =>
      run('clearAllUserGoogle', const [], () {
        user = null;
        return 'success';
      });

  @override
  Future<bool> hasUserGoogle() =>
      run('hasUserGoogle', const [], () => user != null);
}
