import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/ui/core/ui/organization_icon.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/home_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/history/widgets/history_calendar_sheet.dart';
import 'package:monamie_app/ui/home/widgets/home_chip.dart';
import 'package:monamie_app/ui/home/widgets/home_layout.dart';
import 'package:monamie_app/ui/home/widgets/initials.dart';
import 'package:monamie_app/ui/home/widgets/group_menu_button.dart';
import 'package:monamie_app/ui/core/themes/color_palette.dart';

/// The home app bar: menu, the organization, the person, and under them the
/// group chip and (for people who watch) the day chip.
///
/// The group chip is what answers "which group am I with?" for everyone: a
/// person who watches picks it, a person who only shares sees theirs.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.home,
    required this.user,
    required this.calendar,
  });

  final HomeViewModel home;
  final UserViewModel user;
  final CalendarViewModel calendar;

  HomeViewModel get _home => home;
  UserViewModel get _user => user;
  CalendarViewModel get _calendar => calendar;

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
                    child: ListenableBuilder(
                      listenable: _user,
                      builder: (context, _) => _avatar(),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    _home.capabilities,
                    _home.selectedGroup,
                    _home.publishGroups,
                    _calendar.observedDay,
                  ]),
                  builder: (context, _) => Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _groupChip(),
                      if (_home.canWatch) ..._dayChips(),
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

  Widget _groupChip() {
    final canWatch = _home.canWatch;
    final label = groupChipLabel(
      canWatch: canWatch,
      observedGroup: _home.selectedGroup.value?.name,
      publishGroups: [
        for (final group in _home.publishGroups.value) group.name,
      ],
    );
    if (canWatch) return GroupMenuButton(home: _home, label: label);
    return HomeChip(label: label, semanticsLabel: 'Grupo: $label');
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
          onTap: () {
            _calendar.showObservedMonth();
            HistoryCalendarSheet.show(context, _calendar);
          },
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
