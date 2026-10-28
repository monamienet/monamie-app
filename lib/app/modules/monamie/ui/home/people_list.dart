import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/tracking/sharing_times.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/call_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/person_row_tile.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/team_rows.dart';

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
    validity: validity,
  );
}

/// The people of the observed team, each with a switch to draw their trail
/// and a button to call them on Google Meet.
class PeopleList extends StatelessWidget {
  const PeopleList({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = Get.find<GoogleGroupsController>();
    final calls = Get.find<CallController>();
    final me = Get.find<UserController>().googleUser?.email;
    return Obx(() {
      final rows = observedTeamRows();
      return Column(
        children: [
          for (final row in rows)
            PersonRowTile(
              row: row,
              highlighted: groups.isHighlighted(row.member),
              selected: groups.selectedMemberEmail.value == row.member.email,
              onToggleTrail: () => groups.toggleHighlight(row.member),
              onCall: row.member.email == me
                  ? null
                  : () => calls.launchGoogleMeet(row.member.email),
            ),
        ],
      );
    });
  }
}
