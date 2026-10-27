import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_chip.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_colors.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// The team chip of the app bar as a drop-down: it opens a menu right under
/// the chip with the teams whose map the person can watch, the observed one
/// checked.
class TeamMenuButton extends StatelessWidget {
  const TeamMenuButton({super.key, required this.label});

  /// The text of the chip: the observed team, or a prompt to pick one.
  final String label;

  @override
  Widget build(BuildContext context) {
    final groups = Get.find<GoogleGroupsController>();
    return PopupMenuButton<GoogleGroupModel>(
      tooltip: 'Equipe no mapa: $label',
      position: PopupMenuPosition.under,
      offset: const Offset(0, -2),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      onSelected: groups.updateObservedUsers,
      itemBuilder: (context) {
        final teams = groups.googleGroups.toList();
        final selected = groups.selectedGroup.value?.email;
        if (teams.isEmpty) {
          return [
            const PopupMenuItem<GoogleGroupModel>(
              enabled: false,
              child: Text(
                'Nenhuma equipe disponível',
                style: TextStyle(color: HomeColors.muted, fontSize: 14),
              ),
            ),
          ];
        }
        return [
          for (final team in teams)
            PopupMenuItem<GoogleGroupModel>(
              value: team,
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HomeColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (team.email == selected)
                    Icon(Icons.check, size: 20, color: AppColors.mediumBlue()),
                ],
              ),
            ),
        ];
      },
      // The chip only draws; the button opens the menu.
      child: IgnorePointer(
        child: HomeChip(
          label: label,
          icon: Icons.groups_outlined,
          showChevron: true,
        ),
      ),
    );
  }
}
