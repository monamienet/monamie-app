import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/sharing_notification.dart';
import 'package:monamie_app/ui/home/view_models/tracking_toggle_view_model.dart';
import 'package:monamie_app/ui/home/widgets/share_card.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

@GenerateNiceMocks([MockSpec<TrackingToggleViewModel>()])
import 'share_card_test.mocks.dart';

/// A [MockTrackingToggleViewModel] whose sharing flag starts at [enabled]
/// and whose [toggleService] is a real [Command1] answering [result] (by
/// default `Ok(null)`), counting the toggles in [calls] and keeping the
/// notification each one got in [notifications]. With [loading] a toggle is
/// already in flight, until [finishLoading].
class ToggleDouble {
  ToggleDouble({
    bool enabled = false,
    bool loading = false,
    this.result = const Ok(null),
  }) : isEnabled = ValueNotifier<bool>(enabled) {
    when(mock.isTrackingEnabled).thenReturn(isEnabled);
    when(mock.toggleService).thenReturn(command);
    if (loading) startLoading();
  }

  final mock = MockTrackingToggleViewModel();
  final ValueNotifier<bool> isEnabled;
  final Result<UserNotice?> result;

  /// The toggles the card asked for (not the one [startLoading] began).
  int calls = 0;

  /// The notification handed to each toggle the card asked for.
  final List<SharingNotification> notifications = [];
  Completer<void>? _inFlight;

  late final command = Command1<UserNotice?, SharingNotification>((
    notification,
  ) async {
    calls++;
    notifications.add(notification);
    await _inFlight?.future;
    return result;
  });

  /// Starts a toggle that runs until [finishLoading], as a start or stop
  /// in flight.
  void startLoading() {
    _inFlight = Completer<void>();
    command.execute(
      const SharingNotification(title: 'in flight', content: 'in flight'),
    );
    calls = 0;
    notifications.clear();
  }

  /// Ends the toggle [startLoading] began.
  void finishLoading() {
    _inFlight?.complete();
    _inFlight = null;
  }
}

Widget buildApp(
  ToggleDouble toggle, {
  Locale locale = const Locale('pt', 'BR'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: appSupportedLocales,
  home: Scaffold(body: ShareCard(controller: toggle.mock)),
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
      final fake = ToggleDouble(result: const Err(Failure.sharingNotAllowed()));
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Você não está em campo em nenhum grupo. Peça a um administrador '
          'para liberar o compartilhamento da sua localização.',
        ),
        findsOneWidget,
      );
      expect(find.text('Compartilhamento não autorizado'), findsOneWidget);
    });

    testWidgets('Happy Path: an Ok holding a UserNotice shows the notice', (
      tester,
    ) async {
      // 1. Arrange
      final fake = ToggleDouble(result: const Ok(UserNotice.waitingForGps()));
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'O monitoramento foi iniciado, mas a sua posição inicial ainda está '
          'sendo obtida pelos satélites.',
        ),
        findsOneWidget,
      );
      expect(find.text('Aguardando sinal de GPS'), findsOneWidget);
    });

    testWidgets('Edge Case: Ok(null) shows no message', (tester) async {
      // 1. Arrange
      final fake = ToggleDouble(result: const Ok(null));
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('ShareCard - notification words', () {
    testWidgets('Happy Path: a toggle hands the pt-BR notification words to '
        'toggleService', (tester) async {
      // 1. Arrange
      final fake = ToggleDouble();
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(fake.notifications, const [
        SharingNotification(
          title: 'Sua localização está sendo compartilhada',
          content:
              'O compartilhamento está ligado. Para preservar sua '
              'privacidade, certifique-se de desativá-lo assim que terminar '
              'suas atividades.',
        ),
      ]);
    });

    testWidgets('Edge Case: in English the notification follows the '
        "device's language", (tester) async {
      // 1. Arrange
      final fake = ToggleDouble();
      await tester.pumpWidget(buildApp(fake, locale: const Locale('en')));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(fake.notifications, [
        SharingNotification(
          title: l10n.sharingNotificationTitle,
          content: l10n.sharingNotificationContent,
        ),
      ]);
      expect(
        fake.notifications.single.title,
        isNot('Sua localização está sendo compartilhada'),
      );
    });
  });

  group('ShareCard - Widget Test Suite', () {
    testWidgets('Happy Path: tapping an idle card toggles the service once', (
      tester,
    ) async {
      // 1. Arrange
      final fake = ToggleDouble();
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(fake.calls, 1);
    });

    testWidgets('Happy Path: while sharing it reads on, with no spinner', (
      tester,
    ) async {
      // 1. Arrange
      final fake = ToggleDouble(enabled: true);

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
      final fake = ToggleDouble(enabled: false);

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
      final fake = ToggleDouble(enabled: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(fake.calls, 1);
    });

    testWidgets('Edge Case: the spinner shows when a toggle starts', (
      tester,
    ) async {
      // 1. Arrange
      final fake = ToggleDouble();
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      fake.startLoading();
      await tester.pump();

      // 3. Assert
      expect(find.byKey(busyKey), findsOneWidget);
    });

    testWidgets('Edge Case: the spinner goes away when the toggle ends', (
      tester,
    ) async {
      // 1. Arrange
      final fake = ToggleDouble(loading: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      fake.finishLoading();
      fake.isEnabled.value = true;
      await tester.pump();

      // 3. Assert
      expect(find.byKey(busyKey), findsNothing);
      expect(find.text('Compartilhando sua localização'), findsOneWidget);
    });

    testWidgets('Edge Case: the card reads on when sharing turns on with no '
        'loading change', (tester) async {
      // 1. Arrange
      final fake = ToggleDouble();
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      fake.isEnabled.value = true;
      await tester.pump();

      // 3. Assert
      expect(find.text('Compartilhando sua localização'), findsOneWidget);
    });

    testWidgets('Sad Path: while starting, a tap does not toggle', (
      tester,
    ) async {
      // 1. Arrange
      final fake = ToggleDouble(enabled: false, loading: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(fake.calls, 0);
      expect(find.byKey(busyKey), findsOneWidget);
    });

    testWidgets('Sad Path: while stopping, a tap does not toggle', (
      tester,
    ) async {
      // 1. Arrange
      final fake = ToggleDouble(enabled: true, loading: true);
      await tester.pumpWidget(buildApp(fake));

      // 2. Act
      await tester.tap(find.byType(ShareCard));
      await tester.pump();

      // 3. Assert
      expect(fake.calls, 0);
      expect(find.byKey(busyKey), findsOneWidget);
    });
  });
}
