// Route names keep the get_cli style until go_router replaces them (#196).
// ignore_for_file: constant_identifier_names
import 'package:monamie_app/app/modules/monamie/bindings/monamie_bindings.dart';
import 'package:monamie_app/app/modules/monamie/ui/monamie_page.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/data/organization/organization_session.dart';
import 'package:monamie_app/app/data/tracking/firestore_tracking_settings_repository.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/app/modules/admin/appearance_controller.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_edit_controller.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_view.dart';
import 'package:monamie_app/app/modules/admin/appearance_view.dart';
import 'package:monamie_app/app/modules/admin/groups/firebase_groups_backend.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_controller.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_views.dart';
import 'package:monamie_app/app/modules/admin/firebase_appearance_backend.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_controller.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_view.dart';
import 'package:monamie_app/app/modules/admin/administrators/firebase_administrators_backend.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';

import 'package:monamie_app/app/modules/account/deletion_pending_view.dart';
import 'package:monamie_app/app/modules/account/firebase_account_deletion_backend.dart';
import 'package:monamie_app/app/modules/account/my_account_controller.dart';
import 'package:monamie_app/app/modules/account/my_account_view.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';

import '../modules/login/bindings/login_binding.dart';
import '../modules/login/controllers/login_controller.dart';
import '../modules/login/views/login_view.dart';
import '../modules/invites/welcome_view.dart';
import '../modules/login/views/no_organization_view.dart';
import '../modules/login/views/organization_picker_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginView(
        controller: Get.find<LoginController>(),
        auth: Get.find<AuthGoogleController>(),
      ),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.ORGANIZATION_PICKER,
      page: () =>
          OrganizationPickerView(controller: Get.find<AuthGoogleController>()),
    ),
    GetPage(
      name: _Paths.WELCOME,
      page: () => WelcomeView(controller: Get.find<AuthGoogleController>()),
    ),
    GetPage(
      name: _Paths.DELETION_PENDING,
      page: () =>
          DeletionPendingView(controller: Get.find<AuthGoogleController>()),
    ),
    GetPage(
      name: _Paths.MY_ACCOUNT,
      page: () => MyAccountView(
        controller: Get.put(
          MyAccountController(
            backend: const FirebaseAccountDeletionBackend(),
            organizationId: Organization.current!.id,
            checkOwner: () => Get.find<AuthGoogleController>().ownsOrganization(
              Organization.current!.id,
            ),
            onDeleted: Get.find<AuthGoogleController>().accountDeleted,
          ),
        ),
        email: Get.find<UserController>().googleUser?.email ?? '',
        organizationName: Organization.current!.name,
      ),
    ),
    GetPage(
      name: _Paths.NO_ORGANIZATION,
      page: () =>
          NoOrganizationView(controller: Get.find<AuthGoogleController>()),
    ),
    GetPage(
      name: _Paths.TRACKING_SETTINGS,
      page: () => TrackingSettingsView(
        controller: Get.put(
          TrackingSettingsEditController(
            repository: const FirestoreTrackingSettingsRepository(),
            saved: Get.find<TrackingSettingsController>().settings.value,
          ),
        ),
      ),
    ),
    GetPage(
      name: _Paths.GROUPS,
      page: () => GroupsView(
        controller: Get.put(
          GroupsController(
            organizationId: Organization.current!.id,
            backend: const FirebaseGroupsBackend(),
            isAdmin: Get.find<GroupMapState>().isAdmin,
          ),
        ),
      ),
    ),
    GetPage(
      name: _Paths.ADMINISTRATORS,
      page: () => AdministratorsView(
        controller: Get.put(
          AdministratorsController(
            organizationId: Organization.current!.id,
            backend: const FirebaseAdministratorsBackend(),
          ),
        ),
      ),
    ),
    GetPage(
      name: _Paths.APPEARANCE,
      page: () => AppearanceView(
        controller: Get.put(
          AppearanceController(
            organization: Organization.current!,
            backend: FirebaseAppearanceBackend(),
            onSaved: OrganizationSession().storeBranding,
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
