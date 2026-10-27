import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_colors.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/initials.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/presence.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/team_rows.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// The rows of [teamRows] for the observed team, read from the controllers.
List<TeamRow> observedTeamRows() {
  final groups = Get.find<GoogleGroupsController>();
  final tracking = Get.find<TrackingController>();
  return teamRows(
    members: groups.observedMembers.toList(),
    users: tracking.teamUsers.toList(),
    usersWithPoints: tracking.usersWithPointsOnObservedDay.toSet(),
    observingToday: Get.find<CalendarController>().isObservingToday,
    now: DateTime.now(),
    staleAfter: Get.find<TrackingSettingsController>().staleAfter,
  );
}

/// The people of the observed team, with a switch to draw each one's trail.
class PeopleList extends StatelessWidget {
  const PeopleList({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = Get.find<GoogleGroupsController>();
    final tracking = Get.find<TrackingController>();
    return Obx(() {
      final rows = observedTeamRows();
      return Column(
        children: [
          for (final row in rows)
            _PersonRow(
              row: row,
              highlighted: groups.isHighlighted(row.member),
              onTap: row.user == null
                  ? null
                  : () => tracking.openFirebaseUserDetails(row.user!),
              onToggleTrail: () => groups.toggleHighlight(row.member),
            ),
        ],
      );
    });
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.row,
    required this.highlighted,
    required this.onTap,
    required this.onToggleTrail,
  });

  final TeamRow row;
  final bool highlighted;
  final VoidCallback? onTap;
  final VoidCallback onToggleTrail;

  @override
  Widget build(BuildContext context) {
    final kind = row.presence.kind;
    final name = row.member.name;
    final live = kind == PresenceKind.live;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              _Avatar(initials: initialsOf(name), kind: kind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HomeColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      highlighted && live
                          ? '${row.presence.label} · trajeto visível'
                          : row.presence.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: live ? AppColors.darkBlue() : HomeColors.muted,
                        fontSize: 12,
                        fontWeight: live ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: highlighted
                    ? 'Esconder trajeto de $name'
                    : 'Mostrar trajeto de $name',
                child: Semantics(
                  button: true,
                  toggled: highlighted,
                  label: highlighted
                      ? 'Esconder trajeto de $name'
                      : 'Mostrar trajeto de $name',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onToggleTrail,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: highlighted
                            ? AppColors.lightBlue()
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: highlighted
                            ? null
                            : Border.all(color: HomeColors.outline, width: 1.5),
                      ),
                      child: Icon(
                        Icons.timeline,
                        size: 20,
                        color: highlighted
                            ? AppColors.darkBlue()
                            : HomeColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.kind});

  final String initials;
  final PresenceKind kind;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    BoxBorder? border;
    switch (kind) {
      case PresenceKind.live:
        background = AppColors.mediumBlue();
        foreground = AppColors.onPrimary;
      case PresenceKind.stale:
        background = HomeColors.offline;
        foreground = Colors.white;
      case PresenceKind.off:
      case PresenceKind.never:
        background = HomeColors.surface;
        foreground = HomeColors.muted;
        border = Border.all(color: HomeColors.handle, width: 1.5);
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
