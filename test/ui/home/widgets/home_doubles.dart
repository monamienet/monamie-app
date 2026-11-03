import 'package:flutter/foundation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';
import 'package:monamie_app/domain/models/capabilities.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/ui/home/view_models/home_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/domain/models/user_model.dart';

import '../../../../testing/fakes/repositories/fake_membership_repository.dart';
import '../../../../testing/fakes/repositories/fake_permissions_repository.dart';

@GenerateNiceMocks([
  MockSpec<CalendarViewModel>(),
  MockSpec<CallService>(),
  MockSpec<TrackingViewModel>(),
  MockSpec<UserViewModel>(),
])
import 'home_doubles.mocks.dart';

/// What the home widgets read, handed to them by the tests. [home] is a
/// real [HomeViewModel] over the in-memory [groups] and [permissions]
/// repositories and the [CallService] mock (it only passes their values
/// through); the calendar, tracking and user view models are mocks. The
/// repositories' values are their own [ValueNotifier]s (also reachable
/// here, e.g. [mapGroups]) and the calendar's and tracking's are plain
/// [ValueNotifier]s: the test changes them to drive the widgets.
class HomeDoubles {
  HomeDoubles() {
    when(calls.launchGoogleMeet(any)).thenAnswer((_) async {});

    when(calendar.observedDay).thenReturn(observedDay);
    when(calendar.isObservingToday).thenReturn(true);
    when(calendar.observedDayFormatted).thenReturn('Hoje');

    when(tracking.groupUsers).thenReturn(groupUsers);
    when(tracking.usersWithPointsOnObservedDay).thenReturn(usersWithPoints);
  }

  final groups = FakeMembershipRepository();
  final permissions = FakePermissionsRepository();
  final calendar = MockCalendarViewModel();
  final tracking = MockTrackingViewModel();
  final calls = MockCallService();
  final user = MockUserViewModel();

  /// The map screen's view model over [groups], [permissions] and [calls].
  late final home = HomeViewModel(
    membership: groups,
    permissions: permissions,
    calls: calls,
  );

  ValueNotifier<Capabilities> get capabilities => groups.capabilities;
  ValueNotifier<List<MapGroup>> get mapGroups => groups.mapGroups;
  ValueNotifier<List<MapGroup>> get publishGroups => groups.publishGroups;
  ValueNotifier<MapGroup?> get selectedGroup => groups.selectedGroup;
  ValueNotifier<List<GroupMember>> get observedMembers =>
      groups.observedMembers;
  ValueNotifier<List<GroupMember>> get historyMembers => groups.historyMembers;
  ValueNotifier<Map<String, int>> get groupSizes => groups.groupSizes;
  ValueNotifier<List<GroupMember>> get highlighted =>
      groups.highlightedObservedUsers;
  ValueNotifier<String?> get selectedMemberEmail => groups.selectedMemberEmail;
  ValueNotifier<bool> get switchingGroup => groups.switchingGroup;
  ValueNotifier<bool> get hasWhenInUse =>
      permissions.hasWhenInUseLocationPermission;
  ValueNotifier<bool> get hasAlways => permissions.hasAlwaysLocationPermission;
  ValueNotifier<bool> get hasNotification =>
      permissions.hasNotificationPermission;
  ValueNotifier<bool> get backgroundRestricted =>
      permissions.isBackgroundRestricted;
  final observedDay = ValueNotifier<DateTime>(DateTime(2026, 11, 2));
  final groupUsers = ValueNotifier<List<UserModel>>(const []);
  final usersWithPoints = ValueNotifier<Set<String>>(const {});
}

/// Capabilities of a subscriber of [groupId].
Capabilities watcherOf(String groupId) => Capabilities(
  isMember: true,
  rolesByGroup: {
    groupId: {GroupRoles.subscriber},
  },
);
