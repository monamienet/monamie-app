/// How many months back the history calendar goes (history is kept
/// indefinitely, so the calendar bounds what is offered, not what exists).
const historyMonthsBack = 12;

/// `yyyy-mm-dd` of [day] (its local date): the id of a day summary
/// (`usuarios/{email}/dias/{id}`) and the key of a calendar cell.
String dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// One day cell of the history calendar.
class HistoryDay {
  const HistoryDay({
    required this.date,
    required this.isFuture,
    required this.isToday,
    required this.hasTrails,
  });

  final DateTime date;

  /// Future days are shown but cannot be picked.
  final bool isFuture;

  final bool isToday;

  /// Someone shared their location that day: the cell gets a dot.
  final bool hasTrails;
}

/// The month grid of *Histórico por data*: weeks start on Sunday, so the
/// month is preceded by [leadingBlanks] empty cells.
class HistoryMonth {
  HistoryMonth({
    required int year,
    required int month,
    required DateTime today,
    this.trailDays = const {},
  }) : first = DateTime(year, month),
       _today = DateTime(today.year, today.month, today.day);

  /// The first day of the month shown.
  final DateTime first;
  final DateTime _today;

  /// Keys (`yyyy-mm-dd`) of the days with trails.
  final Set<String> trailDays;

  /// Empty cells before day 1 (0 when the month starts on a Sunday).
  int get leadingBlanks => first.weekday % 7;

  int get daysInMonth => DateTime(first.year, first.month + 1, 0).day;

  List<HistoryDay> get days => [
    for (var d = 1; d <= daysInMonth; d++)
      _day(DateTime(first.year, first.month, d)),
  ];

  HistoryDay _day(DateTime date) {
    final isFuture = date.isAfter(_today);
    return HistoryDay(
      date: date,
      isFuture: isFuture,
      isToday: date == _today,
      hasTrails: !isFuture && trailDays.contains(dayKey(date)),
    );
  }

  /// Whether the previous month is still within [historyMonthsBack].
  bool get canGoBack {
    final oldest = DateTime(_today.year, _today.month - historyMonthsBack);
    return first.isAfter(oldest);
  }

  /// Whether the next month has started (never beyond today's month).
  bool get canGoForward => first.isBefore(DateTime(_today.year, _today.month));

  /// The month before or after this one.
  HistoryMonth shift(int months, {Set<String> trailDays = const {}}) =>
      HistoryMonth(
        year: first.year,
        month: first.month + months,
        today: _today,
        trailDays: trailDays,
      );

  /// `yyyy-mm-dd` bounds of this month, for a document-id range query.
  (String, String) get keyRange =>
      (dayKey(first), dayKey(DateTime(first.year, first.month, daysInMonth)));
}
