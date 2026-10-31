import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/call_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';

class MonamieBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
    Get.lazyPut<TrackingController>(() => TrackingController());
    Get.lazyPut<PermissionsController>(() => PermissionsController());
    if (!Get.isRegistered<AuthGoogleController>()) {
      Get.put(AuthGoogleController(), permanent: true);
    }
    // Registered under its contract: screens and controllers find
    // [GroupMapState], never the Firestore-backed class.
    Get.lazyPut<GroupMapState>(() => GroupMapController());
    Get.lazyPut(() => CalendarController());
    Get.lazyPut(() => CallController());
    // Created with the home screen, not on first use: it must already hold
    // the saved settings when *Ajustes de acompanhamento* opens, and a lazy
    // instance first built inside that route would be deleted, factory and
    // all, when the route closes.
    Get.put(TrackingSettingsController());
  }
}
