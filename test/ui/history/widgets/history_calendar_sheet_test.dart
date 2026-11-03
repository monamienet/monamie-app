import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/ui/history/widgets/history_calendar_sheet.dart';
import 'package:monamie_app/domain/models/history_month.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

import '../../home/widgets/home_doubles.mocks.dart';

final _today = DateTime(2026, 11, 2);

/// A calendar mock showing November 2026, its values changed by the test.
class _Calendar {
  _Calendar() {
    when(mock.viewMonth).thenReturn(viewMonth);
    when(mock.observedDay).thenReturn(observedDay);
    when(mock.isLoadingMonth).thenReturn(isLoadingMonth);
  }

  final mock = MockCalendarViewModel();
  final viewMonth = ValueNotifier<HistoryMonth>(
    HistoryMonth(year: 2026, month: 11, today: _today),
  );
  final observedDay = ValueNotifier<DateTime>(_today);
  final isLoadingMonth = ValueNotifier<bool>(false);
}

/// The sheet over [calendar], on a phone-sized screen.
Future<void> _pumpSheet(WidgetTester tester, _Calendar calendar) {
  tester.view
    ..physicalSize = const Size(1200, 2700)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: Scaffold(body: HistoryCalendarSheet(controller: calendar.mock)),
    ),
  );
}

void main() {
  group('HistoryCalendarSheet - Widget Test Suite', () {
    testWidgets('Happy Path: another month shown renames the title', (
      tester,
    ) async {
      // 1. Arrange
      final calendar = _Calendar();
      await _pumpSheet(tester, calendar);

      // 2. Act
      calendar.viewMonth.value = HistoryMonth(
        year: 2026,
        month: 10,
        today: _today,
      );
      await tester.pump();

      // 3. Assert
      expect(find.text('Outubro de 2026'), findsOneWidget);
    });

    testWidgets('Edge Case: loading the trail days shows the spinner', (
      tester,
    ) async {
      // 1. Arrange
      final calendar = _Calendar();
      await _pumpSheet(tester, calendar);

      // 2. Act
      calendar.isLoadingMonth.value = true;
      await tester.pump();

      // 3. Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Edge Case: another observed day becomes the selected day', (
      tester,
    ) async {
      // 1. Arrange
      final calendar = _Calendar();
      await _pumpSheet(tester, calendar);

      // 2. Act
      calendar.observedDay.value = DateTime(2026, 11, 1);
      await tester.pump();

      // 3. Assert
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp(r'^1 de novembro'))),
        isSemantics(isSelected: true),
      );
    });
    testWidgets('Happy Path: in pt_BR the month and the weekday letters are '
        'Portuguese, Sunday first (#84)', (tester) async {
      // 1. Arrange
      final calendar = _Calendar();

      // 2. Act
      await _pumpSheet(tester, calendar);

      // 3. Assert
      expect(find.text('Novembro de 2026'), findsOneWidget);
      final letters = [
        for (final text in tester.widgetList<Text>(
          find.byWidgetPredicate(
            (w) => w is Text && (w.data?.length ?? 0) == 1,
          ),
        ))
          text.data,
      ];
      expect(letters.take(7), ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']);
    });
  });
}
