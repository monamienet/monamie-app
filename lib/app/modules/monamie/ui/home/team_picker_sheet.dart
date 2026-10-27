import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_colors.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// The teams whose map the person can watch, to pick the one to observe.
class TeamPickerSheet extends StatelessWidget {
  const TeamPickerSheet({super.key});

  static Future<void> show() => Get.bottomSheet(
    const TeamPickerSheet(),
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final groups = Get.find<GoogleGroupsController>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Obx(() {
          final teams = groups.googleGroups;
          final selected = groups.selectedGroup.value?.email;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HomeColors.handle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Equipe no mapa',
                  style: TextStyle(
                    color: HomeColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (groups.isLoading.value)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (teams.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Nenhuma equipe disponível.',
                    style: TextStyle(color: HomeColors.muted, fontSize: 15),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final team in teams)
                        ListTile(
                          minTileHeight: 56,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            team.name,
                            style: const TextStyle(
                              color: HomeColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          trailing: team.email == selected
                              ? Icon(Icons.check, color: AppColors.mediumBlue())
                              : null,
                          selected: team.email == selected,
                          onTap: () {
                            groups.updateObservedUsers(team);
                            Get.back<void>();
                          },
                        ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
