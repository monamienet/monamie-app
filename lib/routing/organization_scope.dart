import 'package:flutter/widgets.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/ui/home/view_models/group_map_view_model.dart';
import 'package:monamie_app/ui/home/view_models/group_map_state.dart';
import 'package:monamie_app/ui/home/view_models/permissions_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/home/widgets/dialog_permission_prompts.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
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
        create: (_) => GroupMapViewModel(onAccessLost: onAccessLost)..start(),
        dispose: (_, groupMap) {
          if (groupMap is GroupMapViewModel) groupMap.dispose();
        },
      ),
      Provider<CalendarViewModel>(
        create: (context) =>
            CalendarViewModel(groupMap: context.read<GroupMapState>()),
        dispose: (_, calendar) => calendar.dispose(),
      ),
      ChangeNotifierProvider<UserViewModel>(
        create: (context) => UserViewModel(
          groupMap: context.read<GroupMapState>(),
          repository: userRepository,
        )..start(),
      ),
      Provider<PermissionsViewModel>(
        create: (_) => PermissionsViewModel(
          prompts: const DialogPermissionPrompts(),
          notices: const ScaffoldNoticePresenter(),
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
        )..start(),
        dispose: (_, tracking) => tracking.dispose(),
      ),
      // Holds no state: nothing to start or dispose.
      Provider<CallService>(create: (_) => CallService()),
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
