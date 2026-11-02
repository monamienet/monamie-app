import 'package:flutter/widgets.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/data/services/widgets_binding_app_lifecycle_events.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/group_map_view_model.dart';
import 'package:monamie_app/ui/home/view_models/group_map_state.dart';
import 'package:monamie_app/ui/home/view_models/permissions_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/home/widgets/dialog_permission_prompts.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:provider/provider.dart';

/// The bound organization's view models, for every screen of the
/// organization's shell route (the map, *Minha conta*, the administration).
///
/// Each provider creates and starts its view model on first read (the
/// tracking settings at once: they must hold the saved settings before
/// *Ajustes de acompanhamento* opens) and disposes it when the shell leaves
/// the route stack: on sign-out, on switching organization, on losing
/// access. A provider further down the list reads the ones above it, and
/// Flutter unmounts children first, so a view model is disposed before the
/// ones it listens to. The data layer comes from `appDependencies`, above
/// the router.
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
      // [GroupMapState], never the Firestore-backed class.
      Provider<GroupMapState>(
        create: (context) => GroupMapViewModel(
          onAccessLost: onAccessLost,
          memberships: context.read(),
          positions: context.read(),
        )..start(),
        dispose: (_, groupMap) {
          if (groupMap is GroupMapViewModel) groupMap.dispose();
        },
      ),
      Provider<CalendarViewModel>(
        create: (context) => CalendarViewModel(
          groupMap: context.read<GroupMapState>(),
          positions: context.read(),
        ),
        dispose: (_, calendar) => calendar.dispose(),
      ),
      ChangeNotifierProvider<UserViewModel>(
        create: (context) => UserViewModel(
          groupMap: context.read<GroupMapState>(),
          repository: context.read(),
        )..start(),
      ),
      Provider<PermissionsViewModel>(
        create: (context) => PermissionsViewModel(
          permissions: context.read(),
          prompts: const DialogPermissionPrompts(),
          notices: const ScaffoldNoticePresenter(),
          backgroundRestrictionChecker: context.read(),
          backgroundUsageSettingsLauncher: context.read(),
          // One per view model: each listens alone, and the next scope's
          // starts before this one's stops.
          lifecycle: WidgetsBindingAppLifecycleEvents(),
        )..start(),
        dispose: (_, permissions) => permissions.dispose(),
      ),
      Provider<TrackingViewModel>(
        create: (context) => TrackingViewModel(
          notices: const ScaffoldNoticePresenter(),
          userCtrl: context.read<UserViewModel>(),
          permissionsCtrl: context.read<PermissionsViewModel>(),
          calendar: context.read<CalendarViewModel>(),
          groupMap: context.read<GroupMapState>(),
          service: context.read(),
          location: context.read(),
          positions: context.read(),
        )..start(),
        dispose: (_, tracking) => tracking.dispose(),
      ),
      Provider<TrackingSettingsController>(
        lazy: false,
        create: (context) =>
            TrackingSettingsController(repository: context.read())..start(),
        dispose: (_, settings) => settings.dispose(),
      ),
    ],
    child: child,
  );
}
