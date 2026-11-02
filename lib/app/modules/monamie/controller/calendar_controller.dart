import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/modules/monamie/history/history_month.dart';

/// The day the map shows (today or a past day) and the month of the history
/// calendar. Each value is its own [ValueListenable], so the tracking
/// controller follows the observed day alone. Whoever creates it calls
/// [dispose] once.
class CalendarController {
  /// [groupMap] gives the observed group and its history members;
  /// [positions] reads the trail days, [FirebaseProvider] by default.
  CalendarController({required this._groupMap, FirebaseProvider? positions})
    : _positions = positions ?? FirebaseProvider();

  final GroupMapState _groupMap;
  final FirebaseProvider _positions;

  final _observedDay = ValueNotifier<DateTime>(_today());

  late final _viewMonth = ValueNotifier<HistoryMonth>(
    HistoryMonth(
      year: _observedDay.value.year,
      month: _observedDay.value.month,
      today: DateTime.now(),
    ),
  );

  final _isLoadingMonth = ValueNotifier<bool>(false);

  bool _disposed = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The day the map shows, at midnight.
  ValueListenable<DateTime> get observedDay => _observedDay;

  /// The month shown by the history calendar.
  ValueListenable<HistoryMonth> get viewMonth => _viewMonth;

  /// Whether the trail days of [viewMonth] are being read.
  ValueListenable<bool> get isLoadingMonth => _isLoadingMonth;

  bool get isObservingToday => _observedDay.value == _today();

  String get observedDayFormatted {
    final d = _observedDay.value;
    final today = _today();
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

  void goToToday() => _set(_observedDay, _today());

  /// Prepares *Histórico por data* (the screen then opens the sheet): shows
  /// the observed day's month and starts loading its trail days.
  void showObservedMonth() {
    final day = _observedDay.value;
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
    _set(_observedDay, DateTime(day.year, day.month, day.day));
  }

  /// Marks the days of the shown month when someone shared their location
  /// in the observed group, including people who no longer publish there
  /// (one summary read per person and day).
  Future<void> _loadTrailDays() async {
    final month = _viewMonth.value;
    final groupId = _groupMap.selectedGroup.value?.id;
    if (groupId == null || _disposed) return;
    _set(_isLoadingMonth, true);
    try {
      final emails = [
        for (final member in await _groupMap.loadHistoryMembers()) member.email,
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
    _observedDay.dispose();
    _viewMonth.dispose();
    _isLoadingMonth.dispose();
  }
}
