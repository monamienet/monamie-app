import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/people_list.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/person_row_tile.dart';

import 'home_doubles.dart';

const _bia = GroupMember(name: 'Bia', email: 'bia@example.com');
const _caio = GroupMember(name: 'Caio', email: 'caio@example.com');

/// The list over [doubles], already registered.
Future<void> pumpList(WidgetTester tester, HomeDoubles doubles) async {
  doubles.register();
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: PeopleList())),
    ),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  group('PeopleList - Widget Test Suite', () {
    testWidgets('Happy Path: new people on the map show up in the list', (
      tester,
    ) async {
      // 1. Arrange
      final doubles = HomeDoubles()..observedMembers.value = const [_bia];
      await pumpList(tester, doubles);

      // 2. Act
      doubles.observedMembers.value = const [_bia, _caio];
      await tester.pump();

      // 3. Assert
      expect(find.text('Caio'), findsOneWidget);
    });

    testWidgets('Edge Case: pressing a marker marks that person\'s row', (
      tester,
    ) async {
      // 1. Arrange
      final doubles = HomeDoubles()..observedMembers.value = const [_bia];
      await pumpList(tester, doubles);

      // 2. Act
      doubles.selectedMemberEmail.value = _bia.email;
      await tester.pump();

      // 3. Assert
      expect(
        tester.widget<PersonRowTile>(find.byType(PersonRowTile)).selected,
        isTrue,
      );
    });

    testWidgets('Edge Case: on a past day the history read later fills the '
        'list', (tester) async {
      // 1. Arrange
      final doubles = HomeDoubles()..observedMembers.value = const [_bia];
      when(doubles.calendar.isObservingToday).thenReturn(false);
      await pumpList(tester, doubles);

      // 2. Act
      doubles.historyMembers.value = const [_bia, _caio];
      await tester.pump();

      // 3. Assert
      expect(find.text('Caio'), findsOneWidget);
    });
  });
}
