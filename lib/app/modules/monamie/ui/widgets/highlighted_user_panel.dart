import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/call_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';
import 'package:intl/intl.dart';

class HighlightedUserPanel extends StatelessWidget {
  const HighlightedUserPanel({super.key});

  TrackingController get trackingCtrl => Get.find<TrackingController>();
  GoogleGroupsController get googleGroupsCtrl => Get.find<GoogleGroupsController>();
  CallController get callCtrl => Get.find<CallController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = trackingCtrl.selectedFirebaseUser.value;

      if (user == null) {
        return const SizedBox.shrink();
      }

      // Verifica se o usuário está em observedMembers para mostrar o ícone de olho
      final member = googleGroupsCtrl.observedMembers.firstWhereOrNull(
        (m) => m.email == user.email,
      );
      final isHighlighted = member != null && googleGroupsCtrl.isHighlighted(member);

      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: AppColors.darkBlue(),
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: trackingCtrl.closeFirebaseUserDetails,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.nome ?? user.email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member != null)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isHighlighted
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                googleGroupsCtrl.toggleHighlight(member);
                              },
                            ),
                          ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: SvgPicture.asset(
                              'assets/monamie/Google_Meet_icon.svg',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            onPressed: () {
                              callCtrl.launchGoogleMeet(user.email);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Última atualização: ${DateFormat('dd/MM/yyyy HH:mm').format(user.timestamp!)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
} 
