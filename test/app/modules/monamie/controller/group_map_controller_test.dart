import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/groups/membership_source.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_controller.dart';
import 'package:monamie_app/app/modules/monamie/data/group_positions_source.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

@GenerateNiceMocks([
  MockSpec<MembershipSource>(),
  MockSpec<GroupPositionsSource>(),
])
import 'group_map_controller_test.mocks.dart';

const member = <String, Object?>{'email': 'ana@x.com', 'role': 'member'};
const admin = <String, Object?>{'email': 'ana@x.com', 'role': 'admin'};

late MockMembershipSource memberships;
late MockGroupPositionsSource positions;
late int accessLost;

// The streams [memberships] returns. Each buffers what the test adds until
// the controller listens.
late StreamController<Map<String, Object?>?> organization;
late StreamController<Map<String, Object?>> roles;
late StreamController<Map<String, String>> allNames;
late Map<String, StreamController<String?>> names;

/// The stream of group [groupId]'s name.
StreamController<String?> nameOf(String groupId) =>
    names.putIfAbsent(groupId, StreamController<String?>.new);

/// The people [positions] answers with, by group id.
late Map<String, List<UserModel>> groupPeople;

/// A [MockMembershipSource] answering from the streams above.
MockMembershipSource mockMemberships() {
  final source = MockMembershipSource();
  when(
    source.organizationMembership(any, any),
  ).thenAnswer((_) => organization.stream);
  when(source.groupRoles(any, any)).thenAnswer((_) => roles.stream);
  when(source.allGroupNames(any)).thenAnswer((_) => allNames.stream);
  when(source.groupName(any, any)).thenAnswer(
    (invocation) => nameOf(invocation.positionalArguments[1] as String).stream,
  );
  return source;
}

/// A [MockGroupPositionsSource] answering from [groupPeople].
MockGroupPositionsSource mockPositions() {
  final source = MockGroupPositionsSource();
  when(source.streamGroupPositions(any)).thenAnswer(
    (invocation) => Stream.value(
      groupPeople[invocation.positionalArguments[0]] ?? const [],
    ),
  );
  when(source.groupHistoryPeople(any)).thenAnswer(
    (invocation) async =>
        groupPeople[invocation.positionalArguments[0]] ?? const [],
  );
  when(source.countPublishers(any)).thenAnswer(
    (invocation) async =>
        groupPeople[invocation.positionalArguments[0]]?.length ?? 0,
  );
  return source;
}

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
    organization = StreamController<Map<String, Object?>?>();
    roles = StreamController<Map<String, Object?>>();
    allNames = StreamController<Map<String, String>>();
    names = {};
    groupPeople = {};
    memberships = mockMemberships();
    positions = mockPositions();
    accessLost = 0;
  });

  group('GroupMapController (memberships) - Unit Test Suite', () {
    test(
      'Happy Path: a subscriber sees their group on the map with its people',
      () async {
        // 1. Arrange
        organization.add(member);
        roles.add({
          'g1': ['subscriber'],
          'g2': ['publisher'],
        });
        nameOf('g1').add('Guias');
        nameOf('g2').add('Recepção');
        groupPeople['g1'] = [UserModel(email: 'vera@x.com', name: 'Vera')];

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
        organization.add(admin);
        roles.add({});
        allNames.add({'g2': 'Recepção', 'g1': 'Guias'});

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
      organization
        ..add(null)
        ..add(null);
      roles.add({
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
      organization.add(admin);
      roles.addError(StateError('index missing'));
      allNames.add({'g1': 'Guias'});

      // 2. Act
      final controller = await started();

      // 3. Assert
      expect(controller.mapGroups.map((g) => g.id), ['g1']);
      expect(controller.loadError.value, isNotEmpty);
    });

    test('Sad Path: nobody signed in reads nothing', () async {
      // 1. Arrange
      organization.add(member);

      // 2. Act
      final controller = await started(email: null);

      // 3. Assert
      expect(controller.loadError.value, 'not_authenticated');
      expect(controller.isLoading.value, isFalse);
      expect(organization.hasListener, isFalse);
    });

    test(
      'Sad Path: a plain member present on the server is never forgotten',
      () async {
        // 1. Arrange
        organization.add(member);
        roles.add({});

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
      organization.add(member);
      roles.add({
        'g1': ['subscriber'],
        'g2': ['subscriber'],
      });
      nameOf('g1').add('Guias');
      nameOf('g2').add('Recepção');
      return started();
    }

    test(
      'Happy Path: renaming the observed group shows the new name',
      () async {
        // 1. Arrange
        final controller = await watchingGuias();

        // 2. Act
        nameOf('g1').add('Guias Norte');
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
        roles.add({
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
      roles.add({
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
      nameOf('g2').add(null);
      await pumpEventQueue();

      // 3. Assert
      expect(controller.mapGroups.map((g) => g.id), ['g1']);
    });
  });

  group('GroupMapController.pickGroup - Unit Test Suite', () {
    Future<GroupMapController> watchingTwo() async {
      organization.add(member);
      roles.add({
        'g1': ['subscriber'],
        'g2': ['subscriber'],
      });
      nameOf('g1').add('Guias');
      nameOf('g2').add('Recepção');
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
      clearInteractions(positions);

      // 2. Act
      await controller.pickGroup(const MapGroup(id: 'g1', name: 'Guias'));

      // 3. Assert
      verifyNever(positions.streamGroupPositions(any));
    });

    test(
      'Sad Path: an unreadable history falls back to the people on the map',
      () async {
        // 1. Arrange
        groupPeople['g1'] = [UserModel(email: 'vera@x.com')];
        final controller = await watchingTwo();
        when(
          positions.groupHistoryPeople(any),
        ).thenAnswer((_) async => throw StateError('offline'));

        // 2. Act
        final members = await controller.loadHistoryMembers();

        // 3. Assert
        expect(members.map((m) => m.email), ['vera@x.com']);
      },
    );
  });
}
