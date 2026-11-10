import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';
import 'package:monamie_app/ui/home/view_models/resume_on_restart_view_model.dart';
import 'package:monamie_app/ui/home/widgets/resume_on_restart_row.dart';
import 'package:monamie_app/utils/result.dart';

import '../../../../testing/fakes/repositories/fake_permissions_repository.dart';
import '../../../../testing/fakes/repositories/fake_sharing_resume_repository.dart';

const _portuguese = Locale('pt', 'BR');

/// The app's texts in Brazilian Portuguese.
final _l10n = lookupAppLocalizations(_portuguese);

/// A real [ResumeOnRestartViewModel] over the in-memory [repository] and
/// [permissions] (location allowed all the time and the battery free unless
/// a test changes them), opened in a small app as the menu shows it.
class _Harness {
  _Harness({this._available = true, bool stored = false})
    : repository = FakeSharingResumeRepository(storedOption: stored) {
    permissions.hasAlwaysLocationPermission.value = true;
  }

  final FakeSharingResumeRepository repository;
  final permissions = FakePermissionsRepository();
  final bool _available;

  late final viewModel = ResumeOnRestartViewModel(
    repository: repository,
    permissions: permissions,
    available: _available,
  );

  Future<void> pump(WidgetTester tester) async {
    addTearDown(viewModel.dispose);
    addTearDown(permissions.dispose);
    await viewModel.load.execute();
    await tester.pumpWidget(
      MaterialApp(
        locale: _portuguese,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: Scaffold(body: ResumeOnRestartRow(controller: viewModel)),
      ),
    );
  }
}

/// The row's switch.
Switch _switch(WidgetTester tester) => tester.widget(find.byType(Switch));

void main() {
  group('ResumeOnRestartRow - Widget Test Suite', () {
    testWidgets('Happy Path: shows the title, the description and a switch '
        'off by default', (tester) async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.pump(tester);

      // 3. Assert
      expect(find.text(_l10n.resumeOnRestartTitle), findsOneWidget);
      expect(find.text(_l10n.resumeOnRestartSubtitle), findsOneWidget);
      expect(_switch(tester).value, isFalse);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('Happy Path: the switch shows the stored option', (
      tester,
    ) async {
      // 1. Arrange
      final harness = _Harness(stored: true);

      // 2. Act
      await harness.pump(tester);

      // 3. Assert
      expect(_switch(tester).value, isTrue);
    });

    testWidgets('Edge Case: shows nothing where sharing cannot resume (web, '
        'iOS)', (tester) async {
      // 1. Arrange
      final harness = _Harness(available: false, stored: true);

      // 2. Act
      await harness.pump(tester);

      // 3. Assert
      expect(find.byType(Switch), findsNothing);
      expect(find.text(_l10n.resumeOnRestartTitle), findsNothing);
    });

    testWidgets('Happy Path: tapping the switch stores the option and turns '
        'it on', (tester) async {
      // 1. Arrange
      final harness = _Harness();
      await harness.pump(tester);

      // 2. Act
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(harness.repository.argumentsOf('setResumeOnRestart'), [
        [true],
      ]);
      expect(harness.repository.storedOption, isTrue);
      expect(_switch(tester).value, isTrue);
    });

    testWidgets('Happy Path: tapping it again turns it off', (tester) async {
      // 1. Arrange
      final harness = _Harness(stored: true);
      await harness.pump(tester);

      // 2. Act
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(harness.repository.storedOption, isFalse);
      expect(_switch(tester).value, isFalse);
    });

    testWidgets('Edge Case: the switch is disabled while the option is '
        'stored', (tester) async {
      // 1. Arrange
      final harness = _Harness();
      await harness.pump(tester);
      final held = harness.repository.hold('setResumeOnRestart');

      // 2. Act
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // 3. Assert
      expect(_switch(tester).onChanged, isNull);
      held.complete();
      await tester.pumpAndSettle();
      expect(_switch(tester).onChanged, isNotNull);
    });

    testWidgets('Sad Path: a failing store shows the error and leaves the '
        'switch off', (tester) async {
      // 1. Arrange
      final harness = _Harness();
      harness.repository.fail(
        'setResumeOnRestart',
        const Failure.resumeOptionNotSaved(),
      );
      await harness.pump(tester);

      // 2. Act
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(_l10n.failureResumeOptionNotSaved), findsOneWidget);
      expect(_switch(tester).value, isFalse);
    });

    testWidgets('Happy Path: turned on without location all the time, it '
        'stays on and warns about the location', (tester) async {
      // 1. Arrange
      final harness = _Harness();
      harness.permissions.hasAlwaysLocationPermission.value = false;
      await harness.pump(tester);

      // 2. Act
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(_switch(tester).value, isTrue);
      expect(
        find.text(_l10n.resumeOnRestartNeedsAlwaysLocation),
        findsOneWidget,
      );
    });

    testWidgets('Happy Path: with the battery restricted it warns about the '
        'battery', (tester) async {
      // 1. Arrange
      final harness = _Harness(stored: true);
      harness.permissions.isBackgroundRestricted.value = true;

      // 2. Act
      await harness.pump(tester);

      // 3. Assert
      expect(find.text(_l10n.resumeOnRestartBatteryRestricted), findsOneWidget);
      expect(find.text(_l10n.resumeOnRestartNeedsAlwaysLocation), findsNothing);
    });

    testWidgets('Edge Case: no warning while the option is off', (
      tester,
    ) async {
      // 1. Arrange
      final harness = _Harness();
      harness.permissions.hasAlwaysLocationPermission.value = false;
      harness.permissions.isBackgroundRestricted.value = true;

      // 2. Act
      await harness.pump(tester);

      // 3. Assert
      expect(find.text(_l10n.resumeOnRestartNeedsAlwaysLocation), findsNothing);
      expect(find.text(_l10n.resumeOnRestartBatteryRestricted), findsNothing);
    });

    testWidgets('Happy Path: tapping the location warning asks for location '
        'all the time, and granting it removes the warning', (tester) async {
      // 1. Arrange
      final harness = _Harness(stored: true);
      harness.permissions.hasAlwaysLocationPermission.value = false;
      await harness.pump(tester);

      // 2. Act
      await tester.tap(find.text(_l10n.resumeOnRestartNeedsAlwaysLocation));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(harness.permissions.callCount('requestAlwaysPermission'), 1);
      expect(harness.permissions.callCount('openBackgroundUsageSettings'), 0);
      expect(find.text(_l10n.resumeOnRestartNeedsAlwaysLocation), findsNothing);
    });

    testWidgets("Happy Path: tapping the battery warning opens the app's "
        'battery settings', (tester) async {
      // 1. Arrange
      final harness = _Harness(stored: true);
      harness.permissions.isBackgroundRestricted.value = true;
      await harness.pump(tester);

      // 2. Act
      await tester.tap(find.text(_l10n.resumeOnRestartBatteryRestricted));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(harness.permissions.callCount('openBackgroundUsageSettings'), 1);
      expect(harness.permissions.callCount('requestAlwaysPermission'), 0);
    });

    testWidgets('Edge Case: the warning shows a spinner and ignores taps '
        'while it is being resolved', (tester) async {
      // 1. Arrange
      final harness = _Harness(stored: true);
      harness.permissions.hasAlwaysLocationPermission.value = false;
      await harness.pump(tester);
      final held = harness.permissions.hold('requestAlwaysPermission');

      // 2. Act
      await tester.tap(find.text(_l10n.resumeOnRestartNeedsAlwaysLocation));
      await tester.pump();
      await tester.tap(find.text(_l10n.resumeOnRestartNeedsAlwaysLocation));
      await tester.pump();

      // 3. Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(harness.permissions.callCount('requestAlwaysPermission'), 1);
      held.complete();
      await tester.pumpAndSettle();
    });
  });
}
