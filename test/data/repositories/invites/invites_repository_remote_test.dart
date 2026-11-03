import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository_remote.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/invite_send_result.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<CentralFunctionsService>()])
import 'invites_repository_remote_test.mocks.dart';

const _connection = Failure.connection(FailedAction.conclude);

late MockCentralFunctionsService functions;
late InvitesRepositoryRemote repository;

/// Makes function [name] answer [data].
void answers(String name, Object? data) => when(
  functions.call(name, any, timeout: anyNamed('timeout')),
).thenAnswer((_) async => data);

/// Makes function [name] fail with [error].
void fails(String name, Object error) => when(
  functions.call(name, any, timeout: anyNamed('timeout')),
).thenAnswer((_) async => throw error);

/// The data function [name] was called with, verifying one call.
Object? sentTo(String name) => verify(
  functions.call(name, captureAny, timeout: anyNamed('timeout')),
).captured.single;

Failure failureOf(Result<Object?> result) => switch (result) {
  Err(:final failure) => failure,
  Ok() => fail('expected an Err, got $result'),
};

T valueOf<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err() => fail('expected an Ok, got $result'),
};

/// An invite as the server lists it.
Map<String, Object?> inviteJson(String id) => {
  'id': id,
  'organizationId': 'rotasul',
  'organizationName': 'Rota Sul',
  'groupId': '01',
  'groupName': 'Equipe Norte',
  'email': 'ana@x.com',
  'roles': ['publisher'],
  'inviterName': 'Rita Lima',
  'expiresAt': '2026-11-09T12:00:00.000Z',
};

final _invite = Invite.fromJson(inviteJson('inv1'))!;

/// Sends one invite for ana@x.com (share) to group 01.
Future<Result<InviteSendResult>> sendToGroup() => repository.send(
  'rotasul',
  organizationName: 'Rota Sul',
  groupId: '01',
  invites: [
    (email: 'ana@x.com', roles: {GroupRole.publisher, GroupRole.subscriber}),
  ],
);

void main() {
  setUp(() {
    functions = MockCentralFunctionsService();
    repository = InvitesRepositoryRemote(functions: functions);
  });

  group('InvitesRepositoryRemote.send - Unit Test Suite', () {
    test('Happy Path: sends the group invites and reads what was sent, not '
        'e-mailed and skipped', () async {
      // 1. Arrange
      answers('sendInvites', {
        'groupId': '01',
        'groupName': 'Equipe Norte',
        'sent': [
          {'email': 'ana@x.com', 'emailed': true},
          {'email': 'rui@x.com', 'emailed': false},
        ],
        'skipped': [
          {'email': 'vera@x.com', 'reason': 'Já está no grupo.'},
        ],
      });

      // 2. Act
      final result = await sendToGroup();

      // 3. Assert
      expect(sentTo('sendInvites'), {
        'organizationId': 'rotasul',
        'organizationName': 'Rota Sul',
        'groupId': '01',
        'invites': [
          {
            'email': 'ana@x.com',
            'roles': ['publisher', 'subscriber'],
          },
        ],
      });
      expect(
        valueOf(result),
        const InviteSendResult(
          groupId: '01',
          groupName: 'Equipe Norte',
          sent: ['ana@x.com', 'rui@x.com'],
          notEmailed: ['rui@x.com'],
          skipped: {'vera@x.com': 'Já está no grupo.'},
        ),
      );
    });

    test('Edge Case: first-group mode sends the group name and no group '
        'id', () async {
      // 1. Arrange
      answers('sendInvites', {
        'groupId': '07',
        'groupName': 'Equipe Serra',
        'sent': const <Object?>[],
      });

      // 2. Act
      final result = await repository.send(
        'rotasul',
        organizationName: 'Rota Sul',
        firstGroupName: 'Equipe Serra',
        invites: [
          (email: 'ana@x.com', roles: {GroupRole.subscriber}),
        ],
      );

      // 3. Assert
      final sent = sentTo('sendInvites')! as Map;
      expect(sent.containsKey('groupId'), isFalse);
      expect(sent['firstGroupName'], 'Equipe Serra');
      expect(valueOf(result).groupId, '07');
    });

    test('Edge Case: an empty answer falls back to what was asked and skips '
        'malformed entries', () async {
      // 1. Arrange
      answers('sendInvites', {
        'sent': [
          'ana@x.com',
          {'emailed': true},
        ],
        'skipped': [
          {'email': 'vera@x.com'},
        ],
      });

      // 2. Act
      final result = await sendToGroup();

      // 3. Assert
      expect(
        valueOf(result),
        const InviteSendResult(
          groupId: '01',
          groupName: '',
          sent: [],
          notEmailed: [],
          skipped: {},
        ),
      );
    });

    test('Sad Path: an invalid-argument refusal gives the server\'s own '
        'words', () async {
      // 1. Arrange
      fails(
        'sendInvites',
        const FunctionsFailure('invalid-argument', 'Escolha um grupo.'),
      );

      // 2. Act
      final result = await sendToGroup();

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.serverRefusal('Escolha um grupo.'),
      );
    });

    test('Sad Path: an unexpected error gives the send hint', () async {
      // 1. Arrange
      fails('sendInvites', StateError('offline'));

      // 2. Act
      final result = await sendToGroup();

      // 3. Assert
      expect(failureOf(result), const Failure.connection(FailedAction.send));
    });
  });

  group('InvitesRepositoryRemote (lists) - Unit Test Suite', () {
    test('Happy Path: listForGroup sends the group and parses each '
        'invite', () async {
      // 1. Arrange
      answers('listInvites', {
        'invites': [inviteJson('inv1'), 'junk', inviteJson('inv2')],
      });

      // 2. Act
      final result = await repository.listForGroup('rotasul', '01');

      // 3. Assert
      expect(sentTo('listInvites'), {
        'organizationId': 'rotasul',
        'groupId': '01',
      });
      expect(valueOf(result).map((i) => i.id), ['inv1', 'inv2']);
    });

    test('Happy Path: mine sends nothing and parses the account\'s '
        'invites', () async {
      // 1. Arrange
      answers('myInvites', {
        'invites': [inviteJson('inv1')],
      });

      // 2. Act
      final result = await repository.mine();

      // 3. Assert
      expect(sentTo('myInvites'), isEmpty);
      expect(valueOf(result), [_invite]);
    });

    test('Edge Case: an answer without invites is no invite', () async {
      // 1. Arrange
      answers('myInvites', {'other': 1});

      // 2. Act
      final result = await repository.mine();

      // 3. Assert
      expect(valueOf(result), isEmpty);
    });

    test('Sad Path: an unexpected error gives the load message', () async {
      // 1. Arrange
      fails('listInvites', Exception('offline'));

      // 2. Act
      final result = await repository.listForGroup('rotasul', '01');

      // 3. Assert
      expect(failureOf(result), const Failure.load(LoadTarget.invites));
    });

    test('Sad Path: a refusal the code does not explain gives the connection '
        'hint', () async {
      // 1. Arrange
      fails(
        'myInvites',
        const FunctionsFailure('unauthenticated', 'Sign in first.'),
      );

      // 2. Act
      final result = await repository.mine();

      // 3. Assert
      expect(failureOf(result), _connection);
    });
  });

  group('InvitesRepositoryRemote (resend, cancel) - Unit Test Suite', () {
    test('Happy Path: resend sends the invite id', () async {
      // 1. Arrange
      answers('resendInvite', null);

      // 2. Act
      final result = await repository.resend('rotasul', 'inv1');

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(sentTo('resendInvite'), {
        'organizationId': 'rotasul',
        'inviteId': 'inv1',
      });
    });

    test('Happy Path: cancel sends the invite id', () async {
      // 1. Arrange
      answers('cancelInvite', null);

      // 2. Act
      final result = await repository.cancel('rotasul', 'inv1');

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(sentTo('cancelInvite'), {
        'organizationId': 'rotasul',
        'inviteId': 'inv1',
      });
    });

    test('Sad Path: a failed-precondition refusal of cancel gives the '
        'server\'s own words', () async {
      // 1. Arrange
      fails(
        'cancelInvite',
        const FunctionsFailure('failed-precondition', 'Convite já aceito.'),
      );

      // 2. Act
      final result = await repository.cancel('rotasul', 'inv1');

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.serverRefusal('Convite já aceito.'),
      );
    });

    test('Sad Path: an unexpected error of resend gives the connection '
        'hint', () async {
      // 1. Arrange
      fails('resendInvite', StateError('offline'));

      // 2. Act
      final result = await repository.resend('rotasul', 'inv1');

      // 3. Assert
      expect(failureOf(result), _connection);
    });
  });

  group('InvitesRepositoryRemote.accept - Unit Test Suite', () {
    test(
      'Happy Path: sends only the invite id and returns the invite',
      () async {
        // 1. Arrange
        answers('acceptInvite', {'ok': true});

        // 2. Act
        final result = await repository.accept(_invite);

        // 3. Assert
        expect(sentTo('acceptInvite'), {'inviteId': 'inv1'});
        expect(valueOf(result), same(_invite));
      },
    );

    test('Sad Path: a failed-precondition refusal gives the server\'s own '
        'words', () async {
      // 1. Arrange
      fails(
        'acceptInvite',
        const FunctionsFailure('failed-precondition', 'Este convite expirou.'),
      );

      // 2. Act
      final result = await repository.accept(_invite);

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.serverRefusal('Este convite expirou.'),
      );
    });

    test('Sad Path: an unexpected error gives the accept hint', () async {
      // 1. Arrange
      fails('acceptInvite', StateError('offline'));

      // 2. Act
      final result = await repository.accept(_invite);

      // 3. Assert
      expect(failureOf(result), const Failure.connection(FailedAction.accept));
    });
  });
}
