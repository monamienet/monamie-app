import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// The people of [users] who are sharing right now: `isPublishing` and updated
/// within [validity] of [now]. The map draws only these.
List<UserModel> liveUsers(
  List<UserModel> users, {
  required DateTime now,
  required Duration validity,
}) {
  final limit = now.subtract(validity);
  return [
    for (final user in users)
      if (user.isPublishing == true &&
          user.capturedAt != null &&
          user.capturedAt!.isAfter(limit))
        user,
  ];
}
