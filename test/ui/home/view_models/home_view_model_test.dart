import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/domain/models/capabilities.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/ui/home/view_models/home_view_model.dart';

@GenerateNiceMocks([
  MockSpec<CallService>(),
  MockSpec<MembershipRepository>(),
  MockSpec<PermissionsRepository>(),
])
import 'home_view_model_test.mocks.dart';

const _guias = MapGroup(id: 'g1', name: 'Guias');
const _bia = GroupMember(name: 'Bia', email: 'bia@example.com');
const _caio = GroupMember(name: 'Caio', email: 'caio@example.com');

void main() {
  late MockMembershipRepository membership;
  late MockPermissionsRepository permissions;
  late MockCallService calls;
  late ValueNotifier<List<GroupMember>> observed;
  late ValueNotifier<List<GroupMember>> history;
  late HomeViewModel home;

  setUp(() {
    membership = MockMembershipRepository();
    permissions = MockPermissionsRepository();
    calls = MockCallService();
    observed = ValueNotifier(const [_bia]);
    history = ValueNotifier(const []);
    when(membership.observedMembers).thenReturn(observed);
    when(membership.historyMembers).thenReturn(history);
    when(membership.pickGroup(any)).thenAnswer((_) async {});
    when(membership.loadGroupSizes()).thenAnswer((_) async {});
    when(calls.launchGoogleMeet(any)).thenAnswer((_) async {});
    home = HomeViewModel(
      membership: membership,
      permissions: permissions,
      calls: calls,
    );
  });

  tearDown(() {
    observed.dispose();
    history.dispose();
  });

  group('HomeViewModel (pass-through values) - Unit Test Suite', () {
    test("Happy Path: each value is the repository's own listenable", () {
      // 1. Arrange
      final capabilities = ValueNotifier(const Capabilities());
      final selected = ValueNotifier<MapGroup?>(_guias);
      final whenInUse = ValueNotifier(true);
      final restricted = ValueNotifier(false);
      addTearDown(capabilities.dispose);
      addTearDown(selected.dispose);
      addTearDown(whenInUse.dispose);
      addTearDown(restricted.dispose);
      when(membership.capabilities).thenReturn(capabilities);
      when(membership.selectedGroup).thenReturn(selected);
      when(permissions.hasWhenInUseLocationPermission).thenReturn(whenInUse);
      when(permissions.isBackgroundRestricted).thenReturn(restricted);

      // 2. Act & 3. Assert
      expect(home.capabilities, same(capabilities));
      expect(home.selectedGroup, same(selected));
      expect(home.observedMembers, same(observed));
      expect(home.historyMembers, same(history));
      expect(home.hasWhenInUseLocationPermission, same(whenInUse));
      expect(home.isBackgroundRestricted, same(restricted));
    });

    test('Edge Case: the capability getters ask the repository', () {
      // 1. Arrange
      when(membership.isAdmin).thenReturn(true);
      when(membership.canWatch).thenReturn(false);
      when(membership.canPublish).thenReturn(true);
      when(permissions.arePermissionsGranted()).thenReturn(true);

      // 2. Act & 3. Assert
      expect(home.isAdmin, isTrue);
      expect(home.canWatch, isFalse);
      expect(home.canPublish, isTrue);
      expect(home.arePermissionsGranted(), isTrue);
    });

    test('Sad Path: a change in a repository value never notifies the '
        'view model itself', () {
      // 1. Arrange
      var notifications = 0;
      home.addListener(() => notifications++);

      // 2. Act
      observed.value = const [_bia, _caio];

      // 3. Assert
      expect(home.observedMembers.value, const [_bia, _caio]);
      expect(notifications, 0);
    });
  });

  group('HomeViewModel.listedMembers - Unit Test Suite', () {
    test('Happy Path: today lists those publishing now', () {
      // 1. Arrange
      history.value = const [_bia, _caio];

      // 2. Act
      final listed = home.listedMembers(observingToday: true);

      // 3. Assert
      expect(listed, const [_bia]);
    });

    test('Edge Case: a past day lists everyone who ever published', () {
      // 1. Arrange
      history.value = const [_bia, _caio];

      // 2. Act
      final listed = home.listedMembers(observingToday: false);

      // 3. Assert
      expect(listed, const [_bia, _caio]);
    });

    test('Sad Path: a past day before the history is read lists those '
        'publishing now', () {
      // 1. Arrange & 2. Act
      final listed = home.listedMembers(observingToday: false);

      // 3. Assert
      expect(listed, const [_bia]);
    });
  });

  group('HomeViewModel (actions) - Unit Test Suite', () {
    test('Happy Path: call opens Google Meet for the e-mail', () async {
      // 1. Arrange & 2. Act
      await home.call('bia@example.com');

      // 3. Assert
      verify(calls.launchGoogleMeet('bia@example.com')).called(1);
    });

    test('Happy Path: the group actions reach the repository', () async {
      // 1. Arrange & 2. Act
      await home.pickGroup(_guias);
      await home.loadGroupSizes();
      home
        ..toggleHighlight(_bia)
        ..toggleSelected(_bia.email)
        ..clearSelected();

      // 3. Assert
      verifyInOrder([
        membership.pickGroup(_guias),
        membership.loadGroupSizes(),
        membership.toggleHighlight(_bia),
        membership.toggleSelected(_bia.email),
        membership.clearSelected(),
      ]);
    });

    test('Edge Case: isHighlighted asks the repository', () {
      // 1. Arrange
      when(membership.isHighlighted(_bia)).thenReturn(true);

      // 2. Act & 3. Assert
      expect(home.isHighlighted(_bia), isTrue);
      expect(home.isHighlighted(_caio), isFalse);
    });

    test('Happy Path: the permission requests reach the repository', () async {
      // 1. Arrange
      when(
        permissions.requestNotificationPermission(),
      ).thenAnswer((_) async {});
      when(permissions.requestWhenInUsePermission()).thenAnswer((_) async {});
      when(permissions.requestAlwaysPermission()).thenAnswer((_) async {});
      when(permissions.openBackgroundUsageSettings()).thenAnswer((_) async {});

      // 2. Act
      await home.requestNotificationPermission();
      await home.requestWhenInUsePermission();
      await home.requestAlwaysPermission();
      await home.openBackgroundUsageSettings();

      // 3. Assert
      verifyInOrder([
        permissions.requestNotificationPermission(),
        permissions.requestWhenInUsePermission(),
        permissions.requestAlwaysPermission(),
        permissions.openBackgroundUsageSettings(),
      ]);
    });

    test('Sad Path: a failing call reaches the caller', () async {
      // 1. Arrange
      when(calls.launchGoogleMeet(any)).thenThrow(Exception('no Meet'));

      // 2. Act & 3. Assert
      expect(() => home.call('bia@example.com'), throwsException);
    });
  });
}
