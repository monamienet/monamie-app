import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:monamie_app/app/modules/account/account_deletion_backend.dart';
import 'package:monamie_app/app/modules/account/my_account_controller.dart';
import 'package:monamie_app/app/modules/account/my_account_view.dart';

@GenerateNiceMocks([MockSpec<AccountDeletionBackend>()])
import 'my_account_view_test.mocks.dart';

void main() {
  group('MyAccountView - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen reads the ownership', (
      tester,
    ) async {
      // 1. Arrange
      var checks = 0;
      final controller = MyAccountController(
        backend: MockAccountDeletionBackend(),
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
          home: MyAccountView(
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
