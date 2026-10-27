import 'package:monamie_app/app/modules/monamie/bindings/monamie_bindings.dart';
import 'package:monamie_app/app/modules/monamie/ui/monamie_page.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/data/partner/partner_session.dart';
import 'package:monamie_app/app/modules/admin/appearance_controller.dart';
import 'package:monamie_app/app/modules/admin/appearance_view.dart';
import 'package:monamie_app/app/modules/admin/firebase_appearance_backend.dart';

import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/login/views/not_linked_view.dart';
import '../modules/login/views/partner_picker_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(name: _Paths.PARTNER_PICKER, page: () => const PartnerPickerView()),
    GetPage(name: _Paths.NOT_LINKED, page: () => const NotLinkedView()),
    GetPage(
      name: _Paths.APPEARANCE,
      page: () => AppearanceView(
        controller: Get.put(
          AppearanceController(
            partner: Partner.current!,
            backend: FirebaseAppearanceBackend(),
            onSaved: PartnerSession().storeBranding,
          ),
        ),
      ),
    ),
    GetPage(
      name: _Paths.MONAMIE,
      page: () => const MonamiePage(),
      binding: MonamieBindings(),
    ),
  ];
}
