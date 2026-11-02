import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_repository.dart';
import 'package:monamie_app/ui/appearance/view_models/appearance_view_model.dart';
import 'package:monamie_app/ui/appearance/widgets/appearance_screen.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<AppearanceRepository>()])
import 'appearance_screen_test.mocks.dart';

void main() {
  provideDummy<Result<List<OrganizationTheme>>>(const Ok([]));

  group('AppearanceScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the themes', (
      tester,
    ) async {
      // 1. Arrange
      final repository = MockAppearanceRepository();
      when(
        repository.pickableThemes(),
      ).thenAnswer((_) async => const Ok([defaultOrganizationTheme]));
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
      verify(repository.pickableThemes()).called(1);
      expect(controller.state.isLoadingThemes, isFalse);
    });
  });
}
