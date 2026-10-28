import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_member_model.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/presence.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/team_rows.dart';

final now = DateTime(2026, 10, 27, 12, 0);
const validity = Duration(minutes: 10);

GoogleGroupMember member(String name) =>
    GoogleGroupMember(name: name, email: '$name@x.org');

/// A live document of [name], last seen [minutesAgo] minutes before [now].
UserModel doc(String name, {int minutesAgo = 1, bool? isTracked = true}) =>
    UserModel(
      email: '$name@x.org',
      timestamp: now.subtract(Duration(minutes: minutesAgo)),
      isTracked: isTracked,
    );

List<TeamRow> rows({
  required List<GoogleGroupMember> members,
  List<UserModel> users = const [],
  Set<String> usersWithPoints = const {},
  bool observingToday = true,
}) => teamRows(
  members: members,
  users: users,
  usersWithPoints: usersWithPoints,
  observingToday: observingToday,
  now: now,
  validity: validity,
);

List<String> names(List<TeamRow> list) => [
  for (final row in list) row.member.name,
];

void main() {
  group('teamRows - Unit Test Suite', () {
    test('Happy Path: live, then stale, then off, then never', () {
      // 1. Arrange
      final members = [
        member('never'),
        member('off'),
        member('stale'),
        member('live'),
      ];
      final users = [
        doc('off', isTracked: false),
        doc('stale', minutesAgo: 30),
        doc('live'),
      ];

      // 2. Act
      final result = rows(members: members, users: users);

      // 3. Assert
      expect(names(result), ['live', 'stale', 'off', 'never']);
      expect(result.map((row) => row.presence.kind), [
        PresenceKind.live,
        PresenceKind.stale,
        PresenceKind.off,
        PresenceKind.never,
      ]);
    });

    test('Happy Path: each row carries its member and live document', () {
      // 1. Arrange
      final ana = member('ana');
      final anaDoc = doc('ana');

      // 2. Act
      final result = rows(members: [ana], users: [anaDoc]);

      // 3. Assert
      expect(
        (
          identical(result.single.member, ana),
          identical(result.single.user, anaDoc),
        ),
        (true, true),
      );
    });

    test('Edge Case: within the same presence the input order is kept', () {
      // 1. Arrange
      final members = [
        member('b_live'),
        member('a_never'),
        member('c_live'),
        member('d_never'),
        member('a_live'),
      ];
      final users = [doc('a_live'), doc('b_live'), doc('c_live')];

      // 2. Act
      final result = rows(members: members, users: users);

      // 3. Assert
      expect(names(result), [
        'b_live',
        'c_live',
        'a_live',
        'a_never',
        'd_never',
      ]);
    });

    test('Edge Case: a long run of equal presences keeps the input order', () {
      // 1. Arrange
      // Large enough to defeat an unstable sort.
      final members = [for (var i = 0; i < 100; i++) member('p$i')];

      // 2. Act
      final result = rows(members: members);

      // 3. Assert
      expect(names(result), [for (var i = 0; i < 100; i++) 'p$i']);
    });

    test(
      'Edge Case: a member without a live document is "never" with no user',
      () {
        // 1. Arrange
        final members = [member('ana')];

        // 2. Act
        final result = rows(members: members);

        // 3. Assert
        expect(
          (result.single.user, result.single.presence.kind),
          (null, PresenceKind.never),
        );
      },
    );

    test('Edge Case: live documents of non-members are ignored', () {
      // 1. Arrange
      final members = [member('ana')];
      final users = [doc('ana'), doc('intruso'), doc('outro')];

      // 2. Act
      final result = rows(members: members, users: users);

      // 3. Assert
      expect(names(result), ['ana']);
    });

    test('Edge Case: no members give no rows', () {
      // 1. Arrange
      final users = [doc('ana')];

      // 2. Act
      final result = rows(members: const [], users: users);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Edge Case: a past day orders people with positions first', () {
      // 1. Arrange
      final members = [member('ana'), member('bia'), member('caio')];

      // 2. Act
      final result = rows(
        members: members,
        observingToday: false,
        usersWithPoints: {'caio@x.org'},
      );

      // 3. Assert
      expect(names(result), ['caio', 'ana', 'bia']);
      expect(result.first.presence, dayPresence(hasPoints: true));
    });

    test('Edge Case: a past day ignores whether the person shares now', () {
      // 1. Arrange
      final members = [member('ana')];
      final users = [doc('ana')]; // live today

      // 2. Act
      final result = rows(
        members: members,
        users: users,
        observingToday: false,
      );

      // 3. Assert
      expect(result.single.presence, dayPresence(hasPoints: false));
    });

    test('Edge Case: a past day still carries the live document', () {
      // 1. Arrange
      final ana = member('ana');
      final anaDoc = doc('ana');

      // 2. Act
      final result = rows(
        members: [ana],
        users: [anaDoc],
        observingToday: false,
      );

      // 3. Assert
      expect(identical(result.single.user, anaDoc), isTrue);
    });

    test('Sad Path: positions of someone outside the team are ignored', () {
      // 1. Arrange
      final members = [member('ana')];

      // 2. Act
      final result = rows(
        members: members,
        observingToday: false,
        usersWithPoints: {'intruso@x.org'},
      );

      // 3. Assert
      expect(result.single.presence, dayPresence(hasPoints: false));
    });

    test('Sad Path: today ignores usersWithPoints', () {
      // 1. Arrange
      final members = [member('ana')];

      // 2. Act
      final result = rows(members: members, usersWithPoints: {'ana@x.org'});

      // 3. Assert
      expect(result.single.presence.kind, PresenceKind.never);
    });
  });
}
