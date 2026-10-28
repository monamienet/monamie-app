import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_header.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_menu.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_sheet.dart';
import 'package:monamie_app/app/modules/monamie/ui/widgets/logout_progress_overlay.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';

class MonamiePage extends StatelessWidget {
  const MonamiePage({super.key});

  UserController get userCtrl => Get.find<UserController>();
  PermissionsController get permissionsCtrl =>
      Get.find<PermissionsController>();
  TrackingController get trackingCtrl => Get.find<TrackingController>();
  GoogleGroupsController get googleGroupsController =>
      Get.find<GoogleGroupsController>();
  AuthGoogleController get authCtrl => Get.find<AuthGoogleController>();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The header is dark, so the status bar icons are light.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        drawer: const HomeMenu(),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                const HomeHeader(),
                Expanded(child: _body(context)),
              ],
            ),
            Obx(
              () => authCtrl.isLoggingOut.value
                  ? LogoutProgressOverlay(
                      message: authCtrl.isSwitchingOrganization.value
                          ? 'Trocando de organização…'
                          : 'Encerrando sessão…',
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centralizeButton() {
    return Obx(
      () => permissionsCtrl.arePermissionsGranted() && userCtrl.isTrackable()
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
    return Obx(() {
      if (userCtrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (userCtrl.isTrackable() &
          !kIsWeb &
          !permissionsCtrl.arePermissionsGranted()) {
        return _permissionScreen();
      }

      return Column(
        children: [
          Expanded(child: mapa(context)),
          const HomeSheet(),
        ],
      );
    });
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
            // A person who only shares has no team on the map: start on them.
            onMapReady: () {
              if (!googleGroupsController.canWatch) {
                trackingCtrl.centerMapOnCurrentLocation();
              }
            },
            onTap: (_, _) => googleGroupsController.clearSelected(),
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
            _centralizeButton(),
          ],
        ),
      ],
    );
  }

  /// Desenha as trajetórias dos usuários destacados (highlightedObservedUsers).
  Widget _highlightedTrajectories() {
    return Obx(() {
      final trajectories = trackingCtrl.highlightedTrajectories;

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
    });
  }

  /// Usuário verá essa tela apenas se algumas das permissões necessárias
  /// ainda não tiver sido concedida.
  Widget _permissionScreen() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.appBarBottomGradient()),
      child: Obx(
        () => Align(
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
                        onPressed:
                            permissionsCtrl.requestNotificationPermission,
                        child: const Text("Permitir notificação"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      permissionsCtrl.hasNotificationPermission.value
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
                        onPressed: permissionsCtrl.requestWhenInUsePermission,
                        child: const Text("Permitir localização (durante uso)"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      permissionsCtrl.hasWhenInUseLocationPermission.value
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
                        onPressed: permissionsCtrl.requestAlwaysPermission,
                        child: const Text("Permitir localização (sempre)"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      permissionsCtrl.hasAlwaysLocationPermission.value
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
                        onPressed: permissionsCtrl.openBackgroundUsageSettings,
                        child: const Text("Permitir uso em segundo plano"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      permissionsCtrl.isBackgroundRestricted.value
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

  Widget _tile() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'org.monamienet.app',
    );
  }

  /// The person's own place on the map while they share: the team's
  /// documents only draw them when they also watch the team they share with.
  /// Hidden while sharing is off, so the map never suggests the team sees
  /// someone it does not.
  Widget _ownMarker() {
    const markerSize = 50.0;
    return Obx(() {
      final point = trackingCtrl.ownPosition.value;
      final me = userCtrl.user?.email;
      if (point == null ||
          me == null ||
          !userCtrl.isTrackable() ||
          !trackingCtrl.isTrackingEnabled.value) {
        return const SizedBox.shrink();
      }
      final drawnWithTheTeam =
          googleGroupsController.observedMembers.any((m) => m.email == me) &&
          trackingCtrl.firebaseUsers.any((u) => u.email == me);
      if (drawnWithTheTeam) return const SizedBox.shrink();
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
    });
  }

  Widget _firebaseMarkers() {
    const double markerSize = 50.0;

    return Obx(
      () => MarkerLayer(
        markers: trackingCtrl.firebaseUsers
            .where((user) {
              final isObservingToday = trackingCtrl.isObservingToday;
              final observedMembersEmails = googleGroupsController
                  .observedMembers
                  .map((member) => member.email);
              final isObservedMember = observedMembersEmails.contains(
                user.email,
              );

              if (!isObservingToday) {
                // Em dia passado, mantém o comportamento atual: exibe apenas quem
                // tem posição histórica carregada em `animatedMarkerPositions`.
                final hasHistoricalPosition = trackingCtrl
                    .animatedMarkerPositions
                    .containsKey(user.email);
                return isObservedMember && hasHistoricalPosition;
              }

              // Hoje: exibe usuários observados transmitindo ativamente no grupo
              return isObservedMember;
            })
            .map((user) {
              final isCurrentUser =
                  user.email == trackingCtrl.userCtrl.user?.email;
              // Usa a posição animada se disponível, caso contrário usa a posição atual
              final animatedPos =
                  trackingCtrl.animatedMarkerPositions[user.email];
              final position =
                  animatedPos ?? LatLng(user.lat ?? 0.0, user.lng ?? 0.0);

              return Marker(
                point: position,
                width: isCurrentUser ? markerSize * 3 : markerSize,
                height: isCurrentUser ? markerSize * 3 : markerSize,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () =>
                      googleGroupsController.toggleSelected(user.email),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (isCurrentUser)
                        Obx(() {
                          final heading = trackingCtrl.heading.value;
                          if (heading == null) return const SizedBox.shrink();

                          return Transform.rotate(
                            angle: heading * (math.pi / 180),
                            child: SizedBox(
                              width: markerSize * 3,
                              height: markerSize * 3,
                              child: CustomPaint(painter: _BeamPainter()),
                            ),
                          );
                        }),
                      SizedBox(
                        width: markerSize,
                        height: markerSize,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                user.isTracked == false ||
                                    DateTime.now().difference(
                                          user.timestamp!,
                                        ) >=
                                        Get.find<TrackingSettingsController>()
                                            .staleAfter
                                ? trackingCtrl
                                      .setMarkerColor(user)
                                      .withAlpha(100)
                                : trackingCtrl.setMarkerColor(user),
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
            })
            .toList(),
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
