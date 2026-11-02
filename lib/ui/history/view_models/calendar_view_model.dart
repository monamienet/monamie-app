import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/data/repositories/observed_day/observed_day_repository.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/domain/models/history_month.dart';

/// The history calendar: the month it shows and its trail days, over the
/// day the map shows ([ObservedDayRepository], which the tracking view model
/// follows too). Each value is its own [ValueListenable]. Whoever creates it
/// calls [dispose] once.
class CalendarViewModel {
  /// [memberships] gives the observed group and its history members;
  /// [observedDay] holds the day the map shows; [positions] reads the trail
  /// days.
  CalendarViewModel({
    required this._memberships,
    required this._observedDay,
    required this._positions,
  });

  final MembershipRepository _memberships;
  final ObservedDayRepository _observedDay;
  final PositionsRepository _positions;

  late final _viewMonth = ValueNotifier<HistoryMonth>(
    HistoryMonth(
      year: observedDay.value.year,
      month: observedDay.value.month,
      today: DateTime.now(),
    ),
  );

  final _isLoadingMonth = ValueNotifier<bool>(false);

  bool _disposed = false;

  /// The day the map shows, at midnight ([ObservedDayRepository]).
  ValueListenable<DateTime> get observedDay => _observedDay.observedDay;

  /// The month shown by the history calendar.
  ValueListenable<HistoryMonth> get viewMonth => _viewMonth;

  /// Whether the trail days of [viewMonth] are being read.
  ValueListenable<bool> get isLoadingMonth => _isLoadingMonth;

  bool get isObservingToday => _observedDay.isObservingToday;

  String get observedDayFormatted {
    final d = observedDay.value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (d == today) return 'Hoje';
    if (d == yesterday) return 'Ontem';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Sets [notifier] unless disposed: a trail-day read may finish after
  /// [dispose].
  void _set<T>(ValueNotifier<T> notifier, T value) {
    if (!_disposed) notifier.value = value;
  }

  void goToToday() {
    if (!_disposed) _observedDay.goToToday();
  }

  /// Prepares *Histórico por data* (the screen then opens the sheet): shows
  /// the observed day's month and starts loading its trail days.
  void showObservedMonth() {
    final day = observedDay.value;
    _set(
      _viewMonth,
      HistoryMonth(year: day.year, month: day.month, today: DateTime.now()),
    );
    _loadTrailDays();
  }

  /// Moves the calendar [months] back or forward.
  void showMonth(int months) {
    _set(_viewMonth, _viewMonth.value.shift(months));
    _loadTrailDays();
  }

  /// Observes [day] (the map redraws that day's trails).
  void selectDay(DateTime day) {
    if (!_disposed) _observedDay.select(day);
  }

  /// Marks the days of the shown month when someone shared their location
  /// in the observed group, including people who no longer publish there
  /// (one summary read per person and day).
  Future<void> _loadTrailDays() async {
    final month = _viewMonth.value;
    final groupId = _memberships.selectedGroup.value?.id;
    if (groupId == null || _disposed) return;
    _set(_isLoadingMonth, true);
    try {
      final emails = [
        for (final member in await _memberships.loadHistoryMembers())
          member.email,
      ];
      final days = await _positions.trailDays(groupId, emails, month);
      if (_viewMonth.value.first == month.first) {
        _set(_viewMonth, month.shift(0, trailDays: days));
      }
    } catch (e) {
      debugPrint('[Calendar] Could not read the trail days: $e');
    } finally {
      _set(_isLoadingMonth, false);
    }
  }

  /// Releases the values. Only the first call does anything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _viewMonth.dispose();
    _isLoadingMonth.dispose();
  }
}
