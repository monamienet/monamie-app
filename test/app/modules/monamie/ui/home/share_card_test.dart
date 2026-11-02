import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_toggle_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/share_card.dart';
import 'package:monamie_app/app/utils/result.dart';
import 'package:monamie_app/app/utils/user_notice.dart';

@GenerateNiceMocks([MockSpec<TrackingToggleController>()])
import 'share_card_test.mocks.dart';

/// A [MockTrackingToggleController] whose flags start at [enabled] and
/// [loading]; the test flips them through the returned `RxBool`s.
/// [toggleService] answers [result] (by default `Ok(null)`).
MockTrackingToggleController mockToggle({
  bool enabled = false,
  bool loading = false,
  Result<UserNotice?> result = const Ok(null),
}) {
  final toggle = MockTrackingToggleController();
  final isEnabled = enabled.obs;
  final isLoading = loading.obs;
  when(toggle.isTrackingEnabled).thenReturn(isEnabled);
  when(toggle.isTrackingLoading).thenReturn(isLoading);
  when(toggle.toggleService()).thenAnswer((_) async => result);
  return toggle;
}

Widget buildApp(TrackingToggleController controller) => MaterialApp(
  home: Scaffold(body: ShareCard(controller: controller)),
);

const busyKey = ValueKey('share_card_busy');

void main() {
  // Mockito cannot build a default value of the sealed `Result`.
  provideDummy<Result<UserNotice?>>(const Ok(null));

  group('ShareCard - messages after a toggle', () {
    testWidgets('Sad Path: an Err from toggleService shows its message', (
      tester,
    ) async {
      // 1. Arrange
      final fake = mockToggle(
        result: const Err(
          'Você não está em campo em nenhum grupo.',
          title: 'Compartilhamento não autorizado',
        ),
      );
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Você não está em campo em nenhum grupo.'),
        findsOneWidget,
      );
      expect(find.text('Compartilhamento não autorizado'), findsOneWidget);
    });

    testWidgets('Happy Path: an Ok holding a UserNotice shows the notice', (
      tester,
    ) async {
      // 1. Arrange
      final fake = mockToggle(
        result: const Ok(
          UserNotice(
            'O monitoramento foi iniciado.',
            title: 'Aguardando sinal de GPS',
          ),
        ),
      );
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('O monitoramento foi iniciado.'), findsOneWidget);
      expect(find.text('Aguardando sinal de GPS'), findsOneWidget);
    });

    testWidgets('Edge Case: Ok(null) shows no message', (tester) async {
      // 1. Arrange
      final fake = mockToggle(result: const Ok(null));
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('ShareCard - Widget Test Suite', () {
    testWidgets('Happy Path: tapping an idle card toggles the service once', (
      tester,
    ) async {
      // 1. Arrange
      final fake = mockToggle();
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      verify(fake.toggleService()).called(1);
    });

    testWidgets('Happy Path: while sharing it reads on, with no spinner', (
      tester,
    ) async {
      // 1. Arrange
      final fake = mockToggle(enabled: true);

      // 2. Act
      await tester.pumpWidget(buildApp(fake));

      // 3. Assert
      expect(find.text('Compartilhando sua localização'), findsOneWidget);
      expect(find.byKey(busyKey), findsNothing);
    });

    testWidgets('Happy Path: while off it reads off, with no spinner', (
      tester,
    ) async {
      // 1. Arrange
      final fake = mockToggle(enabled: false);

      // 2. Act
      await tester.pumpWidget(buildApp(fake));

      // 3. Assert
      expect(find.text('Localização desligada'), findsOneWidget);
      expect(find.byKey(busyKey), findsNothing);
    });

    testWidgets('Edge Case: tapping an enabled idle card also toggles', (
      tester,
    ) async {
      // 1. Arrange
      final fake = mockToggle(enabled: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      verify(fake.toggleService()).called(1);
    });

    testWidgets('Edge Case: the spinner shows when the loading flag flips', (
      tester,
    ) async {
      // 1. Arrange
      final fake = mockToggle();
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
      final fake = mockToggle(loading: true);
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
      final fake = mockToggle(enabled: false, loading: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      verifyNever(fake.toggleService());
      expect(find.byKey(busyKey), findsOneWidget);
    });

    testWidgets('Sad Path: while stopping, a tap does not toggle', (
      tester,
    ) async {
      // 1. Arrange
      final fake = mockToggle(enabled: true, loading: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      verifyNever(fake.toggleService());
      expect(find.byKey(busyKey), findsOneWidget);
    });
  });
}
