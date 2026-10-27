import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/admin/teams/team.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';

/// A complete invite as `myInvites` returns it.
Map<String, Object?> _json([Map<String, Object?> overrides = const {}]) => {
  'id': 'inv1',
  'partnerId': 'rotasul',
  'partnerName': 'Rota Sul',
  'team': '01',
  'teamName': 'Equipe Norte',
  'email': 'davi@x.com',
  'roles': ['share', 'watch'],
  'invitedByName': 'Rita Lima',
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
      expect(invite.partnerId, 'rotasul');
      expect(invite.team, '01');
      expect(invite.email, 'davi@x.com');
      expect(invite.roles, {TeamRole.share, TeamRole.watch});
      expect(invite.expiresAt, DateTime.utc(2026, 11, 9, 12));
    });

    test('Happy Path: rolesLabel lists Em campo before Vê o mapa', () {
      // 1. Arrange
      final json = _json({
        'roles': ['watch', 'share'],
      });

      // 2. Act
      final invite = Invite.fromJson(json);

      // 3. Assert
      expect(invite!.rolesLabel, 'Em campo · Vê o mapa');
    });

    test('Edge Case: unknown roles are ignored when a known one remains', () {
      // 1. Arrange
      final json = _json({
        'roles': ['admin', 'watch'],
      });

      // 2. Act
      final invite = Invite.fromJson(json);

      // 3. Assert
      expect(invite!.roles, {TeamRole.watch});
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
      'no partnerId': _json({'partnerId': null}),
      'no team': _json({'team': null}),
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

  group('dayMonth - Unit Test Suite', () {
    test('Happy Path: Nov 9 2026 is "9 de novembro"', () {
      // 1. Arrange
      final date = DateTime(2026, 11, 9);

      // 2. Act
      final text = dayMonth(date);

      // 3. Assert
      expect(text, '9 de novembro');
    });

    test('Edge Case: the first and last months use their names', () {
      // 1. Arrange
      final dates = [DateTime(2027, 1, 1), DateTime(2026, 12, 31)];

      // 2. Act
      final texts = dates.map(dayMonth).toList();

      // 3. Assert
      expect(texts, ['1 de janeiro', '31 de dezembro']);
    });
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
