import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/tracking/sharing_times.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/call_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/person_row_tile.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/group_rows.dart';

/// The rows of [groupRows] for the observed group, read from the
/// controllers: the people publishing there today, or on a past day everyone
/// who ever published there (once read for the history).
List<GroupRow> observedGroupRows() {
  final groups = Get.find<GroupMapState>();
  final tracking = Get.find<TrackingController>();
  final today = Get.find<CalendarController>().isObservingToday;
  return groupRows(
    members: today || groups.historyMembers.isEmpty
        ? groups.observedMembers.toList()
        : groups.historyMembers.toList(),
    users: tracking.groupUsers.toList(),
    usersWithPoints: tracking.usersWithPointsOnObservedDay.toSet(),
    observingToday: today,
    now: DateTime.now(),
    validity: validity,
  );
}

/// The people of the observed group, each with a switch to draw their trail
/// and a button to call them on Google Meet.
class PeopleList extends StatelessWidget {
  const PeopleList({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = Get.find<GroupMapState>();
    final calls = Get.find<CallController>();
    final me = Get.find<UserController>().googleUser?.email;
    return Obx(() {
      final rows = observedGroupRows();
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
