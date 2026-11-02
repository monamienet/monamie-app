import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/groups/membership_source.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_controller.dart';
import 'package:monamie_app/app/modules/monamie/data/group_positions_source.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// [MembershipSource] fed by hand: each stream buffers what the test adds
/// until the controller listens.
class FakeMembershipSource implements MembershipSource {
  final organization = StreamController<Map<String, Object?>?>();
  final roles = StreamController<Map<String, Object?>>();
  final allNames = StreamController<Map<String, String>>();
  final names = <String, StreamController<String?>>{};

  /// The stream of group [groupId]'s name.
  StreamController<String?> name(String groupId) =>
      names.putIfAbsent(groupId, StreamController<String?>.new);

  @override
  Stream<Map<String, Object?>?> organizationMembership(
    String organizationId,
    String email,
  ) => organization.stream;

  @override
  Stream<Map<String, Object?>> groupRoles(
    String organizationId,
    String email,
  ) => roles.stream;

  @override
  Stream<Map<String, String>> allGroupNames(String organizationId) =>
      allNames.stream;

  @override
  Stream<String?> groupName(String organizationId, String groupId) =>
      name(groupId).stream;
}

/// [GroupPositionsSource] answering from [positions] by group id and
/// recording which groups the map listened to.
class FakePositionsSource implements GroupPositionsSource {
  final positions = <String, List<UserModel>>{};
  final streamed = <String>[];
  Object? historyError;

  @override
  Stream<List<UserModel>> streamGroupPositions(String groupId) {
    streamed.add(groupId);
    return Stream.value(positions[groupId] ?? const []);
  }

  @override
  Future<List<UserModel>> groupHistoryPeople(String groupId) async {
    if (historyError case final error?) throw error;
    return positions[groupId] ?? const [];
  }

  @override
  Future<int> countPublishers(String groupId) async =>
      positions[groupId]?.length ?? 0;
}

const member = <String, Object?>{'email': 'ana@x.com', 'role': 'member'};
const admin = <String, Object?>{'email': 'ana@x.com', 'role': 'admin'};

late FakeMembershipSource memberships;
late FakePositionsSource positions;
late int accessLost;

/// A started controller for Ana in Rota Sul ([email] `null`: nobody signed
/// in).
Future<GroupMapController> started({String? email = 'ana@x.com'}) async {
  final controller = GroupMapController(
    memberships: memberships,
    positions: positions,
    onAccessLost: () async => accessLost++,
    organizationId: () => 'rotasul',
    email: () => email,
  );
  controller.onStart();
  await pumpEventQueue();
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    memberships = FakeMembershipSource();
    positions = FakePositionsSource();
    accessLost = 0;
  });

  group('GroupMapController (memberships) - Unit Test Suite', () {
    test(
      'Happy Path: a subscriber sees their group on the map with its people',
      () async {
        // 1. Arrange
        memberships.organization.add(member);
        memberships.roles.add({
          'g1': ['subscriber'],
          'g2': ['publisher'],
        });
        memberships.name('g1').add('Guias');
        memberships.name('g2').add('Recepção');
        positions.positions['g1'] = [
          UserModel(email: 'vera@x.com', name: 'Vera'),
        ];

        // 2. Act
        final controller = await started();

        // 3. Assert
        expect(controller.isLoading.value, isFalse);
        expect(controller.mapGroups, [const MapGroup(id: 'g1', name: 'Guias')]);
        expect(controller.publishGroups, [
          const MapGroup(id: 'g2', name: 'Recepção'),
        ]);
        expect(controller.selectedGroup.value?.id, 'g1');
        expect(controller.observedMembers.single.email, 'vera@x.com');
      },
    );

    test(
      'Happy Path: an administrator in no group sees every group, by name',
      () async {
        // 1. Arrange
        memberships.organization.add(admin);
        memberships.roles.add({});
        memberships.allNames.add({'g2': 'Recepção', 'g1': 'Guias'});

        // 2. Act
        final controller = await started();

        // 3. Assert
        expect(controller.isAdmin, isTrue);
        expect(controller.mapGroups.map((g) => g.name), ['Guias', 'Recepção']);
      },
    );

    test('Edge Case: a missing organization membership forgets the '
        'organization once', () async {
      // 1. Arrange
      memberships.organization
        ..add(null)
        ..add(null);
      memberships.roles.add({
        'g1': ['subscriber'],
      });

      // 2. Act
      final controller = await started();

      // 3. Assert
      expect(accessLost, 1);
      expect(controller.canWatch, isFalse);
    });

    test('Edge Case: an administrator whose groups cannot be read still sees '
        'every group', () async {
      // 1. Arrange
      memberships.organization.add(admin);
      memberships.roles.addError(StateError('index missing'));
      memberships.allNames.add({'g1': 'Guias'});

      // 2. Act
      final controller = await started();

      // 3. Assert
      expect(controller.mapGroups.map((g) => g.id), ['g1']);
      expect(controller.loadError.value, isNotEmpty);
    });

    test('Sad Path: nobody signed in reads nothing', () async {
      // 1. Arrange
      memberships.organization.add(member);

      // 2. Act
      final controller = await started(email: null);

      // 3. Assert
      expect(controller.loadError.value, 'not_authenticated');
      expect(controller.isLoading.value, isFalse);
      expect(memberships.organization.hasListener, isFalse);
    });

    test(
      'Sad Path: a plain member present on the server is never forgotten',
      () async {
        // 1. Arrange
        memberships.organization.add(member);
        memberships.roles.add({});

        // 2. Act
        final controller = await started();

        // 3. Assert
        expect(accessLost, 0);
        expect(controller.capabilities.value.isMember, isTrue);
      },
    );
  });

  group('GroupMapController (live changes) - Unit Test Suite', () {
    Future<GroupMapController> watchingGuias() async {
      memberships.organization.add(member);
      memberships.roles.add({
        'g1': ['subscriber'],
        'g2': ['subscriber'],
      });
      memberships.name('g1').add('Guias');
      memberships.name('g2').add('Recepção');
      return started();
    }

    test(
      'Happy Path: renaming the observed group shows the new name',
      () async {
        // 1. Arrange
        final controller = await watchingGuias();

        // 2. Act
        memberships.name('g1').add('Guias Norte');
        await pumpEventQueue();

        // 3. Assert
        expect(
          controller.selectedGroup.value,
          const MapGroup(id: 'g1', name: 'Guias Norte'),
        );
      },
    );

    test(
      'Edge Case: losing the observed group moves the map to the one left',
      () async {
        // 1. Arrange
        final controller = await watchingGuias();

        // 2. Act
        memberships.roles.add({
          'g2': ['subscriber'],
        });
        await pumpEventQueue();

        // 3. Assert
        expect(controller.selectedGroup.value?.id, 'g2');
      },
    );

    test('Sad Path: losing every subscriber role empties the map', () async {
      // 1. Arrange
      final controller = await watchingGuias();

      // 2. Act
      memberships.roles.add({
        'g1': ['publisher'],
      });
      await pumpEventQueue();

      // 3. Assert
      expect(controller.mapGroups, isEmpty);
      expect(controller.selectedGroup.value, isNull);
      expect(controller.groupPositions, isEmpty);
    });

    test('Sad Path: a group deleted meanwhile leaves the list', () async {
      // 1. Arrange
      final controller = await watchingGuias();

      // 2. Act
      memberships.name('g2').add(null);
      await pumpEventQueue();

      // 3. Assert
      expect(controller.mapGroups.map((g) => g.id), ['g1']);
    });
  });

  group('GroupMapController.pickGroup - Unit Test Suite', () {
    Future<GroupMapController> watchingTwo() async {
      memberships.organization.add(member);
      memberships.roles.add({
        'g1': ['subscriber'],
        'g2': ['subscriber'],
      });
      memberships.name('g1').add('Guias');
      memberships.name('g2').add('Recepção');
      return started();
    }

    test('Happy Path: picking another group puts it on the map', () async {
      // 1. Arrange
      final controller = await watchingTwo();

      // 2. Act
      await controller.pickGroup(const MapGroup(id: 'g2', name: 'Recepção'));

      // 3. Assert
      expect(controller.selectedGroup.value?.id, 'g2');
      expect(controller.switchingGroup.value, isFalse);
    });

    test('Edge Case: picking the observed group again does nothing', () async {
      // 1. Arrange
      final controller = await watchingTwo();
      positions.streamed.clear();

      // 2. Act
      await controller.pickGroup(const MapGroup(id: 'g1', name: 'Guias'));

      // 3. Assert
      expect(positions.streamed, isEmpty);
    });

    test(
      'Sad Path: an unreadable history falls back to the people on the map',
      () async {
        // 1. Arrange
        positions.positions['g1'] = [UserModel(email: 'vera@x.com')];
        final controller = await watchingTwo();
        positions.historyError = StateError('offline');

        // 2. Act
        final members = await controller.loadHistoryMembers();

        // 3. Assert
        expect(members.map((m) => m.email), ['vera@x.com']);
      },
    );
  });
}
