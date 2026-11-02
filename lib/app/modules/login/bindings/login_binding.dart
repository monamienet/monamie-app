import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';

import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // Lazy: the factory runs after AuthGoogleController is registered below.
    Get.lazyPut<LoginController>(
      () => LoginController(signIn: Get.find<AuthGoogleController>()),
    );
    // Permanent: MonAmie's screens after sign-in (*Sem organização*, the
    // picker) replace the login route but still read its state.
    if (!Get.isRegistered<AuthGoogleController>()) {
      Get.put(
        AuthGoogleController(notices: const ScaffoldNoticePresenter()),
        permanent: true,
      );
    }
  }
}
