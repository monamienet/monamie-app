import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/models/gdi_groups_model.dart';
import 'package:monamie_app/app/data/models/user_data.dart';
import 'package:monamie_app/app/data/provider/user_data_provider.dart';

class UserDataRepository {
  final UserDataProvider _userDataProvider = UserDataProvider();
  //final SaciService saciService = SaciService();

  UserDataRepository() {
    debugPrint("Creating User Data Repo");
  }

  Future<String> saveUserData(UserData userData) async {
    return await _userDataProvider.saveUserData(userData);
  }

  Future<UserData?> getUserData() async {
    return await _userDataProvider.getUserData();
  }

  Future<String> deleteUserData() async {
    return await _userDataProvider.deleteUserData();
  }

  Future<String> clearAllUserData() async {
    return await _userDataProvider.clearAllUserData();
  }

  Future<bool> hasUserData() async {
    return await _userDataProvider.hasUserData();
  }

  Future<String> updateQrData(String textoQrCodeCarteirinha) async {
    return await _userDataProvider.updateQrData(textoQrCodeCarteirinha);
  }

  Future<String> updateShortcutRoutes(List<String> shortcutRoutes) async {
    return await _userDataProvider.updateShortcutRoutes(shortcutRoutes);
  }

  Future<String> updateGdiGroupsGoogle(GdiGroupsGoogle gdiGroupsGoogle) async {
    return await _userDataProvider.updateGdiGroupsGoogle(gdiGroupsGoogle);
  }

  Future<String> lastRegisteredTokenCdcUpdate(DateTime lastRegisteredTokenCdcUpdate) async {
    return await _userDataProvider.lastRegisteredTokenCdcUpdate(lastRegisteredTokenCdcUpdate);
  }

  Future<List<GdiGroups>> getGdiGroups(String iduff, String token) async {
    return await _userDataProvider.getGdiGroups(iduff, token);
  }

  // Future<List<dynamic>> getSaciData(String? token, String? iduffUsuario, AuthIduffService auth) async {
    // return await saciService.getSaciData(token, iduffUsuario, auth);
  // }
}
