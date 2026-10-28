import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/data/live_users.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

final now = DateTime(2026, 10, 27, 12, 0);
const validity = Duration(minutes: 10);

UserModel user(String name, {bool? isTracked, DateTime? timestamp}) =>
    UserModel(email: '$name@x.org', isTracked: isTracked, timestamp: timestamp);

List<String> emails(List<UserModel> users) => [
  for (final user in users) user.email,
];

List<UserModel> live(List<UserModel> users) =>
    liveUsers(users, now: now, validity: validity);

void main() {
  group('liveUsers - Unit Test Suite', () {
    test('Happy Path: a sharing person with a fresh position is kept', () {
      // 1. Arrange
      final ana = user(
        'ana',
        isTracked: true,
        timestamp: now.subtract(const Duration(minutes: 2)),
      );

      // 2. Act
      final result = live([ana]);

      // 3. Assert
      expect(result, [same(ana)]);
    });

    test('Happy Path: only the fresh sharing people of a mix are kept', () {
      // 1. Arrange
      final users = [
        user(
          'fresh',
          isTracked: true,
          timestamp: now.subtract(const Duration(minutes: 1)),
        ),
        user(
          'old',
          isTracked: true,
          timestamp: now.subtract(const Duration(hours: 3)),
        ),
        user(
          'off',
          isTracked: false,
          timestamp: now.subtract(const Duration(minutes: 1)),
        ),
      ];

      // 2. Act
      final result = live(users);

      // 3. Assert
      expect(emails(result), ['fresh@x.org']);
    });

    test('Edge Case: a position exactly at the limit is not kept', () {
      // 1. Arrange
      final ana = user(
        'ana',
        isTracked: true,
        timestamp: now.subtract(validity),
      );

      // 2. Act
      final result = live([ana]);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Edge Case: one second inside the limit is kept', () {
      // 1. Arrange
      final ana = user(
        'ana',
        isTracked: true,
        timestamp: now.subtract(validity - const Duration(seconds: 1)),
      );

      // 2. Act
      final result = live([ana]);

      // 3. Assert
      expect(emails(result), ['ana@x.org']);
    });

    test('Edge Case: a position stamped exactly now is kept', () {
      // 1. Arrange
      final ana = user('ana', isTracked: true, timestamp: now);

      // 2. Act
      final result = live([ana]);

      // 3. Assert
      expect(emails(result), ['ana@x.org']);
    });

    test('Edge Case: the input order is preserved', () {
      // 1. Arrange
      final users = [
        for (final name in ['carla', 'ana', 'bia'])
          user(
            name,
            isTracked: true,
            timestamp: now.subtract(const Duration(minutes: 1)),
          ),
      ];

      // 2. Act
      final result = live(users);

      // 3. Assert
      expect(emails(result), ['carla@x.org', 'ana@x.org', 'bia@x.org']);
    });

    test('Edge Case: a zero validity keeps nobody', () {
      // 1. Arrange
      final ana = user('ana', isTracked: true, timestamp: now);

      // 2. Act
      final result = liveUsers([ana], now: now, validity: Duration.zero);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Edge Case: empty input gives empty output', () {
      // 1. Arrange / 2. Act
      final result = live(const []);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Sad Path: isTracked false is dropped however fresh', () {
      // 1. Arrange
      final ana = user('ana', isTracked: false, timestamp: now);

      // 2. Act
      final result = live([ana]);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Sad Path: isTracked null is dropped however fresh', () {
      // 1. Arrange
      final ana = user('ana', isTracked: null, timestamp: now);

      // 2. Act
      final result = live([ana]);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Sad Path: a null timestamp is dropped even when tracked', () {
      // 1. Arrange
      final ana = user('ana', isTracked: true, timestamp: null);

      // 2. Act
      final result = live([ana]);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Sad Path: a position older than the limit is dropped', () {
      // 1. Arrange
      final ana = user(
        'ana',
        isTracked: true,
        timestamp: now.subtract(const Duration(days: 1)),
      );

      // 2. Act
      final result = live([ana]);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Regression: the same snapshot drops the person once time passes', () {
      // 1. Arrange: sharing, 2 min old now, nobody writes again afterwards
      final ana = user(
        'ana',
        isTracked: true,
        timestamp: now.subtract(const Duration(minutes: 2)),
      );
      final stillThere = live([ana]);

      // 2. Act: 9 minutes later, with the limit at 10
      final later = liveUsers(
        [ana],
        now: now.add(const Duration(minutes: 9)),
        validity: validity,
      );

      // 3. Assert
      expect(emails(stillThere), ['ana@x.org']);
      expect(later, isEmpty);
    });
  });
}
