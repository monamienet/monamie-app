import 'package:flutter/material.dart';
import 'package:monamie_app/domain/models/sharing_times.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/home/widgets/person_row_tile.dart';
import 'package:monamie_app/ui/home/widgets/group_rows.dart';

/// The rows of [groupRows] for the observed group, read from the
/// controllers: the people publishing there today, or on a past day everyone
/// who ever published there (once read for the history).
List<GroupRow> observedGroupRows({
  required MembershipRepository groups,
  required TrackingViewModel tracking,
  required CalendarViewModel calendar,
}) {
  final today = calendar.isObservingToday;
  return groupRows(
    members: today || groups.historyMembers.value.isEmpty
        ? groups.observedMembers.value
        : groups.historyMembers.value,
    users: tracking.groupUsers.value,
    usersWithPoints: tracking.usersWithPointsOnObservedDay.value,
    observingToday: today,
    now: DateTime.now(),
    validity: validity,
  );
}

/// The people of the observed group, each with a switch to draw their trail
/// and a button to call them on Google Meet.
class PeopleList extends StatelessWidget {
  const PeopleList({
    super.key,
    required this.groups,
    required this.tracking,
    required this.calendar,
    required this.calls,
    required this.user,
  });

  final MembershipRepository groups;
  final TrackingViewModel tracking;
  final CalendarViewModel calendar;
  final CallService calls;
  final UserViewModel user;

  @override
  Widget build(BuildContext context) {
    final me = user.googleUser?.email;
    return ListenableBuilder(
      listenable: Listenable.merge([
        groups.observedMembers,
        groups.historyMembers,
        groups.highlightedObservedUsers,
        groups.selectedMemberEmail,
        calendar.observedDay,
        tracking.groupUsers,
        tracking.usersWithPointsOnObservedDay,
      ]),
      builder: (context, _) {
        final rows = observedGroupRows(
          groups: groups,
          tracking: tracking,
          calendar: calendar,
        );
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
      },
    );
  }
}
