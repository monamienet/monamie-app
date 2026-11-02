import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';
import 'package:monamie_app/ui/account/widgets/my_account_screen.dart';

@GenerateNiceMocks([
  MockSpec<AccountDeletionRepository>(),
  MockSpec<OrganizationDirectory>(),
  MockSpec<SignOut>(),
])
import 'my_account_screen_test.mocks.dart';

void main() {
  group('MyAccountScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen reads the ownership', (
      tester,
    ) async {
      // 1. Arrange
      final directory = MockOrganizationDirectory();
      when(
        directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => const []);
      final controller = MyAccountViewModel(
        repository: MockAccountDeletionRepository(),
        organizationId: 'rotasul',
        directory: directory,
        signOut: MockSignOut(),
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          home: MyAccountScreen(
            controller: controller,
            email: 'ana@x.com',
            organizationName: 'Rota Sul',
          ),
        ),
      );
      await tester.pump();

      // 3. Assert
      verify(directory.organizationsOfSignedInUser()).called(1);
      expect(controller.state.isOwner, isFalse);
    });
  });
}
