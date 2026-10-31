import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:hive/hive.dart';

enum UserRole { user }

/// The signed-in person's Google profile, kept on the device (Hive): the
/// login reads it back (for example, the e-mail of who signed in).
class UserGoogleProvider {
  final String _hiveBox = 'user_google_data';
  final String _hiveKey = 'current_user';

  /// Builds the profile from the Google account and keeps it on the device.
  Future<UserGoogleModel> saveGoogleProfile(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) async {
    final user = UserGoogleModel(
      name: name,
      email: email,
      id: uid,
      urlImage: urlImage,
      createdAt: DateTime.now(),
      avatarBase64: avatarBase64,
    );
    await saveUserGoogleModel(user);
    return user;
  }

  Future<String> saveUserGoogleModel(UserGoogleModel user) async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      await box.put(_hiveKey, user);
      if (kDebugMode) {
        print('Saved Google user in Hive: ${user.email}');
      }
      return "success";
    } catch (e) {
      if (kDebugMode) {
        print('Error saving Google user in Hive: $e');
      }
      return "Erro ao salvar usuário Google no Hive: $e";
    }
  }

  Future<UserGoogleModel?> getUserGoogleModel() async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      final user = box.get(_hiveKey);
      if (kDebugMode) {
        print('Read Google user from Hive: ${user?.email}');
      }
      return user;
    } catch (e) {
      throw Exception("Erro ao buscar usuário Google do Hive: $e");
    }
  }

  Future<String> deleteUserGoogleModel() async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      await box.delete(_hiveKey);
      return "success";
    } catch (e) {
      return "Erro ao deletar usuário Google do Hive: $e";
    }
  }

  Future<String> clearAllUserGoogle() async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      await box.clear();
      return "success";
    } catch (e) {
      return "Erro ao limpar usuários Google do Hive: $e";
    }
  }

  Future<bool> hasUserGoogle() async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      return box.containsKey(_hiveKey);
    } catch (e) {
      return false;
    }
  }
}
