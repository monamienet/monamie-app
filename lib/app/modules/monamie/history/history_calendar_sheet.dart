import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_palette.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';

import 'history_month.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _future = Color(0xFFB9B4C9);
const _soft = Color(0xFFF1F0F4);

const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// *Histórico por data*: a month calendar over the map. Days with trails
/// have a dot, future days cannot be picked, today is outlined.
class HistoryCalendarSheet extends StatelessWidget {
  const HistoryCalendarSheet({super.key});

  static Future<void> show() => Get.bottomSheet(
    const HistoryCalendarSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalendarController>();
    final palette = PartnerPalette.fromConfig(Partner.current);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Obx(() {
          final month = controller.viewMonth.value;
          final selected = controller.observedDay.value;
          final title =
              '${_months[month.first.month - 1]} de ${month.first.year}';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9C3D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title[0].toUpperCase() + title.substring(1),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                  if (controller.isLoadingMonth.value)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  _Arrow(
                    icon: Icons.chevron_left,
                    label: 'Mês anterior',
                    onTap: month.canGoBack
                        ? () => controller.showMonth(-1)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _Arrow(
                    icon: Icons.chevron_right,
                    label: 'Próximo mês',
                    onTap: month.canGoForward
                        ? () => controller.showMonth(1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final letter in const [
                    'D',
                    'S',
                    'T',
                    'Q',
                    'Q',
                    'S',
                    'S',
                  ])
                    Expanded(
                      child: Center(
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < month.leadingBlanks; i++)
                    const SizedBox.shrink(),
                  for (final day in month.days)
                    _DayCell(
                      day: day,
                      selected: day.date == selected,
                      color: palette.primary,
                      onColor: palette.onPrimary,
                      onTap: day.isFuture
                          ? null
                          : () {
                              controller.selectDay(day.date);
                              Get.back();
                            },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Dias com trajetos',
                    style: TextStyle(fontSize: 13, color: _muted),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _soft,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon, color: onTap == null ? _future : _ink),
    ),
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final HistoryDay day;
  final bool selected;
  final Color color;
  final Color onColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? onColor
        : day.isFuture
        ? _future
        : _ink;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !day.isFuture,
      label:
          '${day.date.day} de ${_months[day.date.month - 1]}'
          '${day.isToday ? ', hoje' : ''}'
          '${day.isFuture
              ? ', ainda não chegou'
              : day.hasTrails
              ? ', com trajetos'
              : ', sem trajetos'}',
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color : null,
            border: day.isToday && !selected
                ? Border.all(color: color, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.date.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected || day.isToday
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.hasTrails
                      ? (selected ? onColor : color)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
