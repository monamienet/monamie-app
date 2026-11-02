import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<GroupsRepository>()])
import 'groups_screen_test.mocks.dart';

const norte = Group(id: '01', name: 'Equipe Norte', people: []);

void main() {
  provideDummy<Result<List<Group>>>(const Ok([]));

  group('GroupsScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the groups', (
      tester,
    ) async {
      // 1. Arrange
      final repository = MockGroupsRepository();
      when(repository.list(any)).thenAnswer((_) async => const Ok([norte]));
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
      verify(repository.list('rotasul')).called(1);
      expect(find.text('Equipe Norte'), findsOneWidget);
    });
  });
}
