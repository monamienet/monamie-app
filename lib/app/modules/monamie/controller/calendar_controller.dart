import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/modules/monamie/history/history_calendar_sheet.dart';
import 'package:monamie_app/app/modules/monamie/history/history_month.dart';

class CalendarController extends GetxController {
  final _observedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;
  Rx<DateTime> get observedDay => _observedDay;

  bool get isObservingToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _observedDay.value == today;
  }

  String get observedDayFormatted {
    final d = _observedDay.value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (d == today) return 'Hoje';
    if (d == yesterday) return 'Ontem';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void goToToday() {
    final now = DateTime.now();
    _observedDay.value = DateTime(now.year, now.month, now.day);
  }

  /// The month shown by the history calendar.
  late final Rx<HistoryMonth> viewMonth = HistoryMonth(
    year: _observedDay.value.year,
    month: _observedDay.value.month,
    today: DateTime.now(),
  ).obs;

  final RxBool isLoadingMonth = false.obs;

  /// Opens *Histórico por data* on the observed day's month.
  Future<void> pickDay(BuildContext context) async {
    final day = _observedDay.value;
    viewMonth.value = HistoryMonth(
      year: day.year,
      month: day.month,
      today: DateTime.now(),
    );
    _loadTrailDays();
    await HistoryCalendarSheet.show();
  }

  /// Moves the calendar [months] back or forward.
  void showMonth(int months) {
    viewMonth.value = viewMonth.value.shift(months);
    _loadTrailDays();
  }

  /// Observes [day] (the map redraws that day's trails).
  void selectDay(DateTime day) {
    _observedDay.value = DateTime(day.year, day.month, day.day);
  }

  /// Marks the days of the shown month when someone shared their location
  /// in the observed group, including people who no longer publish there
  /// (one summary read per person and day).
  Future<void> _loadTrailDays() async {
    final month = viewMonth.value;
    final groupMap = Get.find<GroupMapState>();
    final groupId = groupMap.selectedGroup.value?.id;
    if (groupId == null) return;
    isLoadingMonth.value = true;
    try {
      final emails = [
        for (final member in await groupMap.loadHistoryMembers()) member.email,
      ];
      final days = await FirebaseProvider().trailDays(groupId, emails, month);
      if (viewMonth.value.first == month.first) {
        viewMonth.value = month.shift(0, trailDays: days);
      }
    } catch (e) {
      debugPrint('[Calendar] Could not read the trail days: $e');
    } finally {
      isLoadingMonth.value = false;
    }
  }
}
