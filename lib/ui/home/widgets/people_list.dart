import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/domain/models/sharing_times.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/home_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/home/widgets/person_row_tile.dart';
import 'package:monamie_app/ui/home/widgets/group_rows.dart';

/// The rows of [groupRows] for the observed group, read from the
/// controllers: the people publishing there today, or on a past day everyone
/// who ever published there (once read for the history), in [l10n]'s
/// language.
List<GroupRow> observedGroupRows(
  AppLocalizations l10n, {
  required HomeViewModel home,
  required TrackingViewModel tracking,
  required CalendarViewModel calendar,
}) {
  final today = calendar.isObservingToday;
  return groupRows(
    l10n,
    members: home.listedMembers(observingToday: today),
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
    required this.home,
    required this.tracking,
    required this.calendar,
    required this.user,
  });

  final HomeViewModel home;
  final TrackingViewModel tracking;
  final CalendarViewModel calendar;
  final UserViewModel user;

  @override
  Widget build(BuildContext context) {
    final me = user.googleUser?.email;
    return ListenableBuilder(
      listenable: Listenable.merge([
        home.observedMembers,
        home.historyMembers,
        home.highlightedObservedUsers,
        home.selectedMemberEmail,
        calendar.observedDay,
        tracking.groupUsers,
        tracking.usersWithPointsOnObservedDay,
      ]),
      builder: (context, _) {
        final rows = observedGroupRows(
          AppLocalizations.of(context),
          home: home,
          tracking: tracking,
          calendar: calendar,
        );
        return Column(
          children: [
            for (final row in rows)
              PersonRowTile(
                row: row,
                highlighted: home.isHighlighted(row.member),
                selected: home.selectedMemberEmail.value == row.member.email,
                onToggleTrail: () => home.toggleHighlight(row.member),
                onCall: row.member.email == me
                    ? null
                    : () => home.call(row.member.email),
              ),
          ],
        );
      },
    );
  }
}
