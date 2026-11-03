import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';
import 'package:monamie_app/ui/core/themes/app_theme.dart';

/// A phone's screen for layout tests: 390 x 844 logical pixels (the size of
/// an iPhone 14, in the range of the Android phones the app runs on).
const phonePhysicalSize = Size(1170, 2532);
const phoneDevicePixelRatio = 3.0;

/// The text scale a layout test uses: 30% above the default, a common
/// "larger text" setting.
const largerTextScale = 1.3;

bool _fontsLoaded = false;

/// Loads the app's own font, Manrope (`assets/fonts/`, declared in
/// `pubspec.yaml`), so text takes the widths it takes on a device.
///
/// Without it `flutter test` draws every text with the Ahem font, whose
/// glyphs are all squares one em wide: about twice as wide as Manrope's, so
/// a layout would overflow in the test where it does not on a phone. The
/// font files are bundled as assets, so a test can load them (a font fetched
/// at runtime could not be).
///
/// Manrope is also registered as `Roboto`, Material's default family on
/// Android: a text whose style names no family (a button label set with
/// `styleFrom(textStyle: ...)`, which replaces the theme's style whole) falls
/// back to it on a phone, and Roboto is not bundled in the tests. Manrope is
/// a little wider than Roboto, so a layout that fits here fits there.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final family in const ['Manrope', 'Roboto']) {
    final loader = FontLoader(family);
    for (final weight in const [400, 500, 700, 800]) {
      loader.addFont(rootBundle.load('assets/fonts/Manrope-$weight.ttf'));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// Gives [tester] a phone's screen for the rest of the test.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = phonePhysicalSize;
  tester.view.devicePixelRatio = phoneDevicePixelRatio;
  addTearDown(tester.view.reset);
}

/// [home] as the app shows it: the app's theme and delegates, in [locale],
/// with [textScale] as the device's text size, on a phone's screen.
Future<void> pumpOnPhone(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale('es'),
  double textScale = largerTextScale,
}) async {
  await loadAppFonts();
  usePhoneScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pump();
}

/// Fails the test when a layout error was reported while drawing: a
/// `RenderFlex` that overflowed (the yellow and black stripes) throws a
/// `FlutterError` that [WidgetTester.takeException] returns. The failure
/// names the widgets involved.
void expectNoLayoutError(WidgetTester tester) {
  final exception = tester.takeException();
  final details = exception is FlutterError
      ? exception.toStringDeep()
      : '$exception';
  expect(exception, isNull, reason: 'a layout error was reported:\n$details');
}

/// How many pixels [error] says a `RenderFlex` overflowed by, `null` when it
/// is another error.
double? overflowOf(Object? error) {
  final match = RegExp(r'overflowed by ([0-9.]+) pixels').firstMatch('$error');
  return match == null ? null : double.parse(match[1]!);
}

/// Expects the screen [open] draws in Spanish not to overflow by more than
/// the same screen, drawn the same way, does in Portuguese.
///
/// For a screen that overflows in the test for a reason that is not its
/// layout: a text whose style names no font family (a button label set with
/// `styleFrom(textStyle: ...)`, or flutter_map's attribution) is drawn with
/// Ahem, which [loadAppFonts] cannot replace, and Ahem's square glyphs are
/// about twice as wide as the Roboto such a text has on a phone. Portuguese
/// is the baseline: an overflow that is there with it too is not Spanish's.
///
/// [open] builds the screen in the locale it gets, on a phone's screen and
/// the larger text, and leaves it open.
Future<void> expectSpanishNoWorseThanPortuguese(
  WidgetTester tester,
  Future<void> Function(Locale locale) open,
) async {
  await open(const Locale('pt', 'BR'));
  final baseline = tester.takeException();
  // Takes the first screen away before the second one is built.
  await tester.pumpWidget(const SizedBox());
  await open(const Locale('es', 'ES'));
  final spanish = tester.takeException();

  final allowed = overflowOf(baseline) ?? 0;
  final found = overflowOf(spanish) ?? 0;
  expect(
    spanish == null || (overflowOf(spanish) != null && found <= allowed),
    isTrue,
    reason:
        'Spanish reported "$spanish", Portuguese '
        '${baseline == null ? 'nothing' : '"$baseline"'}',
  );
}
