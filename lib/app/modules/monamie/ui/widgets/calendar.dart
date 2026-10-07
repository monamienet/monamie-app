import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  CalendarController get calendarCtrl => Get.find<CalendarController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isToday = calendarCtrl.isObservingToday;

      return Positioned(
        top: 16,
        left: 16,
        child: Material(
          color: AppColors.darkBlue().withAlpha(220),
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(children: [
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit_calendar, color: Colors.white70, size: 18),
                      onPressed: () => calendarCtrl.pickDay(context),
                    ),
                    
                    if (!isToday) ...[
                      const SizedBox(width: 4),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: calendarCtrl.goToToday,
                        child: const Text(
                          'Voltar para Hoje',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                ]),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Dia observado: ', style: TextStyle(color: Colors.white),),
                    const SizedBox(width: 8),
                    Text(
                      calendarCtrl.observedDayFormatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}