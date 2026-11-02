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
    // GetX never starts nor disposes what is not a GetxController: the
    // factories below start each one once, and this scope disposes them
    // when GetX deletes the home route's instances (as it called their
    // onClose before).
    final scope = Get.put(_HomeScope());
    // The factories run on first use, so each one can find the others no
    // matter the order they are registered in.
    Get.lazyPut<UserController>(
      () => scope.own(
        UserController(groupMap: Get.find<GroupMapState>()),
        (c) => c.dispose(),
      )..start(),
    );
    Get.lazyPut<TrackingController>(
      () => scope.own(
        TrackingController(
          notices: const ScaffoldNoticePresenter(),
          userCtrl: Get.find<UserController>(),
          permissionsCtrl: Get.find<PermissionsController>(),
          calendar: Get.find<CalendarController>(),
          groupMap: Get.find<GroupMapState>(),
        ),
        (c) => c.dispose(),
      )..start(),
    );
    Get.lazyPut<PermissionsController>(
      () => scope.own(
        PermissionsController(
          prompts: const DialogPermissionPrompts(),
          notices: const ScaffoldNoticePresenter(),
        ),
        (c) => c.dispose(),
      )..start(),
    );
    ensureAuthGoogleController();
    // Registered under its contract: screens and controllers find
    // [GroupMapState], never the Firestore-backed class.
    Get.lazyPut<GroupMapState>(
      () => scope.own<GroupMapController>(
        GroupMapController(
          onAccessLost: () =>
              Get.find<AuthGoogleController>().forgetRemovedOrganization(),
        ),
        (c) => c.dispose(),
      )..start(),
    );
    Get.lazyPut(
      () => scope.own(
        CalendarController(groupMap: Get.find<GroupMapState>()),
        (c) => c.dispose(),
      ),
    );
    // Holds no state: nothing to start or dispose.
    Get.lazyPut(() => CallController());
    // Created with the home screen, not on first use: it must already hold
    // the saved settings when *Ajustes de acompanhamento* opens, and a lazy
    // instance first built inside that route would be deleted, factory and
    // all, when the route closes.
    // An instance already registered is kept, as Get.put does (and it was
    // started when it was registered).
    if (!Get.isRegistered<TrackingSettingsController>()) {
      Get.put(
        scope.own(TrackingSettingsController(), (c) => c.dispose())..start(),
      );
    }
  }
}

/// Disposes the home controllers (none of them a GetxController) when GetX
/// deletes the home route's instances (on sign-out or organization switch),
/// the moment it used to call their onClose. Until the organization scope
/// of phase 8 owns them.
class _HomeScope extends GetxController {
  final List<void Function()> _disposers = [];

  /// Records [disposer] for [controller] and returns [controller].
  T own<T>(T controller, void Function(T) disposer) {
    _disposers.add(() => disposer(controller));
    return controller;
  }

  @override
  void onClose() {
    // Latest first, so a controller goes before the ones it listens to.
    for (final dispose in _disposers.reversed) {
      dispose();
    }
    _disposers.clear();
    super.onClose();
  }
}
