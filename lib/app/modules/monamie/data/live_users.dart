import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// The people of [users] who are sharing right now: `isTracked` and updated
/// within [validity] of [now]. The map draws only these.
List<UserModel> liveUsers(
  List<UserModel> users, {
  required DateTime now,
  required Duration validity,
}) {
  final limit = now.subtract(validity);
  return [
    for (final user in users)
      if (user.isTracked == true &&
          user.timestamp != null &&
          user.timestamp!.isAfter(limit))
        user,
  ];
}
