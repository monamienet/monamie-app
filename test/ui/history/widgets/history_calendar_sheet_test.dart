import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

/// App texts in Portuguese whatever the locale: French and Spanish have no app
/// texts yet, but Material's own (`GlobalMaterialLocalizations`) do exist.
class _PortugueseAppTexts extends LocalizationsDelegate<AppLocalizations> {
  const _PortugueseAppTexts();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(lookupAppLocalizations(const Locale('pt')));

  @override
  bool shouldReload(_PortugueseAppTexts old) => false;
}

/// The sheet over [calendar] in French, a language whose week starts on Monday.
Future<void> _pumpSheetInFrench(WidgetTester tester, _Calendar calendar) {
  tester.view
    ..physicalSize = const Size(1200, 2700)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        _PortugueseAppTexts(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      home: Scaffold(body: HistoryCalendarSheet(controller: calendar.mock)),
    ),
  );
}

/// The seven weekday letters of the header, left to right (the first one-letter
/// texts of the sheet).
List<String?> _headerLetters(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(
    find.byWidgetPredicate((w) => w is Text && (w.data?.length ?? 0) == 1),
  ))
    text.data,
].take(7).toList();

/// The center of the header letter in column [column] (0 is the leftmost).
Offset _headerCenter(WidgetTester tester, int column) {
  final letters = tester
      .widgetList<Text>(
        find.byWidgetPredicate((w) => w is Text && (w.data?.length ?? 0) == 1),
      )
      .take(7)
      .toList();
  return tester.getCenter(find.byWidget(letters[column]));
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

    testWidgets('Happy Path: in pt_BR day 1 of November 2026 (a Sunday) falls '
        'under the first column, "D"', (tester) async {
      // 1. Arrange
      final calendar = _Calendar();

      // 2. Act
      await _pumpSheet(tester, calendar);

      // 3. Assert
      final sundayX = _headerCenter(tester, 0).dx;
      expect(_headerLetters(tester).first, 'D');
      expect(tester.getCenter(find.text('1')).dx, closeTo(sundayX, 1));
    });

    testWidgets('Happy Path: in French the header starts with Monday and day '
        '1 falls under its weekday', (tester) async {
      // 1. Arrange
      final calendar = _Calendar();

      // 2. Act
      await _pumpSheetInFrench(tester, calendar);

      // 3. Assert: November 2026 starts on a Sunday, the last French column.
      final letters = _headerLetters(tester);
      expect(letters.first, 'L');
      expect(letters.last, 'D');
      final sundayX = _headerCenter(tester, 6).dx;
      final mondayX = _headerCenter(tester, 0).dx;
      final dayOne = tester.getCenter(find.text('1'));
      expect(dayOne.dx, closeTo(sundayX, 1));
      expect(dayOne.dx, greaterThan(mondayX));
      // Day 2 is a Monday: first column of the second row.
      final dayTwo = tester.getCenter(find.text('2'));
      expect(dayTwo.dx, closeTo(mondayX, 1));
      expect(dayTwo.dy, greaterThan(dayOne.dy));
    });
  });
}
