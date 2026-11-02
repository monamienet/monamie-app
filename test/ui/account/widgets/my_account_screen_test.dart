import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';
import 'package:monamie_app/ui/account/widgets/my_account_screen.dart';

@GenerateNiceMocks([MockSpec<AccountDeletionRepository>()])
import 'my_account_screen_test.mocks.dart';

void main() {
  group('MyAccountScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen reads the ownership', (
      tester,
    ) async {
      // 1. Arrange
      var checks = 0;
      final controller = MyAccountViewModel(
        repository: MockAccountDeletionRepository(),
        organizationId: 'rotasul',
        checkOwner: () async {
          checks++;
          return false;
        },
        onDeleted: (_) async {},
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
      expect(checks, 1);
      expect(controller.state.isOwner, isFalse);
    });
  });
}
