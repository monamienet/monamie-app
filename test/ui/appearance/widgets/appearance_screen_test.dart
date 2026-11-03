import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/ui/appearance/view_models/appearance_view_model.dart';
import 'package:monamie_app/ui/appearance/widgets/appearance_screen.dart';

import '../../../../testing/fakes/repositories/fake_appearance_repository.dart';

void main() {
  group('AppearanceScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the themes', (
      tester,
    ) async {
      // 1. Arrange
      final repository = FakeAppearanceRepository(
        themes: [defaultOrganizationTheme],
      );
      final controller = AppearanceViewModel(
        organization: const OrganizationConfig(id: 'rotasul', name: 'Rota Sul'),
        repository: repository,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(home: AppearanceScreen(controller: controller)),
      );
      await tester.pump();

      // 3. Assert
      expect(repository.callCount('pickableThemes'), 1);
      expect(controller.load.running, isFalse);
      expect(controller.load.completed, isTrue);
    });
  });
}
