import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/invites/invite_controller.dart';
import 'package:monamie_app/app/modules/invites/invites_backend.dart';

const norte = Group(id: '01', name: 'Equipe Norte', people: []);
const leste = Group(id: '03', name: 'Equipe Leste', people: []);

const _result = InviteSendResult(
  groupId: '01',
  groupName: 'Equipe Norte',
  sent: ['ana@x.com'],
  notEmailed: [],
  skipped: {},
);

/// One `send` call as the fake recorded it.
typedef SendCall = ({
  String organizationId,
  String organizationName,
  String? groupId,
  String? firstGroupName,
  List<({String email, Set<GroupRole> roles})> invites,
});

/// [InvitesBackend] that records `send`, optionally waits on [gate] and
/// fails with [failure].
class FakeInvitesBackend implements InvitesBackend {
  final sends = <SendCall>[];
  Completer<void>? gate;
  Object? failure;

  @override
  Future<InviteSendResult> send(
    String organizationId, {
    required String organizationName,
    String? groupId,
    String? firstGroupName,
    required List<({String email, Set<GroupRole> roles})> invites,
  }) async {
    sends.add((
      organizationId: organizationId,
      organizationName: organizationName,
      groupId: groupId,
      firstGroupName: firstGroupName,
      invites: invites,
    ));
    await gate?.future;
    if (failure case final failure?) throw failure;
    return _result;
  }

  @override
  Future<List<Invite>> listForGroup(String organizationId, String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> resend(String organizationId, String inviteId) =>
      throw UnimplementedError();

  @override
  Future<void> cancel(String organizationId, String inviteId) =>
      throw UnimplementedError();

  @override
  Future<List<Invite>> mine() => throw UnimplementedError();

  @override
  Future<Invite> accept(Invite invite) => throw UnimplementedError();
}

late FakeInvitesBackend backend;

InviteController controllerWith({
  List<Group> groups = const [norte, leste],
  String? groupId,
  bool canCreateFirstGroup = true,
}) => InviteController(
  organizationId: 'rotasul',
  organizationName: 'Rota Sul',
  groups: groups,
  backend: backend,
  groupId: groupId,
  canCreateFirstGroup: canCreateFirstGroup,
);

/// A controller for team 01 with ana (share) in the list.
InviteController readyController() {
  final controller = controllerWith();
  controller.add('ana@x.com');
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = FakeInvitesBackend();
  });

  group('InviteController (team) - Unit Test Suite', () {
    test('Happy Path: with teams the team defaults to the first one', () {
      // 1. Arrange
      const teams = [norte, leste];

      // 2. Act
      final controller = controllerWith(groups: teams);

      // 3. Assert
      expect(controller.groupId.value, '01');
      expect(controller.firstGroupMode, isFalse);
    });

    test('Edge Case: a given team wins over the first one', () {
      // 1. Arrange
      const team = '03';

      // 2. Act
      final controller = controllerWith(groupId: team);

      // 3. Assert
      expect(controller.groupId.value, '03');
    });

    test('Edge Case: with no teams it is in first-team mode', () {
      // 1. Arrange
      const teams = <Group>[];

      // 2. Act
      final controller = controllerWith(groups: teams);

      // 3. Assert
      expect(controller.firstGroupMode, isTrue);
    });

    final names = <String, bool>{
      'Equipe Serra': true,
      'Ab': true,
      'A': false,
      '': false,
      '  1 2 ': false,
    };
    for (final MapEntry(key: name, value: valid) in names.entries) {
      test(
        '${valid ? 'Happy Path' : 'Sad Path'}: first team name "$name" is ${valid ? 'valid' : 'refused'}',
        () {
          // 1. Arrange
          final controller = controllerWith(groups: const []);

          // 2. Act
          controller.firstGroupName.value = name;

          // 3. Assert
          expect(controller.firstGroupProblem == null, valid);
        },
      );
    }
  });

  group('InviteController (maintainer) - Unit Test Suite', () {
    test('Happy Path: a maintainer invites to their group', () async {
      // 1. Arrange
      final controller = controllerWith(
        groups: const [leste],
        canCreateFirstGroup: false,
      );
      controller.add('ana@x.com');

      // 2. Act
      final ok = await controller.send();

      // 3. Assert
      expect(ok, isTrue);
      expect(
        [backend.sends.single.groupId, backend.sends.single.firstGroupName],
        ['03', isNull],
      );
    });

    test(
      'Edge Case: with no group a maintainer is not in first-group mode',
      () {
        // 1. Arrange
        const groups = <Group>[];

        // 2. Act
        final controller = controllerWith(
          groups: groups,
          canCreateFirstGroup: false,
        );

        // 3. Assert
        expect(controller.firstGroupMode, isFalse);
      },
    );

    test('Sad Path: with no group a maintainer cannot send, even with a '
        'group name typed', () async {
      // 1. Arrange
      final controller = controllerWith(
        groups: const [],
        canCreateFirstGroup: false,
      );
      controller.firstGroupName.value = 'Equipe Serra';
      controller.add('ana@x.com');

      // 2. Act
      final ok = await controller.send();

      // 3. Assert
      expect(ok, isFalse);
      expect(backend.sends, isEmpty);
    });
  });

  group('InviteController.add - Unit Test Suite', () {
    test('Happy Path: a valid e-mail is added with the share role', () {
      // 1. Arrange
      final controller = controllerWith();

      // 2. Act
      final added = controller.add('ana@x.com');

      // 3. Assert
      expect(added, isTrue);
      expect(controller.people.map((p) => p.email), ['ana@x.com']);
      expect(controller.people.single.roles, {GroupRole.publisher});
      expect(controller.draftError.value, isEmpty);
    });

    test('Edge Case: a duplicate e-mail in another case is refused', () {
      // 1. Arrange
      final controller = readyController();

      // 2. Act
      final added = controller.add('ANA@x.com');

      // 3. Assert
      expect(added, isFalse);
      expect(controller.people, hasLength(1));
      expect(controller.draftError.value, isNotEmpty);
    });

    test('Edge Case: adding is ignored while sending', () {
      // 1. Arrange
      final controller = controllerWith();
      controller.isSending.value = true;

      // 2. Act
      final added = controller.add('ana@x.com');

      // 3. Assert
      expect(added, isFalse);
      expect(controller.people, isEmpty);
    });

    test('Sad Path: a malformed e-mail is refused with draftError', () {
      // 1. Arrange
      final controller = controllerWith();

      // 2. Act
      final added = controller.add('ana@');

      // 3. Assert
      expect(added, isFalse);
      expect(controller.people, isEmpty);
      expect(controller.draftError.value, 'Digite um e-mail válido.');
    });
  });

  group('InviteController.toggle - Unit Test Suite', () {
    test('Happy Path: toggling watch adds it to the person', () {
      // 1. Arrange
      final controller = readyController();
      final ana = controller.people.single;

      // 2. Act
      controller.toggle(ana, GroupRole.subscriber);

      // 3. Assert
      expect(ana.roles, {GroupRole.publisher, GroupRole.subscriber});
    });

    test('Edge Case: toggling share again removes it', () {
      // 1. Arrange
      final controller = readyController();
      final ana = controller.people.single;
      controller.toggle(ana, GroupRole.subscriber);

      // 2. Act
      controller.toggle(ana, GroupRole.publisher);

      // 3. Assert
      expect(ana.roles, {GroupRole.subscriber});
    });

    test('Sad Path: a person left with no role blocks the send', () {
      // 1. Arrange
      final controller = readyController();
      final ana = controller.people.single;

      // 2. Act
      controller.toggle(ana, GroupRole.publisher);

      // 3. Assert
      expect(controller.canSend, isFalse);
    });
  });

  group('InviteController.send - Unit Test Suite', () {
    test('Happy Path: sends the team and the people, sets result', () async {
      // 1. Arrange
      final controller = readyController();

      // 2. Act
      final sent = await controller.send();

      // 3. Assert
      expect(sent, isTrue);
      final call = backend.sends.single;
      expect(call.organizationId, 'rotasul');
      expect(call.groupId, '01');
      expect(call.firstGroupName, isNull);
      expect(call.invites.map((p) => p.email), ['ana@x.com']);
      expect(call.invites.single.roles, {GroupRole.publisher});
      expect(controller.result.value, same(_result));
      expect(controller.isSending.value, isFalse);
    });

    test(
      'Edge Case: in first-team mode sends firstGroupName instead of team',
      () async {
        // 1. Arrange
        final controller = controllerWith(groups: const []);
        controller.firstGroupName.value = 'Equipe Serra';
        controller.add('ana@x.com');

        // 2. Act
        final sent = await controller.send();

        // 3. Assert
        expect(sent, isTrue);
        expect(backend.sends.single.groupId, isNull);
        expect(backend.sends.single.firstGroupName, 'Equipe Serra');
      },
    );

    test(
      'Edge Case: a second send while the first is in flight returns false',
      () async {
        // 1. Arrange
        final controller = readyController();
        backend.gate = Completer<void>();
        final first = controller.send();

        // 2. Act
        final second = await controller.send();

        // 3. Assert
        expect(second, isFalse);
        expect(backend.sends, hasLength(1));
        expect(controller.isSending.value, isTrue);
        backend.gate!.complete();
        await first;
      },
    );

    test(
      'Sad Path: an InvitesException returns false with its message and resets isSending',
      () async {
        // 1. Arrange
        final controller = readyController();
        backend.failure = const InvitesException('Escolha uma equipe.');

        // 2. Act
        final sent = await controller.send();

        // 3. Assert
        expect(sent, isFalse);
        expect(controller.errorMessage.value, 'Escolha uma equipe.');
        expect(controller.result.value, isNull);
        expect(controller.isSending.value, isFalse);
      },
    );

    test('Sad Path: with nobody in the list nothing is sent', () async {
      // 1. Arrange
      final controller = controllerWith();

      // 2. Act
      final sent = await controller.send();

      // 3. Assert
      expect(sent, isFalse);
      expect(backend.sends, isEmpty);
    });
  });

  group('InviteController.again - Unit Test Suite', () {
    test('Happy Path: clears the people and the result', () async {
      // 1. Arrange
      final controller = readyController();
      await controller.send();

      // 2. Act
      controller.again();

      // 3. Assert
      expect(controller.people, isEmpty);
      expect(controller.result.value, isNull);
    });
  });
}
