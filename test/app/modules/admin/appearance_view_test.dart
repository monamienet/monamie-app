import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/config/organization/organization_theme.dart';
import 'package:monamie_app/app/modules/admin/appearance_backend.dart';
import 'package:monamie_app/app/modules/admin/appearance_controller.dart';
import 'package:monamie_app/app/modules/admin/appearance_view.dart';

@GenerateNiceMocks([MockSpec<AppearanceBackend>()])
import 'appearance_view_test.mocks.dart';

void main() {
  group('AppearanceView - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the themes', (
      tester,
    ) async {
      // 1. Arrange
      final backend = MockAppearanceBackend();
      when(
        backend.pickableThemes(),
      ).thenAnswer((_) async => [defaultOrganizationTheme]);
      final controller = AppearanceController(
        organization: const OrganizationConfig(id: 'rotasul', name: 'Rota Sul'),
        backend: backend,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(home: AppearanceView(controller: controller)),
      );
      await tester.pump();

      // 3. Assert
      verify(backend.pickableThemes()).called(1);
      expect(controller.state.isLoadingThemes, isFalse);
    });
  });
}
