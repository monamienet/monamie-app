import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(),
    );
    Get.lazyPut(()=>AuthGoogleController());
  }
}
