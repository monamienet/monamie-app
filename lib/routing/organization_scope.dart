import 'package:flutter/widgets.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository_firestore.dart';
import 'package:monamie_app/data/repositories/observed_day/observed_day_repository.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/data/repositories/tracking/firestore_tracking_settings_repository.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/data/services/widgets_binding_app_lifecycle_events.dart';
import 'package:monamie_app/domain/use_cases/start_sharing.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/home/widgets/dialog_permission_prompts.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:provider/provider.dart';

/// The bound organization's shared state and view models, for every screen
/// of the organization's shell route (the map, *Minha conta*, the
/// administration).
///
/// First the repositories that hold the organization's shared state (the
/// person's memberships and the group on the map, the observed day, the
/// permissions, the tracking settings) and the [StartSharing] use case
/// over them, then the view models, which read only repositories and use
/// cases. Each provider creates and starts its object on first read (the
/// tracking settings at once: they must hold the saved settings before
/// *Ajustes de acompanhamento* opens) and disposes it when the shell leaves
/// the route stack: on sign-out, on switching organization, on losing
/// access. A provider further down the list reads the ones above it, and
/// Flutter unmounts children first, so an object is disposed before the
/// ones it listens to. The organization-independent data layer comes from
/// `appDependencies`, above the router.
///
/// Dialogs and sheets open on the root navigator, outside this scope: they
/// get view models by parameter, never through `context.read`.
class OrganizationScope extends StatelessWidget {
  /// [onAccessLost] runs when the person's organization membership
  /// disappears (`SignOut.afterAccessLost` forgets the organization).
  const OrganizationScope({
    super.key,
    required this.onAccessLost,
    required this.child,
  });

  final Future<void> Function() onAccessLost;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      // Provided under its contract: screens and view models read
      // [MembershipRepository], never the Firestore-backed class.
      Provider<MembershipRepository>(
        create: (context) => MembershipRepositoryFirestore(
          onAccessLost: onAccessLost,
          memberships: context.read(),
          positions: context.read(),
        )..start(),
        dispose: (_, memberships) {
          if (memberships is MembershipRepositoryFirestore) {
            memberships.dispose();
          }
        },
      ),
      Provider<ObservedDayRepository>(
        create: (_) => ObservedDayRepository(),
        dispose: (_, observedDay) => observedDay.dispose(),
      ),
      Provider<PermissionsRepository>(
        create: (context) => PermissionsRepository(
          permissions: context.read(),
          prompts: const DialogPermissionPrompts(),
          notices: const ScaffoldNoticePresenter(),
          backgroundRestrictionChecker: context.read(),
          backgroundUsageSettingsLauncher: context.read(),
          // One per repository: each listens alone, and the next scope's
          // starts before this one's stops.
          lifecycle: WidgetsBindingAppLifecycleEvents(),
        )..start(),
        dispose: (_, permissions) => permissions.dispose(),
      ),
      Provider<TrackingSettingsRepository>(
        lazy: false,
        create: (_) => FirestoreTrackingSettingsRepository()..start(),
        dispose: (_, settings) {
          if (settings is FirestoreTrackingSettingsRepository) {
            settings.dispose();
          }
        },
      ),
      // The use case of the sharing switch: it reads the repositories above.
      Provider<StartSharing>(
        create: (context) => StartSharing(
          permissions: context.read(),
          location: context.read(),
          memberships: context.read(),
          service: context.read(),
        ),
      ),
      Provider<CalendarViewModel>(
        create: (context) => CalendarViewModel(
          memberships: context.read(),
          observedDay: context.read(),
          positions: context.read(),
        ),
        dispose: (_, calendar) => calendar.dispose(),
      ),
      ChangeNotifierProvider<UserViewModel>(
        create: (context) => UserViewModel(
          memberships: context.read(),
          repository: context.read(),
        )..start(),
      ),
      Provider<TrackingViewModel>(
        create: (context) => TrackingViewModel(
          notices: const ScaffoldNoticePresenter(),
          memberships: context.read(),
          observedDay: context.read(),
          permissions: context.read(),
          profiles: context.read(),
          startSharing: context.read(),
          service: context.read(),
          location: context.read(),
          positions: context.read(),
        )..start(),
        dispose: (_, tracking) => tracking.dispose(),
      ),
    ],
    child: child,
  );
}
