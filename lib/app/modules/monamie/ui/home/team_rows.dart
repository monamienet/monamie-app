import 'package:monamie_app/app/modules/monamie/models/google_group_member_model.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/presence.dart';

/// One line of the team list: a member of the observed team, their live
/// document (when they have one) and how fresh it is.
class TeamRow {
  const TeamRow({
    required this.member,
    required this.user,
    required this.presence,
  });

  final GoogleGroupMember member;
  final UserModel? user;
  final Presence presence;
}

/// The team list, the people sharing first.
///
/// Today the line says whether each person is sharing now; on a past day it
/// says whether they have positions that day ([usersWithPoints]). Within the
/// same presence the order of [members] is kept.
List<TeamRow> teamRows({
  required List<GoogleGroupMember> members,
  required List<UserModel> users,
  required Set<String> usersWithPoints,
  required bool observingToday,
  required DateTime now,
  required Duration validity,
}) {
  final byEmail = {for (final user in users) user.email: user};
  final rows = [
    for (final member in members)
      TeamRow(
        member: member,
        user: byEmail[member.email],
        presence: observingToday
            ? presenceOf(
                hasRecord: byEmail.containsKey(member.email),
                isTracked: byEmail[member.email]?.isTracked,
                lastSeen: byEmail[member.email]?.timestamp,
                now: now,
                validity: validity,
              )
            : dayPresence(hasPoints: usersWithPoints.contains(member.email)),
      ),
  ];
  // List.sort is not stable, so the index breaks ties.
  final indexed = [for (var i = 0; i < rows.length; i++) (i, rows[i])];
  indexed.sort((a, b) {
    final byKind = a.$2.presence.kind.index.compareTo(b.$2.presence.kind.index);
    return byKind != 0 ? byKind : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}
