import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_sheet.dart';

import 'home_doubles.dart';

const _guias = MapGroup(id: 'g1', name: 'Guias');
const _bia = GroupMember(name: 'Bia', email: 'bia@example.com');

/// The sheet over [doubles], already registered.
Future<void> pumpSheet(WidgetTester tester, HomeDoubles doubles) async {
  doubles.register();
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: HomeSheet()),
      ),
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  group('HomeSheet - Widget Test Suite', () {
    testWidgets('Happy Path: being allowed to watch shows the observed group', (
      tester,
    ) async {
      // 1. Arrange
      final doubles = HomeDoubles()..selectedGroup.value = _guias;
      await pumpSheet(tester, doubles);

      // 2. Act
      doubles.capabilities.value = watcherOf('g1');
      await tester.pump();

      // 3. Assert
      expect(find.text('Guias'), findsOneWidget);
    });

    testWidgets('Edge Case: the first person in the group replaces the empty '
        'group message with the people', (tester) async {
      // 1. Arrange
      final doubles = HomeDoubles()
        ..capabilities.value = watcherOf('g1')
        ..selectedGroup.value = _guias;
      await pumpSheet(tester, doubles);

      // 2. Act
      doubles.observedMembers.value = const [_bia];
      await tester.pump();

      // 3. Assert
      expect(find.text('1 pessoa'), findsOneWidget);
      expect(find.text('Bia'), findsOneWidget);
      expect(find.textContaining('Ninguém neste grupo'), findsNothing);
    });
  });
}
