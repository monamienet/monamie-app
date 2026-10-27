import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/presence.dart';

final now = DateTime(2026, 10, 27, 12, 0);
const staleAfter = Duration(minutes: 10);

Presence presence({
  bool hasRecord = true,
  bool? isTracked = true,
  DateTime? lastSeen,
}) => presenceOf(
  hasRecord: hasRecord,
  isTracked: isTracked,
  lastSeen: lastSeen,
  now: now,
  staleAfter: staleAfter,
);

void main() {
  group('presenceOf - Unit Test Suite', () {
    test('Happy Path: a recent position is live and reads "Agora"', () {
      // 1. Arrange
      final lastSeen = now.subtract(const Duration(minutes: 3));

      // 2. Act
      final result = presence(lastSeen: lastSeen);

      // 3. Assert
      expect(result, const Presence(PresenceKind.live, 'Agora'));
    });

    test('Happy Path: a silent person is stale with a capitalized ago', () {
      // 1. Arrange
      final lastSeen = now.subtract(const Duration(minutes: 12));

      // 2. Act
      final result = presence(lastSeen: lastSeen);

      // 3. Assert
      expect(result, const Presence(PresenceKind.stale, 'Há 12 min'));
    });

    test('Happy Path: someone who turned it off says so, with when', () {
      // 1. Arrange
      final lastSeen = now.subtract(const Duration(hours: 2));

      // 2. Act
      final result = presence(isTracked: false, lastSeen: lastSeen);

      // 3. Assert
      expect(
        result,
        const Presence(
          PresenceKind.off,
          'Localização desligada · visto há 2 h',
        ),
      );
    });

    test('Edge Case: exactly staleAfter of silence is already stale', () {
      // 1. Arrange
      final lastSeen = now.subtract(staleAfter);

      // 2. Act
      final result = presence(lastSeen: lastSeen);

      // 3. Assert
      expect(result, const Presence(PresenceKind.stale, 'Há 10 min'));
    });

    test('Edge Case: one second under staleAfter is still live', () {
      // 1. Arrange
      final lastSeen = now.subtract(staleAfter - const Duration(seconds: 1));

      // 2. Act
      final result = presence(lastSeen: lastSeen);

      // 3. Assert
      expect(result.kind, PresenceKind.live);
    });

    test('Edge Case: a document without isTracked counts as sharing', () {
      // 1. Arrange
      final lastSeen = now.subtract(const Duration(minutes: 1));

      // 2. Act
      final result = presence(isTracked: null, lastSeen: lastSeen);

      // 3. Assert
      expect(result.kind, PresenceKind.live);
    });

    test('Edge Case: off without a known last position has no "visto"', () {
      // 1. Arrange / 2. Act
      final result = presence(isTracked: false, lastSeen: null);

      // 3. Assert
      expect(result, const Presence(PresenceKind.off, 'Localização desligada'));
    });

    test('Edge Case: off wins over stale however long ago it was seen', () {
      // 1. Arrange
      final lastSeen = now.subtract(const Duration(days: 5));

      // 2. Act
      final result = presence(isTracked: false, lastSeen: lastSeen);

      // 3. Assert
      expect(result.kind, PresenceKind.off);
    });

    test('Edge Case: silent since yesterday reads "Ontem"', () {
      // 1. Arrange
      final lastSeen = DateTime(2026, 10, 26, 9, 0);

      // 2. Act
      final result = presence(lastSeen: lastSeen);

      // 3. Assert
      expect(result, const Presence(PresenceKind.stale, 'Ontem'));
    });

    test('Sad Path: no document at all is "never"', () {
      // 1. Arrange / 2. Act
      final result = presence(hasRecord: false, isTracked: null);

      // 3. Assert
      expect(
        result,
        const Presence(PresenceKind.never, 'Ainda não ativou a localização'),
      );
    });

    test('Sad Path: no document wins over a stray isTracked false', () {
      // 1. Arrange / 2. Act
      final result = presence(hasRecord: false, isTracked: false);

      // 3. Assert
      expect(result.kind, PresenceKind.never);
    });

    test('Sad Path: a document that never got a position is "never"', () {
      // 1. Arrange / 2. Act
      final result = presence(isTracked: true, lastSeen: null);

      // 3. Assert
      expect(result.kind, PresenceKind.never);
    });

    test('Sad Path: a document with neither flag nor position is "never"', () {
      // 1. Arrange / 2. Act
      final result = presence(isTracked: null, lastSeen: null);

      // 3. Assert
      expect(result.kind, PresenceKind.never);
    });
  });

  group('agoLabel - Unit Test Suite', () {
    final cases = <(String, DateTime, String)>[
      ('30 seconds', now.subtract(const Duration(seconds: 30)), 'agora'),
      ('59 seconds', now.subtract(const Duration(seconds: 59)), 'agora'),
      ('60 seconds', now.subtract(const Duration(seconds: 60)), 'há 1 min'),
      ('12 minutes', now.subtract(const Duration(minutes: 12)), 'há 12 min'),
      ('59 minutes', now.subtract(const Duration(minutes: 59)), 'há 59 min'),
      ('60 minutes', now.subtract(const Duration(minutes: 60)), 'há 1 h'),
      ('23 hours', now.subtract(const Duration(hours: 23)), 'há 23 h'),
      (
        '23 hours 59 minutes',
        now.subtract(const Duration(hours: 23, minutes: 59)),
        'há 23 h',
      ),
      ('24 hours, previous day', DateTime(2026, 10, 26, 12, 0), 'ontem'),
      ('26 hours, previous day', DateTime(2026, 10, 26, 10, 0), 'ontem'),
      ('start of yesterday', DateTime(2026, 10, 26, 0, 0), 'ontem'),
      ('48 hours', DateTime(2026, 10, 25, 12, 0), 'há 2 dias'),
      ('3 days', DateTime(2026, 10, 24, 12, 0), 'há 3 dias'),
      ('across a month', DateTime(2026, 9, 27, 12, 0), 'há 30 dias'),
    ];
    for (final (label, then, expected) in cases) {
      test('Boundary: $label -> "$expected"', () {
        // 1. Arrange
        final seen = then;

        // 2. Act
        final ago = agoLabel(seen, now);

        // 3. Assert
        expect(ago, expected);
      });
    }

    test('Edge Case: 20 minutes across midnight is minutes, not "ontem"', () {
      // 1. Arrange
      final justAfterMidnight = DateTime(2026, 10, 27, 0, 10);
      final lastSeen = DateTime(2026, 10, 26, 23, 50);

      // 2. Act
      final label = agoLabel(lastSeen, justAfterMidnight);

      // 3. Assert
      expect(label, 'há 20 min');
    });

    test('Edge Case: 26 hours that span two calendar days is "há 2 dias"', () {
      // 1. Arrange
      final earlyMorning = DateTime(2026, 10, 27, 1, 0);
      final lastSeen = DateTime(2026, 10, 25, 23, 0);

      // 2. Act
      final label = agoLabel(lastSeen, earlyMorning);

      // 3. Assert
      expect(label, 'há 2 dias');
    });

    test('Sad Path: a position stamped in the future reads "agora"', () {
      // 1. Arrange
      final future = now.add(const Duration(minutes: 5));

      // 2. Act
      final label = agoLabel(future, now);

      // 3. Assert
      expect(label, 'agora');
    });
  });

  group('dayPresence - Unit Test Suite', () {
    test('Happy Path: a person with positions that day has a trail', () {
      // 1. Arrange / 2. Act
      final result = dayPresence(hasPoints: true);

      // 3. Assert
      expect(result.kind, PresenceKind.live);
    });

    test('Edge Case: a person without positions that day reads as off', () {
      // 1. Arrange / 2. Act
      final result = dayPresence(hasPoints: false);

      // 3. Assert
      expect(result.kind, PresenceKind.off);
    });
  });
}
