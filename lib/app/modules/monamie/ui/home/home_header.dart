import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_icon.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_chip.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_layout.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/initials.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/team_menu_button.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// The home app bar: menu, the organization, the person, and under them the
/// team chip and (for people who watch) the day chip.
///
/// The team chip is what answers "which team am I with?" for everyone: a
/// person who watches picks it, a person who only shares sees theirs.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  GoogleGroupsController get _groups => Get.find<GoogleGroupsController>();
  UserController get _user => Get.find<UserController>();
  CalendarController get _calendar => Get.find<CalendarController>();

  @override
  Widget build(BuildContext context) {
    final onDark = AppColors.onPrimaryDark;
    return Material(
      color: AppColors.darkBlue(),
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Menu',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    icon: Icon(Icons.menu, color: onDark),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(width: 4),
                  OrganizationIcon(
                    organization: Organization.current,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Organization.current?.name ?? MonAmieBrand.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Obx(() => _avatar()),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Obx(
                  () => Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _teamChip(),
                      if (_groups.canWatch) ..._dayChips(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamChip() {
    final canWatch = _groups.canWatch;
    final label = teamChipLabel(
      canWatch: canWatch,
      observedTeam: _groups.selectedGroup.value?.name,
      shareTeams: [for (final team in _groups.shareTeams) team.name],
    );
    if (canWatch) return TeamMenuButton(label: label);
    return HomeChip(label: label, semanticsLabel: 'Equipe: $label');
  }

  List<Widget> _dayChips() {
    final isToday = _calendar.isObservingToday;
    final day = _calendar.observedDayFormatted;
    return [
      Builder(
        builder: (context) => HomeChip(
          label: day,
          icon: Icons.calendar_month_outlined,
          semanticsLabel: 'Histórico por data, $day',
          onTap: () => _calendar.pickDay(context),
        ),
      ),
      if (!isToday)
        HomeChip(label: 'Voltar para hoje', onTap: _calendar.goToToday),
    ];
  }

  Widget _avatar() {
    final user = _user.googleUser;
    final base64 = user?.avatarBase64;
    if (base64 != null && base64.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          base64Decode(base64),
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.lightBlue(),
      child: Text(
        initialsOf(user?.name ?? user?.email ?? ''),
        style: TextStyle(
          color: AppColors.darkBlue(),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
