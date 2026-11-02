import 'package:flutter/widgets.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/call_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/dialog_permission_prompts.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';
import 'package:provider/provider.dart';

/// The bound organization's controllers, for every screen of the
/// organization's shell route (the map, *Minha conta*, the administration).
///
/// Each provider creates and starts its controller on first read (the
/// tracking settings at once: they must hold the saved settings before
/// *Ajustes de acompanhamento* opens) and disposes it when the shell leaves
/// the route stack: on sign-out, on switching organization, on losing
/// access. A provider further down the list reads the ones above it, and
/// Flutter unmounts children first, so a controller is disposed before the
/// ones it listens to.
///
/// Dialogs and sheets open on the root navigator, outside this scope: they
/// get controllers by parameter, never through `context.read`.
class OrganizationScope extends StatelessWidget {
  /// [onAccessLost] runs when the person's organization membership
  /// disappears (the sign-in flow forgets the organization).
  /// [userRepository] and [trackingSettingsRepository] replace the profile
  /// store and the Firestore settings (tests); `null` uses the real ones.
  const OrganizationScope({
    super.key,
    required this.onAccessLost,
    required this.child,
    this.userRepository,
    this.trackingSettingsRepository,
  });

  final Future<void> Function() onAccessLost;
  final Widget child;
  final UserGoogleRepository? userRepository;
  final TrackingSettingsRepository? trackingSettingsRepository;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      // Provided under its contract: screens and controllers read
      // [GroupMapState], never the Firestore-backed class.
      Provider<GroupMapState>(
        create: (_) => GroupMapController(onAccessLost: onAccessLost)..start(),
        dispose: (_, groupMap) {
          if (groupMap is GroupMapController) groupMap.dispose();
        },
      ),
      Provider<CalendarController>(
        create: (context) =>
            CalendarController(groupMap: context.read<GroupMapState>()),
        dispose: (_, calendar) => calendar.dispose(),
      ),
      ChangeNotifierProvider<UserController>(
        create: (context) => UserController(
          groupMap: context.read<GroupMapState>(),
          repository: userRepository,
        )..start(),
      ),
      Provider<PermissionsController>(
        create: (_) => PermissionsController(
          prompts: const DialogPermissionPrompts(),
          notices: const ScaffoldNoticePresenter(),
        )..start(),
        dispose: (_, permissions) => permissions.dispose(),
      ),
      Provider<TrackingController>(
        create: (context) => TrackingController(
          notices: const ScaffoldNoticePresenter(),
          userCtrl: context.read<UserController>(),
          permissionsCtrl: context.read<PermissionsController>(),
          calendar: context.read<CalendarController>(),
          groupMap: context.read<GroupMapState>(),
        )..start(),
        dispose: (_, tracking) => tracking.dispose(),
      ),
      // Holds no state: nothing to start or dispose.
      Provider<CallController>(create: (_) => CallController()),
      Provider<TrackingSettingsController>(
        lazy: false,
        create: (_) =>
            TrackingSettingsController(repository: trackingSettingsRepository)
              ..start(),
        dispose: (_, settings) => settings.dispose(),
      ),
    ],
    child: child,
  );
}
