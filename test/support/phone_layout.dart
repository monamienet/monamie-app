import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// An error the framework reported while a test ran, read when it was
/// reported: the widgets it names are gone by the end of the test, and
/// describing them then fails.
class CollectedFlutterError {
  CollectedFlutterError(this.details)
    : text = details.toString(),
      isArtifact = isFontArtifact(details);

  final FlutterErrorDetails details;

  /// The error as the framework prints it, with the widgets involved.
  final String text;

  /// Whether it is a test-only overflow, see [isFontArtifact].
  final bool isArtifact;

  /// How many pixels it says a `RenderFlex` overflowed by, `null` when it is
  /// another error.
  double? get overflow => overflowOf(details.exception);

  @override
  String toString() => text;
}

/// Runs [body] and returns the errors the framework reported meanwhile
/// instead of handing them to the test binding, which keeps only the first
/// (or says "Multiple exceptions" without their text).
Future<List<CollectedFlutterError>> collectFlutterErrors(
  Future<void> Function() body,
) async {
  final previous = FlutterError.onError;
  final errors = <CollectedFlutterError>[];
  FlutterError.onError = (details) =>
      errors.add(CollectedFlutterError(details));
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

/// Whether [details] is the overflow of a `RenderFlex` that holds a text
/// whose style names no font family.
///
/// Such a text is drawn with Ahem in the test, whose glyphs are all squares
/// one em wide: about twice as wide as the Roboto it has on a phone, so it
/// overflows here where it does not on a device (issue #125). A button label
/// set with `styleFrom(textStyle: ...)` replaces the theme's style whole and
/// loses its family, and so does flutter_map's attribution, which
/// [loadAppFonts] cannot fix. The app's other texts name Manrope, which the
/// test loads, so an overflow of a row of those is the layout's.
bool isFontArtifact(FlutterErrorDetails details) {
  if (overflowOf(details.exception) == null) return false;
  for (final node
      in details.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
    final value = node.value;
    if (value is RenderObject) return _holdsFamilylessText(value);
  }
  return false;
}

bool _holdsFamilylessText(RenderObject root) {
  var found = false;
  void visit(RenderObject object) {
    if (object is RenderParagraph && _isFamilyless(object)) found = true;
    object.visitChildren(visit);
  }

  visit(root);
  return found;
}

/// Whether [paragraph] draws a text whose style names no font family. A
/// paragraph that has no text yet (an empty `Text`) draws nothing.
bool _isFamilyless(RenderParagraph paragraph) {
  try {
    return paragraph.text.style?.fontFamily == null;
  } on TypeError {
    return false;
  }
}

/// Expects the screen [open] draws to report no layout error but the
/// overflows [isFontArtifact] names, which only exist in the test, and the
/// ones [ignoring] names.
///
/// [open] builds the screen (on a phone's screen and the larger text, see
/// [pumpOnPhone] and `TestApp.pump`) and leaves it open. [ignoring] lists
/// pieces of an error's text (a file and line, as the error prints them,
/// `create_organization_screen.dart:141`) for an overflow known and filed
/// elsewhere, so the rest of the screen is still checked. The failure lists
/// every other error, with the widgets involved.
Future<void> expectNoRealOverflow(
  WidgetTester tester,
  Future<void> Function() open, {
  List<String> ignoring = const [],
}) async {
  final errors = await collectFlutterErrors(open);
  final real = [
    for (final error in errors)
      if (!error.isArtifact && !ignoring.any(error.text.contains)) error.text,
  ];
  expect(real, isEmpty, reason: 'layout errors were reported:\n$real');
}

/// Expects the screen [open] draws in [translated] not to overflow by more
/// than the same screen, drawn the same way, does in Portuguese.
///
/// For a screen whose overflow is not its layout's: the attribution of
/// flutter_map, at the larger text size, is a few tenths of a pixel too wide
/// in every language. Portuguese is the baseline, and the worst overflow of
/// the translation must not exceed the worst one of the baseline; an error
/// that is not an overflow always fails.
///
/// [open] builds the screen in the locale it gets, on a phone's screen and
/// the larger text, and leaves it open.
Future<void> expectNoWorseThanPortuguese(
  WidgetTester tester,
  Locale translated,
  Future<void> Function(Locale locale) open,
) async {
  double worst(List<CollectedFlutterError> errors) => [
    for (final error in errors) error.overflow ?? double.infinity,
  ].fold(0, max);

  final baseline = await collectFlutterErrors(
    () => open(const Locale('pt', 'BR')),
  );
  // Takes the first screen away before the second one is built.
  await tester.pumpWidget(const SizedBox());
  final found = await collectFlutterErrors(() => open(translated));

  expect(
    worst(found),
    lessThanOrEqualTo(worst(baseline)),
    reason:
        '${translated.languageCode} reported ${found.length} error(s):\n'
        '${found.map((e) => e.text).join('\n')}\n'
        'Portuguese reported ${baseline.length}',
  );
}
