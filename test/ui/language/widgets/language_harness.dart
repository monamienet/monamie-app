import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';

import '../../../../testing/fakes/repositories/fake_language_repository.dart';

/// A small app whose `locale` follows a [FakeLanguageRepository] as
/// `MonAmieApp` does (the choice first, then the device's languages), with a
/// real [LanguageViewModel] over it, so a test sees the texts of the whole
/// screen change when a language is chosen.
class LanguageHarness {
  /// [stored] is the language the device keeps (none when omitted) and
  /// [deviceLocales] the device's languages (Brazilian Portuguese when
  /// omitted).
  LanguageHarness({AppLanguage? stored, List<Locale>? deviceLocales})
    : repository = FakeLanguageRepository(stored: stored),
      deviceLocales = List.of(deviceLocales ?? const [Locale('pt', 'BR')]);

  final FakeLanguageRepository repository;

  /// The device's languages the view model reads; a test may change them.
  final List<Locale> deviceLocales;

  /// The view model the widgets under test receive.
  late final LanguageViewModel controller = LanguageViewModel(
    repository: repository,
    deviceLocales: () => deviceLocales,
  );

  /// Opens the app showing [home], with a restored language.
  Future<void> pump(WidgetTester tester, {required Widget home}) async {
    tester.platformDispatcher.localesTestValue = deviceLocales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(controller.dispose);
    await repository.restore();
    await tester.pumpWidget(
      ValueListenableBuilder<AppLanguage?>(
        valueListenable: repository.language,
        builder: (context, language, _) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          locale: language?.locale,
          localeListResolutionCallback: resolveAppLocale,
          home: home,
        ),
      ),
    );
    await tester.pump();
  }
}

/// The row of the language written [name] in the picker.
Finder languageRow(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(InkWell));
