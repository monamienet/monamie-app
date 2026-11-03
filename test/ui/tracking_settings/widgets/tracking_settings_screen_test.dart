import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'package:monamie_app/ui/tracking_settings/view_models/tracking_settings_edit_view_model.dart';
import 'package:monamie_app/ui/tracking_settings/widgets/tracking_settings_screen.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

import '../../../../testing/fakes/repositories/fake_tracking_settings_repository.dart';

void main() {
  group('TrackingSettingsScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen reads the plan minimum', (
      tester,
    ) async {
      // 1. Arrange
      final repository = FakeTrackingSettingsRepository(minPeriod: 15);
      addTearDown(repository.dispose);
      final controller = TrackingSettingsEditViewModel(
        repository: repository,
        saved: const TrackingSettings(periodMinutes: 15, radiusMeters: 100),
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: TrackingSettingsScreen(controller: controller),
        ),
      );
      await tester.pump();

      // 3. Assert
      expect(repository.callCount('minPeriodMinutes'), 1);
      expect(controller.state.minPeriodMinutes, 15);
    });
  });
}
