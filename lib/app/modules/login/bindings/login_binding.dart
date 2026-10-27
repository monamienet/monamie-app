import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
    // Permanent: MonAmie's screens after sign-in (*Sem organização*, the
    // picker) replace the login route but still read its state.
    if (!Get.isRegistered<AuthGoogleController>()) {
      Get.put(AuthGoogleController(), permanent: true);
    }
  }
}
