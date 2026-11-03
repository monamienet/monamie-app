import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';

import '../../../../testing/fakes/repositories/fake_groups_repository.dart';

const norte = Group(id: '01', name: 'Equipe Norte', people: []);

void main() {
  group('GroupsScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the groups', (
      tester,
    ) async {
      // 1. Arrange
      final repository = FakeGroupsRepository(
        groups: {
          'rotasul': [norte],
        },
      );
      final controller = GroupsViewModel(
        organizationId: 'rotasul',
        repository: repository,
        isAdmin: true,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(home: GroupsScreen(controller: controller)),
      );
      await tester.pump();

      // 3. Assert
      expect(repository.argumentsOf('list'), [
        ['rotasul'],
      ]);
      expect(find.text('Equipe Norte'), findsOneWidget);
    });
  });
}
