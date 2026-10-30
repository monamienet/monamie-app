import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_toggle_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/share_card.dart';

class FakeTrackingToggleController implements TrackingToggleController {
  @override
  final RxBool isTrackingEnabled;

  @override
  final RxBool isTrackingLoading;

  int toggleCalls = 0;

  FakeTrackingToggleController({bool enabled = false, bool loading = false})
    : isTrackingEnabled = enabled.obs,
      isTrackingLoading = loading.obs;

  @override
  Future<void> toggleService() async {
    toggleCalls++;
  }
}

Widget buildApp(TrackingToggleController controller) => MaterialApp(
  home: Scaffold(body: ShareCard(controller: controller)),
);

const busyKey = ValueKey('share_card_busy');

void main() {
  group('ShareCard - Widget Test Suite', () {
    testWidgets('Happy Path: tapping an idle card toggles the service once', (
      tester,
    ) async {
      // 1. Arrange
      final fake = FakeTrackingToggleController();
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(fake.toggleCalls, 1);
    });
    testWidgets('Edge Case: the spinner shows when the loading flag flips', (
      tester,
    ) async {
      // 1. Arrange
      final fake = FakeTrackingToggleController();
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      fake.isTrackingLoading.value = true;
      await tester.pump();

      // 3. Assert
      expect(find.byKey(busyKey), findsOneWidget);
    });

    testWidgets('Edge Case: the spinner goes away when loading ends', (
      tester,
    ) async {
      // 1. Arrange
      final fake = FakeTrackingToggleController(loading: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      fake.isTrackingLoading.value = false;
      fake.isTrackingEnabled.value = true;
      await tester.pump();

      // 3. Assert
      expect(find.byKey(busyKey), findsNothing);
      expect(find.text('Compartilhando sua localização'), findsOneWidget);
    });

    testWidgets('Sad Path: while starting, a tap does not toggle', (
      tester,
    ) async {
      // 1. Arrange
      final fake = FakeTrackingToggleController(enabled: false, loading: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(fake.toggleCalls, 0);
      expect(find.byKey(busyKey), findsOneWidget);
    });
  });
}
