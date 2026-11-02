import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_edit_controller.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_view.dart';

@GenerateNiceMocks([MockSpec<TrackingSettingsRepository>()])
import 'tracking_settings_view_test.mocks.dart';

void main() {
  group('TrackingSettingsView - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen reads the plan minimum', (
      tester,
    ) async {
      // 1. Arrange
      final repository = MockTrackingSettingsRepository();
      when(repository.minPeriodMinutes()).thenAnswer((_) async => 15);
      final controller = TrackingSettingsEditController(
        repository: repository,
        saved: const TrackingSettings(periodMinutes: 15, radiusMeters: 100),
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(home: TrackingSettingsView(controller: controller)),
      );
      await tester.pump();

      // 3. Assert
      verify(repository.minPeriodMinutes()).called(1);
      expect(controller.state.minPeriodMinutes, 15);
    });
  });
}
