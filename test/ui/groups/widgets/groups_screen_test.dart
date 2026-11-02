import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/data/repositories/groups/groups_backend.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';

@GenerateNiceMocks([MockSpec<GroupsBackend>()])
import 'groups_screen_test.mocks.dart';

const norte = Group(id: '01', name: 'Equipe Norte', people: []);

void main() {
  group('GroupsScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the groups', (
      tester,
    ) async {
      // 1. Arrange
      final backend = MockGroupsBackend();
      when(backend.list(any)).thenAnswer((_) async => [norte]);
      final controller = GroupsViewModel(
        organizationId: 'rotasul',
        backend: backend,
        isAdmin: true,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(home: GroupsScreen(controller: controller)),
      );
      await tester.pump();

      // 3. Assert
      verify(backend.list('rotasul')).called(1);
      expect(find.text('Equipe Norte'), findsOneWidget);
    });
  });
}
