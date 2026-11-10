import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/home_view_model.dart';
import 'package:monamie_app/ui/home/view_models/resume_on_restart_view_model.dart';
import 'package:monamie_app/ui/home/view_models/home_session_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/home/widgets/home_header.dart';
import 'package:monamie_app/ui/home/widgets/home_menu.dart';
import 'package:monamie_app/ui/home/widgets/home_sheet.dart';
import 'package:monamie_app/ui/home/widgets/sharing_notification_refresher.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/core/ui/logout_progress_overlay.dart';
import 'package:monamie_app/ui/core/themes/color_palette.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

/// The map of the bound organization, with its header, sheet and menu. The
/// organization's route hands it the view models of the organization's
/// scope and its own [HomeViewModel] and [HomeSessionViewModel].
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.userCtrl,
    required this.home,
    required this.trackingCtrl,
    required this.calendar,
    required this.session,
    required this.language,
    required this.resumeOnRestart,
  });

  final UserViewModel userCtrl;

  /// The memberships, the group on the map, the permissions and calls.
  final HomeViewModel home;
  final TrackingViewModel trackingCtrl;
  final CalendarViewModel calendar;

  /// The session: the menu's sign-out and switch, and their overlay.
  final HomeSessionViewModel session;

  /// The language picker, opened from the menu.
  final LanguageViewModel language;

  /// The menu's choice to resume sharing after a restart, and the texts the
  /// device shows then.
  final ResumeOnRestartViewModel resumeOnRestart;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The header is dark, so the status bar icons are light.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        drawer: HomeMenu(
          home: home,
          user: userCtrl,
          session: session,
          tracking: trackingCtrl,
          language: language,
          resumeOnRestart: resumeOnRestart,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Keeps the sharing notification in the app's language.
            SharingNotificationRefresher(
              tracking: trackingCtrl,
              resumeOnRestart: resumeOnRestart,
            ),
            Column(
              children: [
                HomeHeader(home: home, user: userCtrl, calendar: calendar),
                Expanded(child: _body(context)),
              ],
            ),
            ListenableBuilder(
              listenable: session,
              builder: (context, _) => session.state.isLoggingOut
                  ? LogoutProgressOverlay(
                      message: session.state.isSwitchingOrganization
                          ? AppLocalizations.of(context).switchingOrganization
                          : AppLocalizations.of(context).loggingOut,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// What [UserViewModel.isTrackable] reads: the profile and the
  /// capabilities.
  Listenable get _trackable => Listenable.merge([userCtrl, home.capabilities]);

  /// What [HomeViewModel.arePermissionsGranted] reads.
  Listenable get _granted => Listenable.merge([
    home.hasAlwaysLocationPermission,
    home.hasNotificationPermission,
    home.isBackgroundRestricted,
  ]);

  Widget _centralizeButton() {
    return ListenableBuilder(
      listenable: Listenable.merge([_trackable, _granted]),
      builder: (context, _) =>
          home.arePermissionsGranted() && userCtrl.isTrackable()
          ? Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: "btnCentralizeMap",
                backgroundColor: AppColors.lightBlue(),
                onPressed: trackingCtrl.centerMapOnCurrentLocation,
                child: Icon(Icons.my_location, color: AppColors.darkBlue()),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _body(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_trackable, _granted]),
      builder: (context, _) {
        final granted = home.arePermissionsGranted();
        if (userCtrl.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userCtrl.isTrackable() & !kIsWeb & !granted) {
          return _permissionScreen();
        }

        return Column(
          children: [
            Expanded(child: mapa(context)),
            HomeSheet(
              home: home,
              tracking: trackingCtrl,
              calendar: calendar,
              user: userCtrl,
            ),
          ],
        );
      },
    );
  }

  /// Usuário verá essa tela apenas se todas as permissões necessárias já tiverem
  /// sido concedidas.
  Widget mapa(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: trackingCtrl.mapController,
          options: MapOptions(
            initialZoom: 15.0,
            initialCenter: LatLng(
              trackingCtrl.position.latitude,
              trackingCtrl.position.longitude,
            ),
            // A person who only shares has no group on the map: start on them.
            onMapReady: () {
              if (!home.canWatch) {
                trackingCtrl.centerMapOnCurrentLocation();
              }
            },
            onTap: (_, _) => home.clearSelected(),
            minZoom: 3.0,
            maxZoom: 19.0,
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(LatLng(-90, -180), LatLng(90, 180)),
            ),
          ),
          children: [
            _tile(),
            _highlightedTrajectories(),
            _firebaseMarkers(),
            _ownMarker(),
            _attribution(context),
            _centralizeButton(),
          ],
        ),
        _switchingGroupPill(),
      ],
    );
  }

  /// "Carregando `grupo`…" over the map while a group picked in the group
  /// menu loads, as on the design canvas.
  Widget _switchingGroupPill() {
    return ListenableBuilder(
      listenable: Listenable.merge([home.switchingGroup, home.selectedGroup]),
      builder: (context, _) {
        if (!home.switchingGroup.value) {
          return const SizedBox.shrink();
        }
        final group = switch (home.selectedGroup.value) {
          final selected? => AppLocalizations.of(
            context,
          ).mapGroupName(selected),
          null => '',
        };
        return Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, -10 * (1 - t)),
                  child: child,
                ),
              ),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  width: 220,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x47091416),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          color: AppColors.onPrimaryDark,
                          backgroundColor: Colors.white.withAlpha(77),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context).homeLoadingGroup(group),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Desenha as trajetórias dos usuários destacados (highlightedObservedUsers).
  Widget _highlightedTrajectories() {
    return ValueListenableBuilder(
      valueListenable: trackingCtrl.highlightedTrajectories,
      builder: (context, trajectories, _) {
        if (trajectories.isEmpty) {
          return PolylineLayer<Object>(polylines: []);
        }

        final polylines = <Polyline<Object>>[];
        for (final entry in trajectories.entries) {
          final points = entry.value;
          if (points.length < 2) continue;

          final latLngPoints = points.map((p) => LatLng(p.lat, p.lng)).toList();

          // Cor baseada no email para consistência
          final hash = entry.key.hashCode;
          final hue = (hash % 360).toDouble();
          final baseColor = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();

          final darkerBorderColor = Color.fromARGB(
            (baseColor.a * 255.0).round().clamp(0, 255),
            (baseColor.r * 255.0 * 0.5).round().clamp(0, 255),
            (baseColor.g * 255.0 * 0.5).round().clamp(0, 255),
            (baseColor.b * 255.0 * 0.5).round().clamp(0, 255),
          );

          polylines.add(
            Polyline<Object>(
              points: latLngPoints,
              strokeWidth: 4.0,
              color: baseColor,
              borderStrokeWidth: 1.5,
              borderColor: darkerBorderColor,
            ),
          );
        }

        return PolylineLayer<Object>(polylines: polylines);
      },
    );
  }

  /// Usuário verá essa tela apenas se algumas das permissões necessárias
  /// ainda não tiver sido concedida.
  Widget _permissionScreen() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.appBarBottomGradient()),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          home.hasNotificationPermission,
          home.hasWhenInUseLocationPermission,
          home.hasAlwaysLocationPermission,
          home.isBackgroundRestricted,
        ]),
        builder: (context, _) => Align(
          alignment: Alignment.center,
          child: IntrinsicWidth(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkBlue(),
                        ),
                        onPressed: home.requestNotificationPermission,
                        child: Text(
                          AppLocalizations.of(context).homeAllowNotification,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      home.hasNotificationPermission.value
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkBlue(),
                        ),
                        onPressed: home.requestWhenInUsePermission,
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).homeAllowLocationWhileInUse,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      home.hasWhenInUseLocationPermission.value
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkBlue(),
                        ),
                        onPressed: home.requestAlwaysPermission,
                        child: Text(
                          AppLocalizations.of(context).homeAllowLocationAlways,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      home.hasAlwaysLocationPermission.value
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkBlue(),
                        ),
                        onPressed: home.openBackgroundUsageSettings,
                        child: Text(
                          AppLocalizations.of(context).homeAllowBackground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      home.isBackgroundRestricted.value
                          ? Icons.check_box_outline_blank
                          : Icons.check_box,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Keeps 35% of the tiles' saturation (Rec. 709 luminance weights): the
  /// default OSM style is loud, and the group's markers must stand out on it.
  static const _softColors = ColorFilter.matrix(<double>[
    0.48819, 0.46488, 0.04693, 0, 0, //R
    0.13819, 0.81488, 0.04693, 0, 0, //G
    0.13819, 0.46488, 0.39693, 0, 0, //B
    0, 0, 0, 1, 0, //A
  ]);

  Widget _tile() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'org.monamienet.app',
      tileBuilder: (context, tileWidget, tile) =>
          ColorFiltered(colorFilter: _softColors, child: tileWidget),
    );
  }

  /// The credit that the OSM licence and tile policy require on the map;
  /// bottom left, since the center button takes the bottom right.
  Widget _attribution(BuildContext context) {
    return SimpleAttributionWidget(
      source: Text(AppLocalizations.of(context).mapAttribution),
      alignment: Alignment.bottomLeft,
      onTap: () => launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
        mode: LaunchMode.externalApplication,
      ),
    );
  }

  /// The person's own place on the map while they share: the group's
  /// documents only draw them when they also watch a group they share with.
  /// Hidden while sharing is off, so the map never suggests the group sees
  /// someone it does not.
  Widget _ownMarker() {
    const markerSize = 50.0;
    return ListenableBuilder(
      listenable: Listenable.merge([
        _trackable,
        home.observedMembers,
        trackingCtrl.ownPosition,
        trackingCtrl.isTrackingEnabled,
        trackingCtrl.firebaseUsers,
      ]),
      builder: (context, _) {
        final point = trackingCtrl.ownPosition.value;
        final me = userCtrl.user?.email;
        if (point == null ||
            me == null ||
            !userCtrl.isTrackable() ||
            !trackingCtrl.isTrackingEnabled.value) {
          return const SizedBox.shrink();
        }
        if (trackingCtrl.isDrawnWithTheGroup(me)) {
          return const SizedBox.shrink();
        }
        return MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: markerSize,
              height: markerSize,
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _firebaseMarkers() {
    const double markerSize = 50.0;

    return ListenableBuilder(
      listenable: Listenable.merge([
        home.observedMembers,
        calendar.observedDay,
        userCtrl,
        trackingCtrl.firebaseUsers,
        trackingCtrl.animatedMarkerPositions,
      ]),
      builder: (context, _) => MarkerLayer(
        markers: trackingCtrl.markedUsers.map((user) {
          final isCurrentUser = user.email == userCtrl.user?.email;
          // The signed-in person's pin has a colour of its own.
          final markerColor = isCurrentUser ? Colors.indigo : Colors.lightBlue;
          // Usa a posição animada se disponível, caso contrário usa a posição atual
          final animatedPos =
              trackingCtrl.animatedMarkerPositions.value[user.email];
          final position =
              animatedPos ?? LatLng(user.lat ?? 0.0, user.lng ?? 0.0);

          return Marker(
            point: position,
            width: isCurrentUser ? markerSize * 3 : markerSize,
            height: isCurrentUser ? markerSize * 3 : markerSize,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => home.toggleSelected(user.email),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (isCurrentUser)
                    ValueListenableBuilder(
                      valueListenable: trackingCtrl.heading,
                      builder: (context, heading, _) {
                        if (heading == null) return const SizedBox.shrink();

                        return Transform.rotate(
                          angle: heading * (math.pi / 180),
                          child: SizedBox(
                            width: markerSize * 3,
                            height: markerSize * 3,
                            child: CustomPaint(painter: _BeamPainter()),
                          ),
                        );
                      },
                    ),
                  SizedBox(
                    width: markerSize,
                    height: markerSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: trackingCtrl.isFaded(user, DateTime.now())
                            ? markerColor.withAlpha(100)
                            : markerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blueAccent.withValues(alpha: 1.00),
          Colors.blueAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 - math.pi / 6, // start angle: -120 deg
      math.pi / 3, // sweep angle: 60 deg
      false,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
