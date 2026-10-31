import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:get/get.dart';

/// The signed-in person (e-mail, name, avatar), from the profile saved at
/// sign-in. Their positions are written by the tracking service, one per
/// group where they publish; nothing is created here.
class UserController extends GetxController {
  final _user = Rxn<UserModel>();
  UserModel? get user => _user.value;

  final _googleUser = Rxn<UserGoogleModel>();
  UserGoogleModel? get googleUser => _googleUser.value;

  final isLoading = true.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    isLoading.value = true;
    try {
      final googleUser = await UserGoogleRepository().getUserGoogleModel();
      debugPrint('Hive user: ${googleUser?.email} / ${googleUser?.name}');
      _googleUser.value = googleUser;
      final email = googleUser?.email ?? '';
      _user.value = email.isEmpty
          ? null
          : UserModel(email: email, name: googleUser?.name);
    } finally {
      isLoading.value = false;
    }
  }

  /// Whether the person shares their location in some group, so the map
  /// shows the sharing switch.
  bool isTrackable() =>
      _user.value?.email != null && Get.find<GroupMapState>().canPublish;

  String getUserName() {
    final name = user?.name?.trim();
    return name == null || name.isEmpty ? 'Nome não informado' : name;
  }
}
