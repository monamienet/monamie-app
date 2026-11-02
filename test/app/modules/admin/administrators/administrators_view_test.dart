import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_backend.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_controller.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_view.dart';

@GenerateNiceMocks([MockSpec<AdministratorsBackend>()])
import 'administrators_view_test.mocks.dart';

void main() {
  group('AdministratorsView - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the administrators', (
      tester,
    ) async {
      // 1. Arrange
      final backend = MockAdministratorsBackend();
      when(backend.list(any)).thenAnswer(
        (_) async => const OrganizationAdministrators(
          administrators: [Administrator(email: 'olga@x.com', owner: true)],
        ),
      );
      final controller = AdministratorsController(
        organizationId: 'rotasul',
        backend: backend,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(home: AdministratorsView(controller: controller)),
      );
      await tester.pump();

      // 3. Assert
      verify(backend.list('rotasul')).called(1);
      expect(find.text('olga@x.com'), findsOneWidget);
    });
  });
}
