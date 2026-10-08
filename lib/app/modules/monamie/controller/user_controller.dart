import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_member_model.dart';
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

  /// Verifica nos Custom Claims do token se o usuário é observável
  /// (MEMBER ou MANAGER em pelo menos um grupo MonAmie).
  /// Retorna false se os claims não estiverem definidos.
  Future<bool> _isObservavelFromClaims() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final idTokenResult = await user.getIdTokenResult();
    final claims = idTokenResult.claims;
    if (claims == null) return false;

    final groupRoles = claims['group_roles'];
    if (groupRoles == null || groupRoles is! Map) return false;

    // Observável se pelo menos um role é MEMBER ou MANAGER
    return groupRoles.values.any(
      (role) => role == 'MEMBER' || role == 'MANAGER',
    );
  }

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
        // Criar documento no Firestore APENAS se o usuário for observável.
        // A coleção `usuarios` existe exclusivamente para armazenar
        // coordenadas de observáveis (MEMBER/MANAGER).
        final isObservavel = await _isObservavelFromClaims();
        if (isObservavel) {
          await FirebaseProvider().setUser(UserModel(
            email: email,
            nome: _googleName,
          ));
          _user.value = await _initializeUser();
        } else {
          debugPrint(
            'Usuário $email não é observável — doc em `usuarios` não criado.',
          );
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

  bool isTrackable() {
    final googleGroupsCtrl = Get.find<GoogleGroupsController>();
    final currentUserEmail = _user.value?.email;

    if (currentUserEmail == null) return false;

    // Procura o usuário logado entre os membros do grupo observado
    final member = googleGroupsCtrl.observedMembers.firstWhereOrNull(
      (m) => m.email == currentUserEmail,
    );

    // Retorna true se for manager ou member (owner não conta como trackable)
    return member?.role == GoogleGroupRole.manager
      || member?.role == GoogleGroupRole.member;
  }

  String getUserName() {
    return user!.nome ??
        _googleName ??
        "Nome não informado";
  }
}
