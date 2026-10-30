import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/bindings/monamie_bindings.dart';
import 'package:monamie_app/app/modules/monamie/ui/monamie_page.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/data/partner/partner_session.dart';
import 'package:monamie_app/app/data/tracking/firestore_tracking_settings_repository.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/app/modules/admin/appearance_controller.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_edit_controller.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_view.dart';
import 'package:monamie_app/app/modules/admin/appearance_view.dart';
import 'package:monamie_app/app/modules/admin/teams/firebase_teams_backend.dart';
import 'package:monamie_app/app/modules/admin/teams/teams_controller.dart';
import 'package:monamie_app/app/modules/admin/teams/teams_views.dart';
import 'package:monamie_app/app/modules/admin/firebase_appearance_backend.dart';

import 'package:monamie_app/app/modules/account/deletion_pending_view.dart';
import 'package:monamie_app/app/modules/account/firebase_account_deletion_backend.dart';
import 'package:monamie_app/app/modules/account/my_account_controller.dart';
import 'package:monamie_app/app/modules/account/my_account_view.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';

import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/invites/welcome_view.dart';
import '../modules/login/views/no_organization_view.dart';
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
    GetPage(name: _Paths.WELCOME, page: () => const WelcomeView()),
    GetPage(
      name: _Paths.DELETION_PENDING,
      page: () => const DeletionPendingView(),
    ),
    GetPage(
      name: _Paths.MY_ACCOUNT,
      page: () => MyAccountView(
        controller: Get.put(
          MyAccountController(
            backend: const FirebaseAccountDeletionBackend(),
            partnerId: Partner.current!.id,
            checkOwner: () => Get.find<AuthGoogleController>().ownsPartner(
              Partner.current!.id,
            ),
            onDeleted: Get.find<AuthGoogleController>().accountDeleted,
          ),
        ),
        email: Get.find<UserController>().googleUser?.email ?? '',
        partnerName: Partner.current!.name,
      ),
    ),
    GetPage(
      name: _Paths.NO_ORGANIZATION,
      page: () => const NoOrganizationView(),
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
      name: _Paths.TEAMS,
      page: () => TeamsView(
        controller: Get.put(
          TeamsController(
            partnerId: Partner.current!.id,
            backend: const FirebaseTeamsBackend(),
            // The map under this screen follows the teams made here.
            onTeamsChanged: (teams) {
              if (!Get.isRegistered<GoogleGroupsController>()) return;
              Get.find<GoogleGroupsController>().adoptPartnerTeams({
                for (final team in teams) team.key: team.name,
              });
            },
          ),
        ),
      ),
    ),
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
