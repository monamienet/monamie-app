import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_backend.dart';
import 'package:monamie_app/data/repositories/account/firebase_account_deletion_backend.dart';
import 'package:monamie_app/data/repositories/administrators/administrators_backend.dart';
import 'package:monamie_app/data/repositories/administrators/firebase_administrators_backend.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_backend.dart';
import 'package:monamie_app/data/repositories/appearance/firebase_appearance_backend.dart';
import 'package:monamie_app/data/repositories/creation/creation_backend.dart';
import 'package:monamie_app/data/repositories/creation/firebase_creation_backend.dart';
import 'package:monamie_app/data/repositories/groups/firebase_groups_backend.dart';
import 'package:monamie_app/data/repositories/groups/groups_backend.dart';
import 'package:monamie_app/data/repositories/invites/firebase_invites_backend.dart';
import 'package:monamie_app/data/repositories/invites/invites_backend.dart';
import 'package:monamie_app/data/repositories/membership/firestore_membership_source.dart';
import 'package:monamie_app/data/repositories/membership/firestore_organization_membership_check.dart';
import 'package:monamie_app/data/repositories/membership/membership_source.dart';
import 'package:monamie_app/data/repositories/membership/organization_membership_check.dart';
import 'package:monamie_app/data/repositories/organization/central_organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/hive_organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/organization/shared_preferences_organization_binding_store.dart';
import 'package:monamie_app/data/repositories/positions/firebase_provider.dart';
import 'package:monamie_app/data/repositories/positions/group_positions_source.dart';
import 'package:monamie_app/data/repositories/theme/firestore_theme_catalog.dart';
import 'package:monamie_app/data/repositories/theme/theme_catalog.dart';
import 'package:monamie_app/data/repositories/tracking/firestore_tracking_settings_repository.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/data/services/auth/stored_google_bond_check.dart';
import 'package:monamie_app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/data/services/flutter_background_service_tracking_stopper.dart';
import 'package:monamie_app/data/services/geolocator_device_location.dart';
import 'package:monamie_app/data/services/method_channel_background_restriction_checker.dart';
import 'package:monamie_app/data/services/method_channel_background_usage_settings_launcher.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The composition root: the one place that creates the app's concrete data
/// layer (Firebase, Hive, SharedPreferences, the plugins).
///
/// Each object is provided under its contract, above the router, and lives
/// as long as the app. Route assembly reads them (`context.read<T>()`) to
/// build view models; view models and screens never create one. Tests
/// replace any of them by providing a double under the same type.
///
/// None of them holds the bound organization: each reaches the
/// organization's Firebase project when called, so they survive switching
/// organization.
///
/// [organizationSession] and [brandingLoader] come from [createOrganizationSession]
/// and [createBrandingLoader]: `main` uses them before the app runs, to
/// restore the remembered organization.
List<SingleChildWidget> appDependencies({
  required OrganizationSession organizationSession,
  required OrganizationBrandingLoader brandingLoader,
}) => [
  Provider<AuthGoogleService>(create: (_) => AuthGoogleService()),
  Provider<UserGoogleRepository>(create: (_) => UserGoogleRepository()),
  Provider<OrganizationSession>.value(value: organizationSession),
  Provider<ThemeCatalog>(create: (_) => const FirestoreThemeCatalog()),
  Provider<OrganizationBrandingLoader>.value(value: brandingLoader),
  Provider<OrganizationDirectory>(
    create: (_) => CentralOrganizationDirectory(),
  ),
  Provider<OrganizationLocalData>(
    create: (_) => const HiveOrganizationLocalData(),
  ),
  Provider<OrganizationMembershipCheck>(
    create: (_) => const FirestoreOrganizationMembershipCheck(),
  ),
  Provider<GoogleBondCheck>(
    create: (context) => StoredGoogleBondCheck(
      userRepository: context.read<UserGoogleRepository>(),
    ),
  ),
  Provider<FlutterBackgroundService>(create: (_) => FlutterBackgroundService()),
  Provider<BackgroundTrackingStopper>(
    create: (context) => FlutterBackgroundServiceTrackingStopper(
      service: context.read<FlutterBackgroundService>(),
    ),
  ),
  Provider<InvitesBackend>(create: (_) => const FirebaseInvitesBackend()),
  Provider<AccountDeletionBackend>(
    create: (_) => const FirebaseAccountDeletionBackend(),
  ),
  Provider<GroupsBackend>(create: (_) => const FirebaseGroupsBackend()),
  Provider<AdministratorsBackend>(
    create: (_) => const FirebaseAdministratorsBackend(),
  ),
  Provider<AppearanceBackend>(
    create: (context) =>
        FirebaseAppearanceBackend(themes: context.read<ThemeCatalog>()),
  ),
  Provider<CreationBackend>(create: (_) => const FirebaseCreationBackend()),
  Provider<TrackingSettingsRepository>(
    create: (_) => const FirestoreTrackingSettingsRepository(),
  ),
  Provider<MembershipSource>(create: (_) => const FirestoreMembershipSource()),
  // One object behind both contracts: the map reads the positions, the
  // calendar and tracking also read trails and days.
  Provider<FirebaseProvider>(create: (_) => FirebaseProvider()),
  ProxyProvider<FirebaseProvider, GroupPositionsSource>(
    update: (_, positions, _) => positions,
  ),
  Provider<DeviceLocation>(create: (_) => const GeolocatorDeviceLocation()),
  Provider<BackgroundRestrictionChecker>(
    create: (_) => MethodChannelBackgroundRestrictionChecker(),
  ),
  Provider<BackgroundUsageSettingsLauncher>(
    create: (_) => MethodChannelBackgroundUsageSettingsLauncher(),
  ),
  Provider<CallService>(create: (_) => CallService()),
];

/// The organization binding of the UI isolate, remembered in
/// SharedPreferences.
OrganizationSession createOrganizationSession() =>
    OrganizationSession(store: SharedPreferencesOrganizationBindingStore());

/// Reads organizations' branding, with themes from the central catalog.
OrganizationBrandingLoader createBrandingLoader() =>
    OrganizationBrandingLoader(themes: const FirestoreThemeCatalog());
