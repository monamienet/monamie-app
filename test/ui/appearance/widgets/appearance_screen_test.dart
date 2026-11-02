import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_backend.dart';
import 'package:monamie_app/ui/appearance/view_models/appearance_view_model.dart';
import 'package:monamie_app/ui/appearance/widgets/appearance_screen.dart';

@GenerateNiceMocks([MockSpec<AppearanceBackend>()])
import 'appearance_screen_test.mocks.dart';

void main() {
  group('AppearanceScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the themes', (
      tester,
    ) async {
      // 1. Arrange
      final backend = MockAppearanceBackend();
      when(
        backend.pickableThemes(),
      ).thenAnswer((_) async => [defaultOrganizationTheme]);
      final controller = AppearanceViewModel(
        organization: const OrganizationConfig(id: 'rotasul', name: 'Rota Sul'),
        backend: backend,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(home: AppearanceScreen(controller: controller)),
      );
      await tester.pump();

      // 3. Assert
      verify(backend.pickableThemes()).called(1);
      expect(controller.state.isLoadingThemes, isFalse);
    });
  });
}
