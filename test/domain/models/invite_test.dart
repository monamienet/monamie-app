import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';

/// A complete invite as `myInvites` returns it.
Map<String, Object?> _json([Map<String, Object?> overrides = const {}]) => {
  'id': 'inv1',
  'organizationId': 'rotasul',
  'organizationName': 'Rota Sul',
  'groupId': '01',
  'groupName': 'Equipe Norte',
  'email': 'davi@x.com',
  'roles': ['publisher', 'subscriber'],
  'inviterName': 'Rita Lima',
  'expiresAt': '2026-11-09T12:00:00.000Z',
  ...overrides,
};

void main() {
  group('Invite.fromJson - Unit Test Suite', () {
    test('Happy Path: reads a complete invite', () {
      // 1. Arrange
      final json = _json();

      // 2. Act
      final invite = Invite.fromJson(json);

      // 3. Assert
      expect(invite, isNotNull);
      expect(invite!.id, 'inv1');
      expect(invite.organizationId, 'rotasul');
      expect(invite.groupId, '01');
      expect(invite.email, 'davi@x.com');
      expect(invite.roles, {GroupRole.publisher, GroupRole.subscriber});
      expect(invite.expiresAt, DateTime.utc(2026, 11, 9, 12));
    });

    test('Edge Case: unknown roles are ignored when a known one remains', () {
      // 1. Arrange
      final json = _json({
        'roles': ['maintainer', 'subscriber'],
      });

      // 2. Act
      final invite = Invite.fromJson(json);

      // 3. Assert
      expect(invite!.roles, {GroupRole.subscriber});
    });

    test('Edge Case: an expiresAt that is not a string is read as null', () {
      // 1. Arrange
      final json = _json({'expiresAt': 1793966400000});

      // 2. Act
      final invite = Invite.fromJson(json);

      // 3. Assert
      expect(invite, isNotNull);
      expect(invite!.expiresAt, isNull);
    });

    test('Edge Case: a malformed expiresAt string is read as null', () {
      // 1. Arrange
      final json = _json({'expiresAt': 'amanhã'});

      // 2. Act
      final invite = Invite.fromJson(json);

      // 3. Assert
      expect(invite!.expiresAt, isNull);
    });

    final malformed = <String, Object?>{
      'not a map': ['inv1'],
      'null': null,
      'no id': _json({'id': null}),
      'no organizationId': _json({'organizationId': null}),
      'no group': _json({'groupId': null}),
      'no email': _json({'email': null}),
      'a numeric id': _json({'id': 7}),
      'no roles': _json({'roles': null}),
      'an empty role list': _json({'roles': <String>[]}),
      'only unknown roles': _json({
        'roles': ['admin'],
      }),
    };
    for (final MapEntry(key: label, value: json) in malformed.entries) {
      test('Sad Path: $label is read as null', () {
        // 1. Arrange
        final input = json;

        // 2. Act
        final invite = Invite.fromJson(input);

        // 3. Assert
        expect(invite, isNull);
      });
    }
  });

  group('inviteEmailProblem - Unit Test Suite', () {
    test('Happy Path: a valid new e-mail has no problem', () {
      // 1. Arrange
      final drafts = [InviteDraft('ana@x.com')];

      // 2. Act
      final problem = inviteEmailProblem('davi@x.com', drafts);

      // 3. Assert
      expect(problem, isNull);
    });

    test(
      'Edge Case: an e-mail already in the list, in another case, is refused',
      () {
        // 1. Arrange
        final drafts = [InviteDraft('ana@x.com')];

        // 2. Act
        final problem = inviteEmailProblem(' Ana@X.com ', drafts);

        // 3. Assert
        expect(problem, 'ana@x.com já está na lista.');
      },
    );

    for (final email in ['', 'ana', 'ana@', 'ana@x', 'ana souza@x.com']) {
      test('Sad Path: "$email" is not a valid e-mail', () {
        // 1. Arrange
        final drafts = <InviteDraft>[];

        // 2. Act
        final problem = inviteEmailProblem(email, drafts);

        // 3. Assert
        expect(problem, 'Digite um e-mail válido.');
      });
    }
  });
}
