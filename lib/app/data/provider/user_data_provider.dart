import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monamie_app/app/config/secrets.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/models/gdi_groups_model.dart';
import 'package:monamie_app/app/data/models/user_data.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class UserDataProvider {
  final String _collectionPath = "user_data";
  final String _userKey = "current_user";

  UserDataProvider() {
    debugPrint("Started User Data provider");
  }

 Future<String> saveUserData(UserData newUserData) async {
  try {
    var box = await Hive.openBox<UserData>(_collectionPath);
    
    UserData? existingData = box.get(_userKey);

    UserData dataToSave;

    if (existingData != null) {
      dataToSave = existingData.copyWith(
        name: newUserData.name ?? existingData.name,
        nomesocial: newUserData.nomesocial ?? existingData.nomesocial,
        matricula: newUserData.matricula ?? existingData.matricula,
        iduff: newUserData.iduff ?? existingData.iduff,
        curso: newUserData.curso ?? existingData.curso,
        fotoUrl: newUserData.fotoUrl ?? existingData.fotoUrl,
        dataValidadeMatricula: newUserData.dataValidadeMatricula ?? existingData.dataValidadeMatricula,
        bond: newUserData.bond ?? existingData.bond,
        textoQrCodeCarteirinha: newUserData.textoQrCodeCarteirinha ?? existingData.textoQrCodeCarteirinha,
        accessToken: newUserData.accessToken ?? existingData.accessToken,
        bondId: newUserData.bondId ?? existingData.bondId,
        gdiGroups: newUserData.gdiGroups ?? existingData.gdiGroups,
        profileType: newUserData.profileType ?? existingData.profileType,
        shortcutRoutes: newUserData.shortcutRoutes ?? existingData.shortcutRoutes,
        gdiGroupsGoogle: newUserData.gdiGroupsGoogle ?? existingData.gdiGroupsGoogle,
        lastRegisteredTokenCdcUpdate: newUserData.lastRegisteredTokenCdcUpdate ?? existingData.lastRegisteredTokenCdcUpdate,
        

      );
    } else {
      dataToSave = newUserData;
    }

    await box.put(_userKey, dataToSave);
    return "success";
  } catch (e) {
    throw Exception("Erro ao salvar dados do usuário no Hive: $e");
  }
}

  Future<UserData?> getUserData() async {
    try {
      var box = await Hive.openBox<UserData>(_collectionPath);
      return box.get(_userKey);
    } catch (e) {
      return null;
    }
  }

  Future<String> deleteUserData() async {
    try {
      var box = await Hive.openBox<UserData>(_collectionPath);
      await box.delete(_userKey);
      return "success";
    } catch (e) {
      return "Erro ao deletar dados do usuário do Hive: $e";
    }
  }

  Future<String> clearAllUserData() async {
    try {
      var box = await Hive.openBox<UserData>(_collectionPath);
      await box.clear();
      return "success";
    } catch (e) {
      return "Erro ao limpar dados do usuário do Hive: $e";
    }
  }

  Future<bool> hasUserData() async {
    try {
      var box = await Hive.openBox<UserData>(_collectionPath);
      return box.containsKey(_userKey);
    } catch (e) {
      debugPrint("Erro ao verificar existência de dados do usuário: $e");
      return false;
    }
  }

  Future<String> updateQrData(String textoQrCodeCarteirinha) async {
    try {
      var box = await Hive.openBox<UserData>(_collectionPath);
      UserData? user = box.get(_userKey);

      if (user == null) {
        await saveUserData(UserData(textoQrCodeCarteirinha: textoQrCodeCarteirinha));
        return "success";
      }

      // altera o campo diretamente e salva
      user.textoQrCodeCarteirinha = textoQrCodeCarteirinha;
      await user.save(); // persiste o objeto atualizado
      return textoQrCodeCarteirinha;
    } catch (e) {
      return "Erro ao atualizar status de login no Hive: $e";
    }
  }

  Future<String> updateShortcutRoutes(List<String> shortcutRoutes) async {
    try {
      var box = await Hive.openBox<UserData>(_collectionPath);
      UserData? user = box.get(_userKey);

      if (user == null) {
        await saveUserData(UserData(shortcutRoutes: List<String>.from(shortcutRoutes)));
        return "success";
      }

      user.shortcutRoutes = List<String>.from(shortcutRoutes);
      await user.save();
      return "success";
    } catch (e) {
      return "Erro ao atualizar atalhos no Hive: $e";
    }
  }

  Future<String> updateGdiGroupsGoogle(GdiGroupsGoogle gdiGroupsGoogle) async {
    try {
      var box = await Hive.openBox<UserData>(_collectionPath);
      UserData? user = box.get(_userKey);

      if (user == null) {
        await saveUserData(UserData(gdiGroupsGoogle: gdiGroupsGoogle));
        return "success";
      }

      // altera o campo diretamente e salva
      user.gdiGroupsGoogle = gdiGroupsGoogle;
      await user.save(); // persiste o objeto atualizado
      return "success";
    } catch (e) {
      return "Erro ao atualizar grupos GDI Google no Hive: $e";
    }
  }

  Future<String> lastRegisteredTokenCdcUpdate(DateTime lastRegisteredTokenCdcUpdate) async {
    try {
      var box = await Hive.openBox<UserData>(_collectionPath);
      UserData? user = box.get(_userKey);

      if (user == null) {
        await saveUserData(UserData(lastRegisteredTokenCdcUpdate: lastRegisteredTokenCdcUpdate));
        return "success";
      }

      // altera o campo diretamente e salva
      user.lastRegisteredTokenCdcUpdate = lastRegisteredTokenCdcUpdate;
      await user.save(); // persiste o objeto atualizado
      return "success";
    } catch (e) {
      return "Erro ao atualizar grupos GDI Google no Hive: $e";
    }
  }

  Future<List<GdiGroups>> getGdiGroups(String iduff, String token) async {
    final path = '${Secrets.gdiGroupsPath}/$iduff${Secrets.gdiGroupsQuery}';
    var uri = Uri.https(Secrets.gdiGroupsHost, path);
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((group) => GdiGroups.fromJson(group)).toList();
      }
    } catch (e) {
      debugPrint("Erro ao buscar grupos GDI: $e");
      return [];
    }
    return [];
  }
}
