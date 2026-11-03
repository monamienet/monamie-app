import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phone_layout.dart';

const _long = 'A text that is much too long for a row one hundred pixels wide';

/// A row 100 pixels wide holding [text], in [style].
Widget _narrowRow(String text, TextStyle style) => Scaffold(
  body: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 100,
      child: Row(children: [Text(text, style: style)]),
    ),
  ),
);

/// The same row whose text has no font family at all: it takes the default
/// style of the surrounding [DefaultTextStyle], as a button label does.
Widget _familylessRow(String text) => Scaffold(
  body: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 100,
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 16),
        child: Row(children: [Text(text)]),
      ),
    ),
  ),
);

const _manrope = TextStyle(fontFamily: 'Manrope', fontSize: 16);

void main() {
  setUpAll(loadAppFonts);

  group('collectFlutterErrors - Widget Test Suite', () {
    testWidgets('Happy Path: returns every error reported while it runs', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      final errors = await collectFlutterErrors(() async {
        await pumpOnPhone(tester, _narrowRow(_long, _manrope));
      });

      // 3. Assert
      expect(errors, isNotEmpty);
      expect(errors.first.overflow, isNotNull);
      expect(errors.first.text, contains('overflowed by'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edge Case: gives the error handler back afterwards', (
      tester,
    ) async {
      // 1. Arrange
      final before = FlutterError.onError;

      // 2. Act
      await collectFlutterErrors(() async {});

      // 3. Assert
      expect(FlutterError.onError, same(before));
    });

    testWidgets('Sad Path: gives the error handler back when the body '
        'throws', (tester) async {
      // 1. Arrange
      final before = FlutterError.onError;

      // 2. Act
      await expectLater(
        collectFlutterErrors(() async => throw StateError('boom')),
        throwsStateError,
      );

      // 3. Assert
      expect(FlutterError.onError, same(before));
    });
  });

  group('isFontArtifact - Widget Test Suite', () {
    testWidgets('Happy Path: the overflow of a family-less text is a '
        'test-only artifact', (tester) async {
      // 1. Arrange / 2. Act
      final errors = await collectFlutterErrors(
        () => pumpOnPhone(tester, _familylessRow(_long)),
      );

      // 3. Assert
      expect(errors, hasLength(1));
      expect(errors.single.isArtifact, isTrue);
    });

    testWidgets('Happy Path: the overflow of a Manrope text is the '
        'layout\'s', (tester) async {
      // 1. Arrange / 2. Act
      final errors = await collectFlutterErrors(
        () => pumpOnPhone(tester, _narrowRow(_long, _manrope)),
      );

      // 3. Assert
      expect(errors, hasLength(1));
      expect(errors.single.isArtifact, isFalse);
    });

    testWidgets('Sad Path: an error that is not an overflow is not an '
        'artifact', (tester) async {
      // 1. Arrange
      final details = FlutterErrorDetails(exception: StateError('boom'));

      // 2. Act
      final artifact = isFontArtifact(details);

      // 3. Assert
      expect(artifact, isFalse);
    });
  });

  group('expectNoRealOverflow - Widget Test Suite', () {
    testWidgets('Happy Path: a screen that fits passes', (tester) async {
      // 1. Arrange / 2. Act / 3. Assert
      await expectNoRealOverflow(
        tester,
        () => pumpOnPhone(tester, _narrowRow('Short', _manrope)),
      );
    });

    testWidgets('Edge Case: an overflow of a family-less text passes', (
      tester,
    ) async {
      // 1. Arrange / 2. Act / 3. Assert
      await expectNoRealOverflow(
        tester,
        () => pumpOnPhone(tester, _familylessRow(_long)),
      );
    });

    testWidgets('Edge Case: an overflow the test names is left out, the '
        'others still fail', (tester) async {
      // 1. Arrange
      Future<void> open() => pumpOnPhone(tester, _narrowRow(_long, _manrope));

      // 2. Act
      await expectNoRealOverflow(
        tester,
        open,
        ignoring: ['phone_layout_test.dart'],
      );
      await tester.pumpWidget(const SizedBox());
      final other = expectNoRealOverflow(
        tester,
        open,
        ignoring: ['another_file.dart:1'],
      );

      // 3. Assert
      await expectLater(other, throwsA(isA<TestFailure>()));
    });

    testWidgets('Sad Path: an overflow of a Manrope text fails', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      final check = expectNoRealOverflow(
        tester,
        () => pumpOnPhone(tester, _narrowRow(_long, _manrope)),
      );

      // 3. Assert
      await expectLater(check, throwsA(isA<TestFailure>()));
    });
  });

  group('expectNoWorseThanPortuguese - Widget Test Suite', () {
    // The text is longer in French than in Portuguese.
    Future<void> openRow(
      WidgetTester tester,
      Locale locale, {
      required String portuguese,
      required String french,
    }) => pumpOnPhone(
      tester,
      _narrowRow(locale.languageCode == 'pt' ? portuguese : french, _manrope),
      locale: locale,
    );

    testWidgets('Happy Path: a translation that fits passes', (tester) async {
      // 1. Arrange / 2. Act / 3. Assert
      await expectNoWorseThanPortuguese(
        tester,
        const Locale('fr', 'FR'),
        (locale) => openRow(tester, locale, portuguese: _long, french: 'Court'),
      );
    });

    testWidgets('Edge Case: an overflow no larger than Portuguese\'s passes', (
      tester,
    ) async {
      // 1. Arrange / 2. Act / 3. Assert
      await expectNoWorseThanPortuguese(
        tester,
        const Locale('fr', 'FR'),
        (locale) => openRow(tester, locale, portuguese: _long, french: _long),
      );
    });

    testWidgets('Sad Path: an overflow larger than Portuguese\'s fails', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      final check = expectNoWorseThanPortuguese(
        tester,
        const Locale('fr', 'FR'),
        (locale) => openRow(
          tester,
          locale,
          portuguese: 'A text a little too long for the row',
          french: '$_long, and then some more words after it',
        ),
      );

      // 3. Assert
      await expectLater(check, throwsA(isA<TestFailure>()));
    });

    testWidgets('Sad Path: an overflow where Portuguese has none fails', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      final check = expectNoWorseThanPortuguese(
        tester,
        const Locale('fr', 'FR'),
        (locale) => openRow(tester, locale, portuguese: 'Court', french: _long),
      );

      // 3. Assert
      await expectLater(check, throwsA(isA<TestFailure>()));
    });
  });
}
