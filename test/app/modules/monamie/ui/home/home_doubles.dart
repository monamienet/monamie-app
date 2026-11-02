import 'package:flutter/foundation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/call_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

@GenerateNiceMocks([
  MockSpec<CalendarController>(),
  MockSpec<CallController>(),
  MockSpec<GroupMapState>(),
  MockSpec<TrackingController>(),
  MockSpec<UserController>(),
])
import 'home_doubles.mocks.dart';

/// The home controllers as mocks, handed to the widgets by the tests. The
/// [GroupMapState], calendar and tracking values are plain [ValueNotifier]s the test
/// changes to drive the widgets; the capability getters follow
/// [capabilities].
class HomeDoubles {
  HomeDoubles() {
    when(groups.capabilities).thenReturn(capabilities);
    when(groups.canWatch).thenAnswer((_) => capabilities.value.canWatch);
    when(groups.canPublish).thenAnswer((_) => capabilities.value.canPublish);
    when(groups.isAdmin).thenAnswer((_) => capabilities.value.isAdmin);
    when(groups.mapGroups).thenReturn(mapGroups);
    when(groups.publishGroups).thenReturn(publishGroups);
    when(groups.selectedGroup).thenReturn(selectedGroup);
    when(groups.observedMembers).thenReturn(observedMembers);
    when(groups.historyMembers).thenReturn(historyMembers);
    when(groups.groupSizes).thenReturn(groupSizes);
    when(groups.highlightedObservedUsers).thenReturn(highlighted);
    when(groups.selectedMemberEmail).thenReturn(selectedMemberEmail);
    when(groups.isHighlighted(any)).thenAnswer(
      (invocation) => highlighted.value.any(
        (m) =>
            m.email == (invocation.positionalArguments[0] as GroupMember).email,
      ),
    );
    when(groups.loadGroupSizes()).thenAnswer((_) async {});
    when(groups.pickGroup(any)).thenAnswer((_) async {});

    when(calendar.observedDay).thenReturn(observedDay);
    when(calendar.isObservingToday).thenReturn(true);
    when(calendar.observedDayFormatted).thenReturn('Hoje');

    when(tracking.groupUsers).thenReturn(groupUsers);
    when(tracking.usersWithPointsOnObservedDay).thenReturn(usersWithPoints);
  }

  final groups = MockGroupMapState();
  final calendar = MockCalendarController();
  final tracking = MockTrackingController();
  final calls = MockCallController();
  final user = MockUserController();

  final capabilities = ValueNotifier<Capabilities>(const Capabilities());
  final mapGroups = ValueNotifier<List<MapGroup>>(const []);
  final publishGroups = ValueNotifier<List<MapGroup>>(const []);
  final selectedGroup = ValueNotifier<MapGroup?>(null);
  final observedMembers = ValueNotifier<List<GroupMember>>(const []);
  final historyMembers = ValueNotifier<List<GroupMember>>(const []);
  final groupSizes = ValueNotifier<Map<String, int>>(const {});
  final highlighted = ValueNotifier<List<GroupMember>>(const []);
  final selectedMemberEmail = ValueNotifier<String?>(null);
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
