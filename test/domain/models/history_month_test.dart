import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/history_month.dart';

/// 27 October 2026, mid-afternoon: the time of day must be ignored.
final today = DateTime(2026, 10, 27, 15, 30);

HistoryMonth monthOf(int year, int month, {Set<String> trailDays = const {}}) =>
    HistoryMonth(year: year, month: month, today: today, trailDays: trailDays);

/// The cell of day [day] in [month].
HistoryDay cellOf(HistoryMonth month, int day) => month.days[day - 1];

void main() {
  group('historyMonthsBack - Unit Test Suite', () {
    test('Happy Path: the calendar goes 12 months back', () {
      // 1. Arrange
      const expected = 12;

      // 2. Act
      const value = historyMonthsBack;

      // 3. Assert
      expect(value, expected);
    });
  });

  group('dayKey - Unit Test Suite', () {
    final cases = <(String, DateTime, String)>[
      (
        'Happy Path: a two-digit month and day',
        DateTime(2026, 10, 27),
        '2026-10-27',
      ),
      (
        'Edge Case: month and day are zero-padded',
        DateTime(2026, 3, 7),
        '2026-03-07',
      ),
      (
        'Edge Case: the time of day is ignored',
        DateTime(2026, 12, 31, 23, 59, 59),
        '2026-12-31',
      ),
    ];
    for (final (label, date, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final day = date;

        // 2. Act
        final key = dayKey(day);

        // 3. Assert
        expect(key, expected);
      });
    }
  });

  group('HistoryMonth.leadingBlanks - Unit Test Suite', () {
    const sunday = 0;
    const monday = 1;
    const saturday = 6;
    final cases = <(String, int, int, int, int)>[
      // (label, year, month, first day of the week, expected blanks)
      (
        'Happy Path: October 2026 starts on a Thursday, Sunday first',
        2026,
        10,
        sunday,
        4,
      ),
      (
        'Edge Case: November 2026 starts on a Sunday, Sunday first',
        2026,
        11,
        sunday,
        0,
      ),
      (
        'Edge Case: August 2026 starts on a Saturday, Sunday first',
        2026,
        8,
        sunday,
        6,
      ),
      (
        'Happy Path: October 2026 starts on a Thursday, Monday first',
        2026,
        10,
        monday,
        3,
      ),
      (
        'Edge Case: November 2026 starts on a Sunday, Monday first',
        2026,
        11,
        monday,
        6,
      ),
      (
        'Edge Case: August 2026 starts on a Saturday, Monday first',
        2026,
        8,
        monday,
        5,
      ),
      (
        'Edge Case: a month starting on a Monday has none, Monday first',
        2026,
        6,
        monday,
        0,
      ),
      (
        'Edge Case: a month starting on a Monday has one, Sunday first',
        2026,
        6,
        sunday,
        1,
      ),
      (
        'Edge Case: a month starting on a Saturday has none, Saturday first',
        2026,
        8,
        saturday,
        0,
      ),
      (
        'Edge Case: October 2026 (Thursday), Saturday first',
        2026,
        10,
        saturday,
        5,
      ),
      (
        'Edge Case: November 2026 (Sunday), Saturday first',
        2026,
        11,
        saturday,
        1,
      ),
    ];
    for (final (label, year, month, firstDay, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final shown = monthOf(year, month);

        // 2. Act
        final blanks = shown.leadingBlanks(firstDay);

        // 3. Assert
        expect(blanks, expected);
      });
    }

    test('Edge Case: the blanks are always between 0 and 6', () {
      // 1. Arrange
      final months = [
        for (var m = 1; m <= 12; m++) monthOf(2026, m),
        for (var m = 1; m <= 12; m++) monthOf(2028, m),
      ];

      // 2. Act
      final all = [
        for (final shown in months)
          for (var firstDay = 0; firstDay <= 6; firstDay++)
            shown.leadingBlanks(firstDay),
      ];

      // 3. Assert
      expect(all.every((blanks) => blanks >= 0 && blanks <= 6), isTrue);
    });
  });

  group('HistoryMonth.weekdaysFrom - Unit Test Suite', () {
    const letters = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    final cases = <(String, List<String>, int, List<String>)>[
      (
        'Happy Path: Sunday first keeps the order',
        ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
        0,
        ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      ),
      (
        'Happy Path: Monday first starts at the second label and ends with '
            'the first',
        ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
        1,
        ['b', 'c', 'd', 'e', 'f', 'g', 'a'],
      ),
      (
        'Edge Case: Saturday first starts at the last label',
        ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
        6,
        ['g', 'a', 'b', 'c', 'd', 'e', 'f'],
      ),
      (
        'Edge Case: the Portuguese narrow labels, Monday first',
        letters,
        1,
        ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'],
      ),
      (
        'Edge Case: the Portuguese narrow labels, Sunday first',
        letters,
        0,
        letters,
      ),
    ];
    for (final (label, input, firstDay, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final sundayFirst = input;

        // 2. Act
        final rotated = HistoryMonth.weekdaysFrom(sundayFirst, firstDay);

        // 3. Assert
        expect(rotated, expected);
      });
    }

    test('Edge Case: the input list is not changed', () {
      // 1. Arrange
      final sundayFirst = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

      // 2. Act
      HistoryMonth.weekdaysFrom(sundayFirst, 1);

      // 3. Assert
      expect(sundayFirst, ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']);
    });

    test('Happy Path: the header and the grid agree on Monday first', () {
      // 1. Arrange
      final shown = monthOf(2026, 10); // starts on a Thursday
      const sundayFirst = ['0', '1', '2', '3', '4', '5', '6'];

      // 2. Act
      final header = HistoryMonth.weekdaysFrom(sundayFirst, 1);
      final column = shown.leadingBlanks(1);

      // 3. Assert: day 1 sits under Thursday's label (index 4 of the week).
      expect(header[column], '4');
    });
  });

  group('HistoryMonth.daysInMonth - Unit Test Suite', () {
    final cases = <(String, int, int, int)>[
      ('Happy Path: October has 31 days', 2026, 10, 31),
      ('Edge Case: February of a leap year has 29 days', 2028, 2, 29),
      ('Edge Case: February of a common year has 28 days', 2026, 2, 28),
    ];
    for (final (label, year, month, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final shown = monthOf(year, month);

        // 2. Act
        final count = shown.daysInMonth;

        // 3. Assert
        expect(count, expected);
      });
    }
  });

  group('HistoryMonth.days - Unit Test Suite', () {
    test('Happy Path: one cell per day, in order, from the 1st', () {
      // 1. Arrange
      final shown = monthOf(2026, 10);

      // 2. Act
      final days = shown.days;

      // 3. Assert
      expect(days.map((d) => dayKey(d.date)), [
        for (var d = 1; d <= 31; d++) '2026-10-${d.toString().padLeft(2, '0')}',
      ]);
    });

    final flagCases = <(String, int, bool, bool)>[
      // (label, day of October 2026, isFuture, isToday)
      ('Happy Path: a past day is neither future nor today', 26, false, false),
      ('Edge Case: today is not future, and is today', 27, false, true),
      ('Edge Case: tomorrow is future', 28, true, false),
      ('Edge Case: the last day of the month is future', 31, true, false),
    ];
    for (final (label, day, isFuture, isToday) in flagCases) {
      test(label, () {
        // 1. Arrange
        final shown = monthOf(2026, 10);

        // 2. Act
        final cell = cellOf(shown, day);

        // 3. Assert
        expect((cell.isFuture, cell.isToday), (isFuture, isToday));
      });
    }

    test('Edge Case: every day of a past month is past and none is today', () {
      // 1. Arrange
      final shown = monthOf(2026, 9);

      // 2. Act
      final days = shown.days;

      // 3. Assert
      expect(days.any((d) => d.isFuture || d.isToday), isFalse);
    });

    test('Edge Case: every day of a future month is future', () {
      // 1. Arrange
      final shown = monthOf(2026, 11);

      // 2. Act
      final days = shown.days;

      // 3. Assert
      expect(days.every((d) => d.isFuture && !d.isToday), isTrue);
    });

    final trailDays = {'2026-10-05', '2026-10-27', '2026-10-30'};
    final trailCases = <(String, int, bool)>[
      ('Happy Path: a past day listed in trailDays has a dot', 5, true),
      ('Edge Case: today listed in trailDays has a dot', 27, true),
      ('Edge Case: a past day not listed has no dot', 6, false),
      ('Sad Path: a future day listed in trailDays has no dot', 30, false),
    ];
    for (final (label, day, expected) in trailCases) {
      test(label, () {
        // 1. Arrange
        final shown = monthOf(2026, 10, trailDays: trailDays);

        // 2. Act
        final cell = cellOf(shown, day);

        // 3. Assert
        expect(cell.hasTrails, expected);
      });
    }

    test('Sad Path: a key of another month gives no dot', () {
      // 1. Arrange
      final shown = monthOf(2026, 9, trailDays: {'2026-10-05'});

      // 2. Act
      final cell = cellOf(shown, 5);

      // 3. Assert
      expect(cell.hasTrails, isFalse);
    });
  });

  group('HistoryMonth.canGoBack - Unit Test Suite', () {
    final cases = <(String, int, int, bool)>[
      ("Happy Path: today's month can go back", 2026, 10, true),
      ('Edge Case: 11 months before today can go back', 2025, 11, true),
      ('Edge Case: 12 months before today cannot go back', 2025, 10, false),
      (
        'Sad Path: more than 12 months before today cannot go back',
        2025,
        3,
        false,
      ),
    ];
    for (final (label, year, month, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final shown = monthOf(year, month);

        // 2. Act
        final canGoBack = shown.canGoBack;

        // 3. Assert
        expect(canGoBack, expected);
      });
    }
  });

  group('HistoryMonth.canGoForward - Unit Test Suite', () {
    final cases = <(String, int, int, bool)>[
      ('Happy Path: the month before today can go forward', 2026, 9, true),
      (
        'Edge Case: a month of the previous year can go forward',
        2025,
        12,
        true,
      ),
      ("Edge Case: today's month cannot go forward", 2026, 10, false),
      ('Sad Path: a future month cannot go forward', 2026, 11, false),
    ];
    for (final (label, year, month, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final shown = monthOf(year, month);

        // 2. Act
        final canGoForward = shown.canGoForward;

        // 3. Assert
        expect(canGoForward, expected);
      });
    }
  });

  group('HistoryMonth.shift - Unit Test Suite', () {
    final cases = <(String, int, int, int, String)>[
      // (label, year, month, n, first day of the result)
      (
        'Happy Path: one month back in the same year',
        2026,
        10,
        -1,
        '2026-09-01',
      ),
      (
        'Edge Case: January back crosses to December',
        2027,
        1,
        -1,
        '2026-12-01',
      ),
      (
        'Edge Case: December forward crosses to January',
        2026,
        12,
        1,
        '2027-01-01',
      ),
      (
        'Edge Case: twelve months back is the same month a year before',
        2026,
        10,
        -12,
        '2025-10-01',
      ),
    ];
    for (final (label, year, month, n, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final shown = monthOf(year, month);

        // 2. Act
        final shifted = shown.shift(n);

        // 3. Assert
        expect(shifted.keyRange.$1, expected);
      });
    }

    test('Edge Case: the shifted month keeps the same today', () {
      // 1. Arrange
      final shown = monthOf(2026, 9);

      // 2. Act
      final shifted = shown.shift(1);

      // 3. Assert
      expect(cellOf(shifted, 27).isToday, isTrue);
    });

    test('Happy Path: the shifted month takes the trail days given', () {
      // 1. Arrange
      final shown = monthOf(2026, 10, trailDays: {'2026-10-05'});

      // 2. Act
      final shifted = shown.shift(-1, trailDays: {'2026-09-05'});

      // 3. Assert
      expect(cellOf(shifted, 5).hasTrails, isTrue);
    });
  });

  group('HistoryMonth.keyRange - Unit Test Suite', () {
    final cases = <(String, int, int, (String, String))>[
      (
        'Happy Path: October runs from the 1st to the 31st',
        2026,
        10,
        ('2026-10-01', '2026-10-31'),
      ),
      (
        'Edge Case: February of a leap year ends on the 29th',
        2028,
        2,
        ('2028-02-01', '2028-02-29'),
      ),
      (
        'Edge Case: February of a common year ends on the 28th',
        2026,
        2,
        ('2026-02-01', '2026-02-28'),
      ),
    ];
    for (final (label, year, month, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final shown = monthOf(year, month);

        // 2. Act
        final range = shown.keyRange;

        // 3. Assert
        expect(range, expected);
      });
    }
  });
}
