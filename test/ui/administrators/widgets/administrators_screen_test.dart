import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/data/repositories/administrators/administrators_backend.dart';
import 'package:monamie_app/ui/administrators/view_models/administrators_view_model.dart';
import 'package:monamie_app/ui/administrators/widgets/administrators_screen.dart';

@GenerateNiceMocks([MockSpec<AdministratorsBackend>()])
import 'administrators_screen_test.mocks.dart';

void main() {
  group('AdministratorsScreen - Unit Test Suite', () {
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
      final controller = AdministratorsViewModel(
        organizationId: 'rotasul',
        backend: backend,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(home: AdministratorsScreen(controller: controller)),
      );
      await tester.pump();

      // 3. Assert
      verify(backend.list('rotasul')).called(1);
      expect(find.text('olga@x.com'), findsOneWidget);
    });
  });
}
