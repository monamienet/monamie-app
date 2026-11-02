import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/ui/home/widgets/group_menu_button.dart';

import 'home_doubles.dart';

const _guias = MapGroup(id: 'g1', name: 'Guias');
const _recepcao = MapGroup(id: 'g2', name: 'Recepção');

/// The chip over [doubles], with its card open.
Future<void> pumpOpenMenu(WidgetTester tester, HomeDoubles doubles) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GroupMenuButton(groups: doubles.groups, label: 'Guias'),
      ),
    ),
  );
  await tester.tap(find.byType(GroupMenuButton));
  await tester.pumpAndSettle();
}

void main() {
  group('GroupMenuButton - Widget Test Suite', () {
    testWidgets('Happy Path: counts that arrive while the card is open show '
        'under each group', (tester) async {
      // 1. Arrange
      final doubles = HomeDoubles()
        ..mapGroups.value = const [_guias]
        ..selectedGroup.value = _guias;
      await pumpOpenMenu(tester, doubles);

      // 2. Act
      doubles.groupSizes.value = const {'g1': 3};
      await tester.pump();

      // 3. Assert
      expect(find.text('3 pessoas'), findsOneWidget);
    });

    testWidgets('Edge Case: a group gained while the card is open joins the '
        'list and the count', (tester) async {
      // 1. Arrange
      final doubles = HomeDoubles()
        ..mapGroups.value = const [_guias]
        ..selectedGroup.value = _guias;
      await pumpOpenMenu(tester, doubles);

      // 2. Act
      doubles.mapGroups.value = const [_guias, _recepcao];
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.text('Recepção'), findsOneWidget);
      expect(find.text('2 grupos'), findsOneWidget);
    });
  });
}
