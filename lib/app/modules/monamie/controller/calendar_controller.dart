import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

class CalendarController extends GetxController {
  final _observedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).obs;
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

  Future<void> pickDay(BuildContext context) async {
    final now = DateTime.now();
    final initial = _observedDay.value;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.darkBlue(),
              onPrimary: Colors.white,
              onSurface: AppColors.darkBlue(),
              secondary: AppColors.mediumBlue(),
              onSecondary: Colors.white,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mediumBlue(),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: AppColors.darkBlue(),
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey;
                }
                return AppColors.darkBlue();
              }),
              dayBackgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.mediumBlue();
                }
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.mediumBlue();
              }),
              todayBackgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.mediumBlue();
                }
                return Colors.transparent;
              }),
              todayBorder: BorderSide(color: AppColors.mediumBlue(), width: 1),
              yearForegroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.darkBlue();
              }),
              yearBackgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.mediumBlue();
                }
                return Colors.transparent;
              }),
              yearOverlayColor: WidgetStateColor.resolveWith((_) {
                return AppColors.lightBlue();
              }),
              dayOverlayColor: WidgetStateColor.resolveWith((_) {
                return AppColors.lightBlue();
              }),
              rangeSelectionBackgroundColor: AppColors.lightBlue(),
              dividerColor: AppColors.lightBlue(),
              weekdayStyle: TextStyle(color: AppColors.alternativeMediumBlue()),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    _observedDay.value = DateTime(picked.year, picked.month, picked.day);
  }
}