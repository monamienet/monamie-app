import 'package:monamie_app/app/modules/login/bindings/login_binding.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/call_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/ui/dialog_permission_prompts.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';

class MonamieBindings implements Bindings {
  @override
  void dependencies() {
    // The factories run on first use, so each one can find the others no
    // matter the order they are registered in.
    Get.lazyPut<UserController>(
      () => UserController(groupMap: Get.find<GroupMapState>()),
    );
    Get.lazyPut<TrackingController>(
      () => TrackingController(
        notices: const ScaffoldNoticePresenter(),
        userCtrl: Get.find<UserController>(),
        permissionsCtrl: Get.find<PermissionsController>(),
        calendar: Get.find<CalendarController>(),
        groupMap: Get.find<GroupMapState>(),
      ),
    );
    Get.lazyPut<PermissionsController>(
      () => PermissionsController(
        prompts: const DialogPermissionPrompts(),
        notices: const ScaffoldNoticePresenter(),
      ),
    );
    ensureAuthGoogleController();
    // Registered under its contract: screens and controllers find
    // [GroupMapState], never the Firestore-backed class.
    Get.lazyPut<GroupMapState>(
      () => GroupMapController(
        onAccessLost: () =>
            Get.find<AuthGoogleController>().forgetRemovedOrganization(),
      ),
    );
    Get.lazyPut(() => CalendarController(groupMap: Get.find<GroupMapState>()));
    Get.lazyPut(() => CallController());
    // Created with the home screen, not on first use: it must already hold
    // the saved settings when *Ajustes de acompanhamento* opens, and a lazy
    // instance first built inside that route would be deleted, factory and
    // all, when the route closes.
    Get.put(TrackingSettingsController());
  }
}
