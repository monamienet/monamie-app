import 'package:monamie_app/app/modules/login/controllers/sign_in_actions.dart';
import 'package:monamie_app/app/modules/login/services/google_bond_check.dart';
import 'package:monamie_app/app/modules/login/services/stored_google_bond_check.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/result.dart';

class LoginController extends GetxController {
  /// [signIn] runs the sign-in and sign-out (the `AuthGoogleController`);
  /// [bondCheck] tells whether a sign-in survives from a previous run,
  /// [StoredGoogleBondCheck] by default.
  LoginController({required this._signIn, GoogleBondCheck? bondCheck})
    : _injectedBondCheck = bondCheck;

  final SignInActions _signIn;
  final GoogleBondCheck? _injectedBondCheck;

  // Created on first use: the default reads Firebase and Hive.
  late final GoogleBondCheck _bondCheck =
      _injectedBondCheck ?? StoredGoogleBondCheck();

  /// `true` enquanto verifica se há uma sessão válida para restaurar.
  final isRestoringSession = true.obs;

  /// Restaura a sessão quando o app é recriado do zero — por exemplo, depois
  /// que o Android encerra o processo enquanto o usuário está nas
  /// configurações do sistema. Sem isso o usuário precisaria logar de novo.
  @override
  Future<void> onReady() async {
    super.onReady();
    try {
      if (await hasActiveGoogleBond()) {
        Get.offNamed(Routes.MONAMIE);
      }
    } finally {
      isRestoringSession.value = false;
    }
  }

  /// See [GoogleBondCheck.hasActiveBond].
  Future<bool> hasActiveGoogleBond() => _bondCheck.hasActiveBond();

  /// See [SignInActions.loginGoogle].
  Future<Result<void>> loginGoogle() => _signIn.loginGoogle();

  /// See [SignInActions.logout].
  Future<Result<bool>> logoutGoogle() => _signIn.logout();
}
