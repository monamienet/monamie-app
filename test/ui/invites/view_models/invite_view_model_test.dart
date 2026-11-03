import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/ui/invites/view_models/invite_view_model.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/domain/models/invite_send_result.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<InvitesRepository>()])
import 'invite_view_model_test.mocks.dart';

const norte = Group(id: '01', name: 'Equipe Norte', people: []);
const leste = Group(id: '03', name: 'Equipe Leste', people: []);

const _result = InviteSendResult(
  groupId: '01',
  groupName: 'Equipe Norte',
  sent: ['ana@x.com'],
  notEmailed: [],
  skipped: {},
);

/// One `send` call as the mock received it.
typedef SendCall = ({
  String organizationId,
  String organizationName,
  String? groupId,
  String? firstGroupName,
  List<({String email, Set<GroupRole> roles})> invites,
});

/// The `send` stub of [repository], with any arguments.
Future<Result<InviteSendResult>> anySend() => repository.send(
  any,
  organizationName: anyNamed('organizationName'),
  groupId: anyNamed('groupId'),
  firstGroupName: anyNamed('firstGroupName'),
  invites: anyNamed('invites'),
);

/// Makes `send` wait on [wait] before returning [_result] or, with
/// [failure], an [Err] with that failure.
void stubSend(Future<void> Function() wait, {Failure? failure}) {
  when(anySend()).thenAnswer((_) async {
    await wait();
    return failure == null ? const Ok(_result) : Err(failure);
  });
}

/// Verifies `send` was called exactly once and returns its arguments.
SendCall sentCall() {
  final captured = verify(
    repository.send(
      captureAny,
      organizationName: captureAnyNamed('organizationName'),
      groupId: captureAnyNamed('groupId'),
      firstGroupName: captureAnyNamed('firstGroupName'),
      invites: captureAnyNamed('invites'),
    ),
  ).captured;
  expect(captured, hasLength(5), reason: 'send called once');
  return (
    organizationId: captured[0] as String,
    organizationName: captured[1] as String,
    groupId: captured[2] as String?,
    firstGroupName: captured[3] as String?,
    invites: captured[4] as List<({String email, Set<GroupRole> roles})>,
  );
}

late MockInvitesRepository repository;

InviteViewModel controllerWith({
  List<Group> groups = const [norte, leste],
  String? groupId,
  bool canCreateFirstGroup = true,
}) => InviteViewModel(
  organizationId: 'rotasul',
  organizationName: 'Rota Sul',
  groups: groups,
  repository: repository,
  groupId: groupId,
  canCreateFirstGroup: canCreateFirstGroup,
);

/// A controller for team 01 with ana (share) in the list.
InviteViewModel readyController() {
  final controller = controllerWith();
  controller.add('ana@x.com');
  return controller;
}

void main() {
  provideDummy<Result<InviteSendResult>>(const Ok(_result));

  setUp(() {
    repository = MockInvitesRepository();
    stubSend(() async {});
  });

  group('InviteViewModel (team) - Unit Test Suite', () {
    test('Happy Path: with teams the team defaults to the first one', () {
      // 1. Arrange
      const teams = [norte, leste];

      // 2. Act
      final controller = controllerWith(groups: teams);

      // 3. Assert
      expect(controller.state.groupId, '01');
      expect(controller.firstGroupMode, isFalse);
    });

    test('Edge Case: a given team wins over the first one', () {
      // 1. Arrange
      const team = '03';

      // 2. Act
      final controller = controllerWith(groupId: team);

      // 3. Assert
      expect(controller.state.groupId, '03');
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
          controller.setFirstGroupName(name);

          // 3. Assert
          expect(controller.firstGroupProblem == null, valid);
        },
      );
    }
  });

  group('InviteViewModel (maintainer) - Unit Test Suite', () {
    test('Happy Path: a maintainer invites to their group', () async {
      // 1. Arrange
      final controller = controllerWith(
        groups: const [leste],
        canCreateFirstGroup: false,
      );
      controller.add('ana@x.com');

      // 2. Act
      final ok = await controller.send.execute();

      // 3. Assert
      expect(ok, isA<Ok<InviteSendResult>>());
      final call = sentCall();
      expect([call.groupId, call.firstGroupName], ['03', isNull]);
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
      controller.setFirstGroupName('Equipe Serra');
      controller.add('ana@x.com');

      // 2. Act
      final ok = await controller.send.execute();

      // 3. Assert
      expect(ok, isNull);
      verifyNever(anySend());
    });
  });

  group('InviteViewModel.add - Unit Test Suite', () {
    test('Happy Path: a valid e-mail is added with the share role', () {
      // 1. Arrange
      final controller = controllerWith();

      // 2. Act
      final added = controller.add('ana@x.com');

      // 3. Assert
      expect(added, isTrue);
      expect(controller.state.people.map((p) => p.email), ['ana@x.com']);
      expect(controller.state.people.single.roles, {GroupRole.publisher});
      expect(controller.state.draftFailure, isNull);
    });

    test('Edge Case: a duplicate e-mail in another case is refused', () {
      // 1. Arrange
      final controller = readyController();

      // 2. Act
      final added = controller.add('ANA@x.com');

      // 3. Assert
      expect(added, isFalse);
      expect(controller.state.people, hasLength(1));
      expect(controller.state.draftFailure, isNotNull);
    });

    test('Edge Case: adding is ignored while sending', () async {
      // 1. Arrange
      final controller = readyController();
      final gate = Completer<void>();
      stubSend(() => gate.future);
      final pending = controller.send.execute();

      // 2. Act
      final added = controller.add('bia@x.com');

      // 3. Assert
      expect(added, isFalse);
      expect(controller.state.people.map((p) => p.email), ['ana@x.com']);
      gate.complete();
      await pending;
    });

    test('Sad Path: a malformed e-mail is refused with draftFailure', () {
      // 1. Arrange
      final controller = controllerWith();

      // 2. Act
      final added = controller.add('ana@');

      // 3. Assert
      expect(added, isFalse);
      expect(controller.state.people, isEmpty);
      expect(controller.state.draftFailure, const Failure.invalidEmail());
    });
  });

  group('InviteViewModel.toggle - Unit Test Suite', () {
    test('Happy Path: toggling watch adds it to the person', () {
      // 1. Arrange
      final controller = readyController();
      final ana = controller.state.people.single;

      // 2. Act
      controller.toggle(ana, GroupRole.subscriber);

      // 3. Assert
      expect(controller.state.people.single.roles, {
        GroupRole.publisher,
        GroupRole.subscriber,
      });
    });

    test('Edge Case: toggling share again removes it', () {
      // 1. Arrange
      final controller = readyController();
      final ana = controller.state.people.single;
      controller.toggle(ana, GroupRole.subscriber);

      // 2. Act
      controller.toggle(ana, GroupRole.publisher);

      // 3. Assert
      expect(controller.state.people.single.roles, {GroupRole.subscriber});
    });

    test('Sad Path: a person left with no role blocks the send', () {
      // 1. Arrange
      final controller = readyController();
      final ana = controller.state.people.single;

      // 2. Act
      controller.toggle(ana, GroupRole.publisher);

      // 3. Assert
      expect(controller.canSend, isFalse);
    });
  });

  group('InviteViewModel.send - Unit Test Suite', () {
    test('Happy Path: sends the team and the people, sets result', () async {
      // 1. Arrange
      final controller = readyController();

      // 2. Act
      final sent = await controller.send.execute();

      // 3. Assert
      expect(sent, isA<Ok<InviteSendResult>>());
      final call = sentCall();
      expect(call.organizationId, 'rotasul');
      expect(call.groupId, '01');
      expect(call.firstGroupName, isNull);
      expect(call.invites.map((p) => p.email), ['ana@x.com']);
      expect(call.invites.single.roles, {GroupRole.publisher});
      expect(controller.state.result, same(_result));
      expect(controller.send.running, isFalse);
    });

    test(
      'Edge Case: in first-team mode sends firstGroupName instead of team',
      () async {
        // 1. Arrange
        final controller = controllerWith(groups: const []);
        controller.setFirstGroupName('Equipe Serra');
        controller.add('ana@x.com');

        // 2. Act
        final sent = await controller.send.execute();

        // 3. Assert
        expect(sent, isA<Ok<InviteSendResult>>());
        final call = sentCall();
        expect(call.groupId, isNull);
        expect(call.firstGroupName, 'Equipe Serra');
      },
    );

    test(
      'Edge Case: a second send while the first is in flight is ignored (null)',
      () async {
        // 1. Arrange
        final controller = readyController();
        final gate = Completer<void>();
        stubSend(() => gate.future);
        final first = controller.send.execute();

        // 2. Act
        final second = await controller.send.execute();

        // 3. Assert
        expect(second, isNull);
        verify(anySend()).called(1);
        expect(controller.send.running, isTrue);
        gate.complete();
        await first;
      },
    );

    test(
      'Sad Path: an Err is returned with its failure and the send stops running',
      () async {
        // 1. Arrange
        final controller = readyController();
        stubSend(
          () async {},
          failure: const Failure.serverRefusal('Escolha uma equipe.'),
        );

        // 2. Act
        final sent = await controller.send.execute();

        // 3. Assert
        expect(
          sent,
          isA<Err<InviteSendResult>>().having(
            (err) => err.failure,
            'failure',
            const Failure.serverRefusal('Escolha uma equipe.'),
          ),
        );
        expect(
          controller.state.failure,
          const Failure.serverRefusal('Escolha uma equipe.'),
        );
        expect(controller.state.result, isNull);
        expect(controller.send.running, isFalse);
      },
    );

    test('Sad Path: with nobody in the list nothing is sent', () async {
      // 1. Arrange
      final controller = controllerWith();

      // 2. Act
      final sent = await controller.send.execute();

      // 3. Assert
      expect(sent, isNull);
      verifyNever(anySend());
    });
  });

  group('InviteViewModel.again - Unit Test Suite', () {
    test('Happy Path: clears the people and the result', () async {
      // 1. Arrange
      final controller = readyController();
      await controller.send.execute();

      // 2. Act
      controller.again();

      // 3. Assert
      expect(controller.state.people, isEmpty);
      expect(controller.state.result, isNull);
    });
  });

  group('InviteViewModel (listeners) - Unit Test Suite', () {
    test('Happy Path: choosing another group notifies once', () {
      // 1. Arrange
      final controller = controllerWith();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.selectGroup('03');

      // 3. Assert
      expect(notifications, 1);
      expect(controller.state.groupId, '03');
    });

    test('Edge Case: choosing the group already chosen notifies nobody', () {
      // 1. Arrange
      final controller = controllerWith();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.selectGroup('01');

      // 3. Assert
      expect(notifications, 0);
    });

    test('Edge Case: removing someone not in the list notifies nobody, '
        'though the list is rebuilt', () {
      // 1. Arrange
      final controller = readyController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.remove(const InviteDraft('bia@x.com'));

      // 3. Assert
      expect(notifications, 0);
    });

    test('Sad Path: a refused e-mail notifies once with the problem', () {
      // 1. Arrange
      final controller = controllerWith();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.add('ana@');

      // 3. Assert
      expect(notifications, 1);
    });

    test('Sad Path: a send finishing after dispose notifies nobody and does '
        'not throw', () async {
      // 1. Arrange
      final controller = readyController();
      final gate = Completer<void>();
      stubSend(() => gate.future);
      var notifications = 0;
      final pending = controller.send.execute();
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      gate.complete();

      // 3. Assert
      await expectLater(pending, completion(isA<Ok<InviteSendResult>>()));
      expect(notifications, 0);
    });
  });
}
