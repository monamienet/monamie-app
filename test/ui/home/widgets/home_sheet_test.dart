import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/ui/home/widgets/home_sheet.dart';

import 'home_doubles.dart';

const _guias = MapGroup(id: 'g1', name: 'Guias');
const _bia = GroupMember(name: 'Bia', email: 'bia@example.com');

/// The sheet over [doubles].
Future<void> pumpSheet(WidgetTester tester, HomeDoubles doubles) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: HomeSheet(
            groups: doubles.groups,
            tracking: doubles.tracking,
            calendar: doubles.calendar,
            calls: doubles.calls,
            user: doubles.user,
          ),
        ),
      ),
    ),
  );
}

void main() {
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
