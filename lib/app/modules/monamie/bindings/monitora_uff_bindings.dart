import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/call_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:get/get.dart';

class MonitoraUffBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
    Get.lazyPut<TrackingController>(() => TrackingController());
    Get.lazyPut<PermissionsController>(() => PermissionsController());
    Get.lazyPut(() => AuthGoogleController());
    Get.lazyPut(() => GoogleGroupsController());
    Get.lazyPut(() => CalendarController());
    Get.lazyPut(() => CallController());
  }
}
