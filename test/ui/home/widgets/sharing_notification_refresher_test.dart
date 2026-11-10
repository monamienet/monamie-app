import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/sharing_notification.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';
import 'package:monamie_app/ui/home/view_models/resume_on_restart_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/widgets/sharing_notification_refresher.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<TrackingViewModel>()])
import 'sharing_notification_refresher_test.mocks.dart';

import '../../../../testing/fakes/repositories/fake_permissions_repository.dart';
import '../../../../testing/fakes/repositories/fake_sharing_resume_repository.dart';

const _portuguese = Locale('pt', 'BR');
const _english = Locale('en');

/// A [MockTrackingViewModel] whose `refreshNotification` is a real command
/// that records the notifications it runs with in [refreshed].
({MockTrackingViewModel tracking, List<SharingNotification> refreshed})
_tracking() {
  final tracking = MockTrackingViewModel();
  final refreshed = <SharingNotification>[];
  when(tracking.refreshNotification).thenReturn(
    Command1<void, SharingNotification>((notification) async {
      refreshed.add(notification);
      return const Ok(null);
    }),
  );
  return (tracking: tracking, refreshed: refreshed);
}

/// The sharing notification's texts in [locale], as the app's own.
SharingNotification _texts(Locale locale) {
  final l10n = lookupAppLocalizations(locale);
  return SharingNotification(
    title: l10n.sharingNotificationTitle,
    content: l10n.sharingNotificationContent,
  );
}

/// The texts shown without the screen in [locale], as the app's own.
SharingResumeTexts _resumeTexts(Locale locale) {
  final l10n = lookupAppLocalizations(locale);
  return SharingResumeTexts(
    notificationTitle: l10n.sharingNotificationTitle,
    notificationContent: l10n.sharingNotificationContent,
    waitingForGps: l10n.resumeWaitingForGps,
    failureChannel: l10n.resumeFailureChannel,
    failureTitle: l10n.resumeFailureTitle,
    failures: {
      ResumeFailure.backgroundLocation: l10n.resumeFailureBackgroundLocation,
      ResumeFailure.batteryRestricted: l10n.resumeFailureBatteryRestricted,
      ResumeFailure.signedOut: l10n.resumeFailureSignedOut,
      ResumeFailure.noGroup: l10n.resumeFailureNoGroup,
    },
  );
}

/// A real [ResumeOnRestartViewModel] (on a device that resumes sharing)
/// over an in-memory repository, which keeps the texts it stores.
({ResumeOnRestartViewModel viewModel, FakeSharingResumeRepository repository})
_resumeOnRestart(WidgetTester tester) {
  final repository = FakeSharingResumeRepository();
  final permissions = FakePermissionsRepository();
  final viewModel = ResumeOnRestartViewModel(
    repository: repository,
    permissions: permissions,
    available: true,
  );
  addTearDown(viewModel.dispose);
  addTearDown(permissions.dispose);
  return (viewModel: viewModel, repository: repository);
}

/// Opens the refresher under an app whose language is [locale]'s value;
/// [rebuilds] makes the app rebuild with the same language.
Future<void> _pump(
  WidgetTester tester, {
  required ValueNotifier<Locale> locale,
  required MockTrackingViewModel tracking,
  ResumeOnRestartViewModel? resumeOnRestart,
  ValueNotifier<int>? rebuilds,
}) {
  final resume = resumeOnRestart ?? _resumeOnRestart(tester).viewModel;
  return tester.pumpWidget(
    ListenableBuilder(
      listenable: Listenable.merge([locale, ?rebuilds]),
      builder: (context, _) => MaterialApp(
        locale: locale.value,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: SharingNotificationRefresher(
          tracking: tracking,
          resumeOnRestart: resume,
        ),
      ),
    ),
  );
}

void main() {
  group('SharingNotificationRefresher - Widget Test Suite', () {
    testWidgets('Happy Path: the first build does not refresh the '
        'notification', (tester) async {
      // 1. Arrange
      final (:tracking, :refreshed) = _tracking();
      final locale = ValueNotifier(_portuguese);
      addTearDown(locale.dispose);

      // 2. Act
      await _pump(tester, locale: locale, tracking: tracking);
      await tester.pump();

      // 3. Assert
      expect(refreshed, isEmpty);
      expect(
        find.descendant(
          of: find.byType(SharingNotificationRefresher),
          matching: find.byType(SizedBox),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Happy Path: changing the language refreshes the notification '
        'once, in the new language', (tester) async {
      // 1. Arrange
      final (:tracking, :refreshed) = _tracking();
      final locale = ValueNotifier(_portuguese);
      addTearDown(locale.dispose);
      await _pump(tester, locale: locale, tracking: tracking);

      // 2. Act
      locale.value = _english;
      await tester.pump();
      await tester.pump();

      // 3. Assert
      expect(refreshed, [_texts(_english)]);
      expect(refreshed.single.title, isNot(_texts(_portuguese).title));
    });

    testWidgets('Edge Case: changing back refreshes again, in the language '
        'it went back to', (tester) async {
      // 1. Arrange
      final (:tracking, :refreshed) = _tracking();
      final locale = ValueNotifier(_portuguese);
      addTearDown(locale.dispose);
      await _pump(tester, locale: locale, tracking: tracking);
      locale.value = _english;
      await tester.pump();
      await tester.pump();

      // 2. Act
      locale.value = _portuguese;
      await tester.pump();
      await tester.pump();

      // 3. Assert
      expect(refreshed, [_texts(_english), _texts(_portuguese)]);
    });

    testWidgets('Edge Case: a rebuild in the same language does not refresh '
        'the notification', (tester) async {
      // 1. Arrange
      final (:tracking, :refreshed) = _tracking();
      final locale = ValueNotifier(_english);
      final rebuilds = ValueNotifier(0);
      addTearDown(locale.dispose);
      addTearDown(rebuilds.dispose);
      await _pump(
        tester,
        locale: locale,
        tracking: tracking,
        rebuilds: rebuilds,
      );

      // 2. Act
      rebuilds.value++;
      await tester.pump();
      await tester.pump();

      // 3. Assert
      expect(refreshed, isEmpty);
    });
  });

  group('SharingNotificationRefresher - texts shown without the screen - '
      'Widget Test Suite', () {
    testWidgets('Happy Path: the first frame stores the texts in the '
        "app's language", (tester) async {
      // 1. Arrange
      final (:tracking, refreshed: _) = _tracking();
      final (:viewModel, :repository) = _resumeOnRestart(tester);
      final locale = ValueNotifier(_portuguese);
      addTearDown(locale.dispose);

      // 2. Act
      await _pump(
        tester,
        locale: locale,
        tracking: tracking,
        resumeOnRestart: viewModel,
      );
      await tester.pump();

      // 3. Assert
      expect(repository.argumentsOf('saveTexts'), [
        [_resumeTexts(_portuguese)],
      ]);
      expect(
        repository.texts!.failures,
        hasLength(ResumeFailure.values.length),
      );
    });

    testWidgets('Happy Path: changing the language stores the texts again, '
        'in the new language', (tester) async {
      // 1. Arrange
      final (:tracking, refreshed: _) = _tracking();
      final (:viewModel, :repository) = _resumeOnRestart(tester);
      final locale = ValueNotifier(_portuguese);
      addTearDown(locale.dispose);
      await _pump(
        tester,
        locale: locale,
        tracking: tracking,
        resumeOnRestart: viewModel,
      );
      await tester.pump();

      // 2. Act
      locale.value = _english;
      await tester.pump();
      await tester.pump();

      // 3. Assert
      expect(repository.texts, _resumeTexts(_english));
      expect(repository.callCount('saveTexts'), 2);
    });

    testWidgets('Edge Case: a rebuild in the same language does not store '
        'the texts again', (tester) async {
      // 1. Arrange
      final (:tracking, refreshed: _) = _tracking();
      final (:viewModel, :repository) = _resumeOnRestart(tester);
      final locale = ValueNotifier(_english);
      final rebuilds = ValueNotifier(0);
      addTearDown(locale.dispose);
      addTearDown(rebuilds.dispose);
      await _pump(
        tester,
        locale: locale,
        tracking: tracking,
        resumeOnRestart: viewModel,
        rebuilds: rebuilds,
      );
      await tester.pump();

      // 2. Act
      rebuilds.value++;
      await tester.pump();
      await tester.pump();

      // 3. Assert
      expect(repository.callCount('saveTexts'), 1);
    });
  });
}
