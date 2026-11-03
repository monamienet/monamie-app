import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';
import 'package:monamie_app/ui/account/widgets/my_account_screen.dart';

import '../../../../testing/fakes/repositories/fake_account_deletion_repository.dart';
import '../../../../testing/fakes/repositories/fake_organization_directory.dart';

@GenerateNiceMocks([MockSpec<SignOut>()])
import 'my_account_screen_test.mocks.dart';

void main() {
  group('MyAccountScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen reads the ownership', (
      tester,
    ) async {
      // 1. Arrange
      final directory = FakeOrganizationDirectory();
      final controller = MyAccountViewModel(
        repository: FakeAccountDeletionRepository(),
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
      expect(directory.callCount('organizationsOfSignedInUser'), 1);
      expect(controller.state.isOwner, isFalse);
    });
  });
}
