import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';

import '../controllers/login_controller.dart';

/// Registers the [AuthGoogleController] once for the whole app and starts
/// it (web sign-in listener, Google Sign-In initialization). Permanent:
/// MonAmie's screens after sign-in (*Sem organização*, the picker) replace
/// the login route but still read its state, and so does the home screen.
void ensureAuthGoogleController() {
  if (Get.isRegistered<AuthGoogleController>()) return;
  Get.put(
    AuthGoogleController(notices: const ScaffoldNoticePresenter())..start(),
    permanent: true,
  );
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // Lazy: the factory runs after AuthGoogleController is registered below.
    // *Login* restores a remembered session when it opens.
    Get.lazyPut<LoginController>(
      () => LoginController(signIn: Get.find<AuthGoogleController>()),
    );
    ensureAuthGoogleController();
  }
}
