import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository_remote.dart';
import 'package:monamie_app/data/repositories/administrators/administrators_repository.dart';
import 'package:monamie_app/data/repositories/administrators/administrators_repository_remote.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_repository.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_repository_remote.dart';
import 'package:monamie_app/data/repositories/creation/creation_repository.dart';
import 'package:monamie_app/data/repositories/creation/creation_repository_remote.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository_remote.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository_remote.dart';
import 'package:monamie_app/data/repositories/language/language_repository.dart';
import 'package:monamie_app/data/repositories/language/language_repository_preferences.dart';
import 'package:monamie_app/data/repositories/organization/central_organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/hive_organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/organization/shared_preferences_organization_binding_store.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository_firestore.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository_google.dart';
import 'package:monamie_app/data/repositories/theme/theme_repository.dart';
import 'package:monamie_app/data/repositories/theme/theme_repository_firestore.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/data/services/auth/stored_google_bond_check.dart';
import 'package:monamie_app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/data/services/firestore/positions_firestore_service.dart';
import 'package:monamie_app/data/services/flutter_background_service_tracking_stopper.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/data/services/language_preferences_service.dart';
import 'package:monamie_app/data/services/geolocator_device_location.dart';
import 'package:monamie_app/data/services/method_channel_background_restriction_checker.dart';
import 'package:monamie_app/data/services/method_channel_background_usage_settings_launcher.dart';
import 'package:monamie_app/data/services/permissions_service.dart';
import 'package:monamie_app/data/services/storage/organization_storage_service.dart';
import 'package:monamie_app/data/services/user_profile_hive_service.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The composition root: the one place that creates the app's concrete data
/// layer (Firebase, Hive, SharedPreferences, the plugins), the
/// [SessionRepository] the router follows and the use cases.
///
/// Each object is provided under its contract, above the router, and lives
/// as long as the app. Route assembly reads them (`context.read<T>()`) to
/// build view models; view models and screens never create one. Tests
/// replace any of them by providing a double under the same type.
///
/// None of them holds the bound organization: each reaches the
/// organization's Firebase project when called, so they survive switching
/// organization. What does hold it (the memberships, the observed day, the
/// permissions, the tracking settings and the `StartSharing` use case over
/// them) is created by `OrganizationScope`, with the organization's view
/// models.
///
/// [organizationSession], [brandingLoader] and [languageRepository] come from
/// [createOrganizationSession], [createBrandingLoader] and
/// [createLanguageRepository]: `main` uses them before the app runs, to
/// restore the remembered organization and language.
List<SingleChildWidget> appDependencies({
  required OrganizationSession organizationSession,
  required OrganizationBrandingLoader brandingLoader,
  required LanguageRepository languageRepository,
}) => [
  Provider<UserProfileHiveService>(
    create: (_) => const UserProfileHiveService(),
  ),
  Provider<UserGoogleRepository>(
    create: (context) => UserGoogleRepository(service: context.read()),
  ),
  Provider<AuthGoogleService>(
    create: (context) => AuthGoogleService(userRepository: context.read()),
    // Stops the web sign-in events.
    dispose: (_, auth) => auth.dispose(),
  ),
  // The session the router follows; Google Sign-In starts initializing at
  // once (*Login* waits for it).
  Provider<SessionRepository>(
    create: (context) => SessionRepositoryGoogle(auth: context.read())..start(),
    dispose: (_, session) => session.dispose(),
  ),
  Provider<OrganizationSession>.value(value: organizationSession),
  Provider<LanguageRepository>.value(value: languageRepository),
  Provider<ThemeRepository>(create: (_) => const ThemeRepositoryFirestore()),
  Provider<OrganizationBrandingLoader>.value(value: brandingLoader),
  Provider<OrganizationDirectory>(
    create: (_) => CentralOrganizationDirectory(),
  ),
  Provider<OrganizationLocalData>(
    create: (_) => const HiveOrganizationLocalData(),
  ),
  // The membership documents: the check on entering an organization and
  // the map's live capabilities.
  Provider<MembershipService>(create: (_) => const MembershipService()),
  Provider<PositionsFirestoreService>(
    create: (_) => const PositionsFirestoreService(),
  ),
  // The memberships, the calendar and tracking read positions, trails and
  // days.
  Provider<PositionsRepository>(
    create: (context) => PositionsRepositoryFirestore(
      positions: context.read(),
      memberships: context.read(),
    ),
  ),
  Provider<GoogleBondCheck>(
    create: (context) => StoredGoogleBondCheck(
      userRepository: context.read<UserGoogleRepository>(),
    ),
  ),
  Provider<BackgroundTrackingService>(
    create: (_) =>
        BackgroundTrackingService(service: FlutterBackgroundService()),
  ),
  Provider<BackgroundTrackingStopper>(
    create: (context) => FlutterBackgroundServiceTrackingStopper(
      service: context.read(),
      positions: context.read(),
    ),
  ),
  Provider<CentralFunctionsService>(
    create: (_) => const CentralFunctionsService(),
  ),
  Provider<OrganizationFunctionsService>(
    create: (_) => const OrganizationFunctionsService(),
  ),
  Provider<OrganizationStorageService>(
    create: (_) => const OrganizationStorageService(),
  ),
  Provider<InvitesRepository>(
    create: (context) => InvitesRepositoryRemote(functions: context.read()),
  ),
  Provider<AccountDeletionRepository>(
    create: (context) =>
        AccountDeletionRepositoryRemote(functions: context.read()),
  ),
  Provider<GroupsRepository>(
    create: (context) => GroupsRepositoryRemote(functions: context.read()),
  ),
  Provider<AdministratorsRepository>(
    create: (context) =>
        AdministratorsRepositoryRemote(functions: context.read()),
  ),
  Provider<AppearanceRepository>(
    create: (context) => AppearanceRepositoryRemote(
      themes: context.read(),
      functions: context.read(),
      storage: context.read(),
    ),
  ),
  Provider<CreationRepository>(
    create: (context) => CreationRepositoryRemote(functions: context.read()),
  ),
  Provider<DeviceLocation>(create: (_) => const GeolocatorDeviceLocation()),
  Provider<PermissionsService>(create: (_) => const PermissionsService()),
  Provider<BackgroundRestrictionChecker>(
    create: (_) => MethodChannelBackgroundRestrictionChecker(),
  ),
  Provider<BackgroundUsageSettingsLauncher>(
    create: (_) => MethodChannelBackgroundUsageSettingsLauncher(),
  ),
  Provider<CallService>(create: (_) => CallService()),
  // The use cases: the logic that crosses repositories.
  Provider<EnterOrganization>(
    create: (context) => EnterOrganization(
      session: context.read(),
      directory: context.read(),
      brandingLoader: context.read(),
      binder: context.read<OrganizationSession>(),
      memberships: context.read(),
      userRepository: context.read(),
      deletions: context.read(),
      invites: context.read(),
    ),
  ),
  Provider<SignOut>(
    create: (context) => SignOut(
      session: context.read(),
      trackingStopper: context.read(),
      userRepository: context.read(),
      binder: context.read<OrganizationSession>(),
      localData: context.read(),
      directory: context.read(),
      brandingLoader: context.read(),
      invites: context.read(),
      // Messages no screen waits for go through the root messenger.
      notices: const ScaffoldNoticePresenter(),
    ),
  ),
];

/// The organization binding of the UI isolate, remembered in
/// SharedPreferences.
OrganizationSession createOrganizationSession() =>
    OrganizationSession(store: SharedPreferencesOrganizationBindingStore());

/// Reads organizations' branding, with themes from the central catalog.
OrganizationBrandingLoader createBrandingLoader() =>
    OrganizationBrandingLoader(themes: const ThemeRepositoryFirestore());

/// The language the person chose, remembered in SharedPreferences. Call
/// `restore` on it before the app runs.
LanguageRepository createLanguageRepository() =>
    LanguageRepositoryPreferences(service: LanguagePreferencesService());
