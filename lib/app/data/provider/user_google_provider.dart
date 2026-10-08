import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:hive/hive.dart';

enum UserRole { user }

class UserGoogleProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app()
  );
  final String _hiveBox = 'user_google_data';
  final String _hiveKey = 'current_user';

  Future<UserGoogleModel> createUserDoc(
    String email,
    String name,
    String uid,
    String urlImage,
    {String? avatarBase64}
  ) async {
    final docRef = _firestore.collection('users').doc(uid);
    final docSnapshot = await docRef.get();

    UserGoogleModel user;
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      user = UserGoogleModel(
        id: docSnapshot.id,
        name: data['name'] as String?,
        email: data['email'] as String,
        urlImage: data['urlImage'] as String?,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'] as String)
            : null,
        avatarBase64: data['avatarBase64'] as String? ?? avatarBase64,
      );
    } else {
      user = UserGoogleModel(
        name: name,
        email: email,
        id: uid,
        urlImage: urlImage,
        createdAt: DateTime.now(),
        avatarBase64: avatarBase64,
      );
      await createUserDocInFirebase(user);
    }

    await saveUserGoogleModel(user);
    return user;
  }

  Future<void> createUserDocInFirebase(UserGoogleModel user) async {
    await _firestore.collection('users').doc(user.id).set({
      'name': user.name,
      'email': user.email,
      'urlImage': user.urlImage,
      'createdAt': user.createdAt?.toIso8601String(),
    });
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
