import 'package:flutter/foundation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';
import 'package:monamie_app/domain/models/capabilities.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/domain/models/user_model.dart';

@GenerateNiceMocks([
  MockSpec<CalendarViewModel>(),
  MockSpec<CallService>(),
  MockSpec<MembershipRepository>(),
  MockSpec<TrackingViewModel>(),
  MockSpec<UserViewModel>(),
])
import 'home_doubles.mocks.dart';

/// The home view models and the memberships repository as mocks, handed to the widgets by the tests. The
/// [MembershipRepository], calendar and tracking values are plain [ValueNotifier]s the test
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

  final groups = MockMembershipRepository();
  final calendar = MockCalendarViewModel();
  final tracking = MockTrackingViewModel();
  final calls = MockCallService();
  final user = MockUserViewModel();

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
