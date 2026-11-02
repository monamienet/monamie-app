// check_layers: state_contract

import 'package:flutter/foundation.dart';

/// The day the map shows (today or a past day), picked in the history
/// calendar: the bound organization's shared state that the calendar, the
/// tracking view model (its markers and trails) and the home screen read.
/// It lives in memory only, as long as the organization's scope.
///
/// Whoever creates it calls [dispose] once.
class ObservedDayRepository {
  final _observedDay = ValueNotifier<DateTime>(_today());

  bool _disposed = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The day the map shows, at midnight; notifies only when it changes.
  ValueListenable<DateTime> get observedDay => _observedDay;

  bool get isObservingToday => _observedDay.value == _today();

  /// Observes [day], at midnight.
  void select(DateTime day) {
    if (!_disposed) {
      _observedDay.value = DateTime(day.year, day.month, day.day);
    }
  }

  /// Observes today again.
  void goToToday() => select(_today());

  /// Releases the value. Only the first call does anything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _observedDay.dispose();
  }
}
