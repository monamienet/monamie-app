import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/groups/membership_source.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_controller.dart';
import 'package:monamie_app/app/modules/monamie/data/group_positions_source.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
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
  controller.start();
  await pumpEventQueue();
  return controller;
}

/// Counts the notifications of [listenable] from now on.
class Notifications {
  Notifications(Listenable listenable) {
    listenable.addListener(_count);
  }

  int count = 0;
  void _count() => count++;
}

/// A controller watching Guias (`g1`, where Ana subscribes and publishes)
/// whose positions arrive through the returned stream, which already
/// delivered Vera.
Future<(GroupMapController, StreamController<List<UserModel>>)>
watchingLive() async {
  final live = StreamController<List<UserModel>>();
  when(positions.streamGroupPositions('g1')).thenAnswer((_) => live.stream);
  organization.add(member);
  roles.add({
    'g1': ['publisher', 'subscriber'],
  });
  nameOf('g1').add('Guias');
  live.add([UserModel(email: 'vera@x.com', name: 'Vera')]);
  final controller = await started();
  return (controller, live);
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
        expect(controller.mapGroups.value, [
          const MapGroup(id: 'g1', name: 'Guias'),
        ]);
        expect(controller.publishGroups.value, [
          const MapGroup(id: 'g2', name: 'Recepção'),
        ]);
        expect(controller.selectedGroup.value?.id, 'g1');
        expect(controller.observedMembers.value.single.email, 'vera@x.com');
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
        expect(controller.mapGroups.value.map((g) => g.name), [
          'Guias',
          'Recepção',
        ]);
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
      expect(controller.mapGroups.value.map((g) => g.id), ['g1']);
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
      expect(controller.mapGroups.value, isEmpty);
      expect(controller.selectedGroup.value, isNull);
      expect(controller.groupPositions.value, isEmpty);
    });

    test('Sad Path: a group deleted meanwhile leaves the list', () async {
      // 1. Arrange
      final controller = await watchingGuias();

      // 2. Act
      nameOf('g2').add(null);
      await pumpEventQueue();

      // 3. Assert
      expect(controller.mapGroups.value.map((g) => g.id), ['g1']);
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

  group('GroupMapController (notifies on change) - Unit Test Suite', () {
    test('Happy Path: a snapshot with a new person notifies the positions and '
        'the people once each', () async {
      // 1. Arrange
      final (controller, live) = await watchingLive();
      final positionsChanged = Notifications(controller.groupPositions);
      final membersChanged = Notifications(controller.observedMembers);

      // 2. Act
      live.add([
        UserModel(email: 'vera@x.com', name: 'Vera'),
        UserModel(email: 'bia@x.com', name: 'Bia'),
      ]);
      await pumpEventQueue();

      // 3. Assert
      expect(positionsChanged.count, 1);
      expect(membersChanged.count, 1);
      expect(controller.observedMembers.value.map((m) => m.email), [
        'bia@x.com',
        'vera@x.com',
      ]);
    });

    test('Edge Case: a new snapshot with the same positions notifies none of '
        'the values it feeds', () async {
      // 1. Arrange
      final (controller, live) = await watchingLive();
      final positionsChanged = Notifications(controller.groupPositions);
      final membersChanged = Notifications(controller.observedMembers);
      final sizesChanged = Notifications(controller.groupSizes);

      // 2. Act
      live.add([UserModel(email: 'vera@x.com', name: 'Vera')]);
      await pumpEventQueue();

      // 3. Assert
      expect(positionsChanged.count, 0);
      expect(membersChanged.count, 0);
      expect(sizesChanged.count, 0);
    });

    test('Edge Case: a new snapshot with the same roles notifies neither the '
        'capabilities nor the groups', () async {
      // 1. Arrange
      final (controller, _) = await watchingLive();
      final capabilitiesChanged = Notifications(controller.capabilities);
      final mapGroupsChanged = Notifications(controller.mapGroups);
      final publishGroupsChanged = Notifications(controller.publishGroups);
      final selectedChanged = Notifications(controller.selectedGroup);

      // 2. Act
      roles.add({
        'g1': ['publisher', 'subscriber'],
      });
      await pumpEventQueue();

      // 3. Assert
      expect(capabilitiesChanged.count, 0);
      expect(mapGroupsChanged.count, 0);
      expect(publishGroupsChanged.count, 0);
      expect(selectedChanged.count, 0);
    });

    test('Edge Case: the same group name read again notifies neither the '
        'groups nor the observed group', () async {
      // 1. Arrange
      final (controller, _) = await watchingLive();
      final mapGroupsChanged = Notifications(controller.mapGroups);
      final selectedChanged = Notifications(controller.selectedGroup);

      // 2. Act
      nameOf('g1').add('Guias');
      await pumpEventQueue();

      // 3. Assert
      expect(mapGroupsChanged.count, 0);
      expect(selectedChanged.count, 0);
    });

    test('Happy Path: a role gained notifies the capabilities once', () async {
      // 1. Arrange
      final (controller, _) = await watchingLive();
      final capabilitiesChanged = Notifications(controller.capabilities);

      // 2. Act
      roles.add({
        'g1': ['maintainer', 'publisher', 'subscriber'],
      });
      await pumpEventQueue();

      // 3. Assert
      expect(capabilitiesChanged.count, 1);
      expect(controller.capabilities.value.maintainerGroupIds, ['g1']);
    });

    test(
      'Sad Path: the same counted size notifies the group sizes no more',
      () async {
        // 1. Arrange
        final (controller, _) = await watchingLive();
        when(positions.countPublishers('g1')).thenAnswer((_) async => 1);
        final sizesChanged = Notifications(controller.groupSizes);

        // 2. Act
        await controller.loadGroupSizes();

        // 3. Assert
        expect(controller.groupSizes.value, {'g1': 1});
        expect(sizesChanged.count, 0);
      },
    );
  });

  group('GroupMapController (unmodifiable values) - Unit Test Suite', () {
    const bia = GroupMember(name: 'Bia', email: 'bia@x.com');
    final cases = <String, void Function(GroupMapController)>{
      'mapGroups': (c) =>
          c.mapGroups.value.add(const MapGroup(id: 'g9', name: 'Intrusos')),
      'publishGroups': (c) => c.publishGroups.value.clear(),
      'groupPositions': (c) =>
          c.groupPositions.value.add(UserModel(email: 'bia@x.com')),
      'observedMembers': (c) => c.observedMembers.value.add(bia),
      'groupSizes': (c) => c.groupSizes.value['g9'] = 3,
      'highlightedObservedUsers': (c) =>
          c.highlightedObservedUsers.value.add(bia),
    };
    for (final MapEntry(key: name, value: mutate) in cases.entries) {
      test('Sad Path: $name cannot be changed in place', () async {
        // 1. Arrange
        final (controller, _) = await watchingLive();
        controller.toggleHighlight(
          const GroupMember(name: 'Vera', email: 'vera@x.com'),
        );

        // 2. Act
        void act() => mutate(controller);

        // 3. Assert
        expect(act, throwsUnsupportedError);
      });
    }

    test('Sad Path: historyMembers cannot be changed in place', () async {
      // 1. Arrange
      final (controller, _) = await watchingLive();
      when(
        positions.groupHistoryPeople('g1'),
      ).thenAnswer((_) async => [UserModel(email: 'vera@x.com', name: 'Vera')]);
      await controller.loadHistoryMembers();

      // 2. Act
      void act() => controller.historyMembers.value.add(bia);

      // 3. Assert
      expect(act, throwsUnsupportedError);
    });
  });

  group('GroupMapController (start and dispose) - Unit Test Suite', () {
    test('Edge Case: start() a second time listens to nothing more', () async {
      // 1. Arrange
      organization.add(member);
      roles.add({});
      final controller = await started();

      // 2. Act
      controller.start();
      await pumpEventQueue();

      // 3. Assert
      verify(memberships.organizationMembership(any, any)).called(1);
      verify(memberships.groupRoles(any, any)).called(1);
    });

    test('Happy Path: dispose() cancels the memberships, the group names and '
        'the positions', () async {
      // 1. Arrange
      final (controller, live) = await watchingLive();

      // 2. Act
      controller.dispose();
      await pumpEventQueue();

      // 3. Assert
      expect(organization.hasListener, isFalse);
      expect(roles.hasListener, isFalse);
      expect(nameOf('g1').hasListener, isFalse);
      expect(live.hasListener, isFalse);
    });

    test('Happy Path: dispose() cancels the list of every group an '
        'administrator follows', () async {
      // 1. Arrange
      organization.add(admin);
      roles.add({});
      allNames.add({'g1': 'Guias'});
      final controller = await started();

      // 2. Act
      controller.dispose();
      await pumpEventQueue();

      // 3. Assert
      expect(allNames.hasListener, isFalse);
    });

    test('Edge Case: dispose() a second time does not throw', () async {
      // 1. Arrange
      final (controller, _) = await watchingLive();
      controller.dispose();

      // 2. Act
      void act() => controller.dispose();

      // 3. Assert
      expect(act, returnsNormally);
    });

    test('Sad Path: a history read answered after dispose() is returned '
        'without notifying', () async {
      // 1. Arrange
      final (controller, _) = await watchingLive();
      final answer = Completer<List<UserModel>>();
      when(positions.groupHistoryPeople('g1')).thenAnswer((_) => answer.future);
      final historyChanged = Notifications(controller.historyMembers);
      final pending = controller.loadHistoryMembers();
      controller.dispose();

      // 2. Act
      answer.complete([UserModel(email: 'bia@x.com', name: 'Bia')]);
      final members = await pending;

      // 3. Assert
      expect(members.map((m) => m.email), ['bia@x.com']);
      expect(historyChanged.count, 0);
    });

    test(
      'Sad Path: a group count answered after dispose() does not throw',
      () async {
        // 1. Arrange
        final (controller, _) = await watchingLive();
        final answer = Completer<int>();
        when(positions.countPublishers('g1')).thenAnswer((_) => answer.future);
        final pending = controller.loadGroupSizes();
        controller.dispose();

        // 2. Act
        answer.complete(7);

        // 3. Assert
        await expectLater(pending, completes);
      },
    );
  });

  group('GroupMapController.pickGroup (timeout) - Unit Test Suite', () {
    /// Ana watching Guias (`g1`) and Recepção (`g2`), whose positions never
    /// arrive. Runs inside [async].
    GroupMapController watchingSilentRecepcao(FakeAsync async) {
      organization = StreamController<Map<String, Object?>?>();
      roles = StreamController<Map<String, Object?>>();
      names = {};
      when(
        positions.streamGroupPositions('g2'),
      ).thenAnswer((_) => StreamController<List<UserModel>>().stream);
      organization.add(member);
      roles.add({
        'g1': ['subscriber'],
        'g2': ['subscriber'],
      });
      nameOf('g1').add('Guias');
      nameOf('g2').add('Recepção');
      final controller = GroupMapController(
        memberships: memberships,
        positions: positions,
        onAccessLost: () async => accessLost++,
        organizationId: () => 'rotasul',
        email: () => 'ana@x.com',
      )..start();
      async.flushMicrotasks();
      return controller;
    }

    test('Edge Case: a group whose positions never arrive releases '
        'switchingGroup after 15 s', () {
      fakeAsync((async) {
        // 1. Arrange
        final controller = watchingSilentRecepcao(async);
        controller.pickGroup(const MapGroup(id: 'g2', name: 'Recepção'));
        async.elapse(const Duration(seconds: 14));
        final switchingBefore = controller.switchingGroup.value;

        // 2. Act
        async.elapse(const Duration(seconds: 1));

        // 3. Assert
        expect(switchingBefore, isTrue);
        expect(controller.switchingGroup.value, isFalse);
        expect(controller.selectedGroup.value?.id, 'g2');
      });
    });

    test('Sad Path: the 15 s timeout reached after dispose() neither throws '
        'nor notifies', () {
      fakeAsync((async) {
        // 1. Arrange
        final controller = watchingSilentRecepcao(async);
        final switchingChanged = Notifications(controller.switchingGroup);
        Object? failure;
        var finished = false;
        controller
            .pickGroup(const MapGroup(id: 'g2', name: 'Recepção'))
            .then(
              (_) => finished = true,
              onError: (Object e) {
                failure = e;
                return false;
              },
            );
        async.flushMicrotasks();
        final notifiedBeforeDispose = switchingChanged.count;
        controller.dispose();

        // 2. Act
        async.elapse(const Duration(seconds: 16));

        // 3. Assert
        expect(failure, isNull);
        expect(finished, isTrue);
        expect(switchingChanged.count, notifiedBeforeDispose);
      });
    });
  });
}
