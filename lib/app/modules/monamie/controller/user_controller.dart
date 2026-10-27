import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/data/services/monamie_claims_service.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  final _user = Rxn<UserModel>();
  UserModel? get user => _user.value;

  final _googleUser = Rxn<UserGoogleModel>();
  UserGoogleModel? get googleUser => _googleUser.value;

  String? _googleName;
  final isLoading = true.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadCurrentUser();
  }

  /// Whether the claims let the person share their location in a team.
  Future<bool> _canShareFromClaims() async =>
      (await MonAmieClaimsService.readClaims())?.canShare ?? false;

  Future<void> loadCurrentUser() async {
    isLoading.value = true;
    try {
      final googleUser = await UserGoogleRepository().getUserGoogleModel();
      debugPrint('Hive user: ${googleUser?.email} / ${googleUser?.name}');
      _googleUser.value = googleUser;
      _googleName = googleUser?.name;
      final email = googleUser?.email ?? "";

      if (email.isEmpty) {
        _user.value = null;
        return;
      }

      // Tentar carregar do Firestore
      var firestoreUser = await _initializeUser();
      if (firestoreUser != null) {
        _user.value = firestoreUser;
      } else {
        // Only people who share in a team get a document in `usuarios`:
        // the collection holds the positions of people in the field.
        if (await _canShareFromClaims()) {
          await FirebaseProvider().setUser(
            UserModel(email: email, nome: _googleName),
          );
          _user.value = await _initializeUser();
        } else {
          debugPrint('$email shares in no team: no document in `usuarios`.');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<UserModel?> _initializeUser() async {
    final googleUser = await UserGoogleRepository().getUserGoogleModel();
    _googleUser.value = googleUser;
    final email = googleUser?.email ?? "";
    debugPrint('Email usado no lookup: $email');
    if (email.isEmpty) return null;

    final user = await FirebaseProvider().getUserByEmail(email);
    return user;
  }

  /// Whether the person shares their location in some team, so the map
  /// shows the sharing switch.
  bool isTrackable() =>
      _user.value?.email != null &&
      Get.find<GoogleGroupsController>().capabilities.value.canShare;

  String getUserName() {
    return user!.nome ?? _googleName ?? "Nome não informado";
  }
}
