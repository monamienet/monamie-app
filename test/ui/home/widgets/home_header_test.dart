import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/widgets/group_menu_button.dart';
import 'package:monamie_app/ui/home/widgets/home_header.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

import 'home_doubles.dart';

const _guias = MapGroup(id: 'g1', name: 'Guias');
const _recepcao = MapGroup(id: 'g2', name: 'Recepção');

/// The header over [doubles].
Future<void> pumpHeader(WidgetTester tester, HomeDoubles doubles) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: Scaffold(
        body: HomeHeader(
          home: doubles.home,
          user: doubles.user,
          calendar: doubles.calendar,
        ),
      ),
    ),
  );
}

void main() {
  group('HomeHeader - Widget Test Suite', () {
    testWidgets('Happy Path: another observed group renames the group chip', (
      tester,
    ) async {
      // 1. Arrange
      final doubles = HomeDoubles()
        ..capabilities.value = watcherOf('g1')
        ..selectedGroup.value = _guias;
      await pumpHeader(tester, doubles);

      // 2. Act
      doubles.selectedGroup.value = _recepcao;
      await tester.pump();

      // 3. Assert
      expect(
        tester.widget<GroupMenuButton>(find.byType(GroupMenuButton)).label,
        'Recepção',
      );
    });

    testWidgets('Edge Case: being allowed to watch turns the group chip into '
        'the group menu and shows the day chip', (tester) async {
      // 1. Arrange
      final doubles = HomeDoubles()..selectedGroup.value = _guias;
      await pumpHeader(tester, doubles);

      // 2. Act
      doubles.capabilities.value = watcherOf('g1');
      await tester.pump();

      // 3. Assert
      expect(find.byType(GroupMenuButton), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
    });

    testWidgets('Sad Path: someone who only shares sees their group as a '
        'plain chip, without the day chip', (tester) async {
      // 1. Arrange
      final doubles = HomeDoubles();
      await pumpHeader(tester, doubles);

      // 2. Act
      doubles.publishGroups.value = const [_recepcao];
      await tester.pump();

      // 3. Assert
      expect(find.byType(GroupMenuButton), findsNothing);
      expect(find.text('Recepção'), findsOneWidget);
      expect(find.text('Hoje'), findsNothing);
    });
    testWidgets('Edge Case: the day before today reads "Ontem"', (
      tester,
    ) async {
      // 1. Arrange
      final doubles = HomeDoubles()..capabilities.value = watcherOf('g1');
      when(
        doubles.calendar.observedRelativeDay,
      ).thenReturn(RelativeDay.yesterday);

      // 2. Act
      await pumpHeader(tester, doubles);

      // 3. Assert
      expect(find.text('Ontem'), findsOneWidget);
      expect(find.text('Hoje'), findsNothing);
    });

    testWidgets('Edge Case: another day reads as dd/MM/yyyy in pt_BR', (
      tester,
    ) async {
      // 1. Arrange
      final doubles = HomeDoubles()..capabilities.value = watcherOf('g1');
      doubles.observedDay.value = DateTime(2025, 3, 7);
      when(doubles.calendar.observedRelativeDay).thenReturn(RelativeDay.other);

      // 2. Act
      await pumpHeader(tester, doubles);

      // 3. Assert
      expect(find.text('07/03/2025'), findsOneWidget);
    });
  });
}
