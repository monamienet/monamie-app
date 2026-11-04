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

  group('findTruncatedTexts - Widget Test Suite', () {
    // A text on one line in a box 100 pixels wide, cut with an ellipsis.
    Widget cutText(String text, {int maxLines = 1}) => Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100,
          child: Text(
            text,
            style: _manrope,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    testWidgets('Happy Path: a short text is not truncated', (tester) async {
      // 1. Arrange / 2. Act
      await pumpOnPhone(tester, cutText('Short'));

      // 3. Assert
      expect(truncatedTexts(tester), isEmpty);
    });

    testWidgets('Sad Path: a long text cut with an ellipsis is found, with '
        'its whole text', (tester) async {
      // 1. Arrange / 2. Act
      await pumpOnPhone(tester, cutText(_long));

      // 3. Assert: no overflow was thrown, the text is cut all the same.
      expect(tester.takeException(), isNull);
      expect(truncatedTexts(tester), [_long]);
    });

    testWidgets('Sad Path: a text clipped at its maxLines is found', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      await pumpOnPhone(tester, cutText('$_long. $_long. $_long', maxLines: 2));

      // 3. Assert
      expect(truncatedTexts(tester), hasLength(1));
    });

    testWidgets('Edge Case: a long text that still fits in its lines is not '
        'truncated', (tester) async {
      // 1. Arrange / 2. Act
      await pumpOnPhone(tester, cutText(_long, maxLines: 12));

      // 3. Assert
      expect(truncatedTexts(tester), isEmpty);
    });

    testWidgets('Edge Case: the text of a smaller scale is not truncated where '
        'the larger one is', (tester) async {
      // 1. Arrange
      const text = 'Fits here';

      // 2. Act / 3. Assert
      await pumpOnPhone(tester, cutText(text), textScale: 1);
      expect(truncatedTexts(tester), isEmpty);
      await pumpOnPhone(tester, cutText(text), textScale: 2.5);
      expect(truncatedTexts(tester), [text]);
    });

    testWidgets('Edge Case: a truncated text that is data is left out when '
        'the test names it', (tester) async {
      // 1. Arrange
      const email = 'una.direccion.muy.larga.de.correo@example.com';
      await pumpOnPhone(tester, cutText(email));

      // 2. Act
      final found = truncatedTexts(tester);
      final ignored = truncatedTexts(tester, ignoring: ['@example.com']);
      final other = truncatedTexts(tester, ignoring: ['another text']);
      final whole = truncatedTexts(tester, ignoring: [RegExp('^una.*com\$')]);
      final part = truncatedTexts(tester, ignoring: [RegExp('^direccion')]);

      // 3. Assert
      expect(found, [email]);
      expect(ignored, isEmpty);
      expect(other, [email]);
      expect(whole, isEmpty);
      expect(part, [email]);
    });

    testWidgets('Happy Path: says where the widget was created', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      await pumpOnPhone(tester, cutText(_long));

      // 3. Assert: the Text was created in this file, a framework widget
      // (flutter/lib/...text.dart) draws it.
      final found = findTruncatedTexts(tester);
      expect(found, hasLength(1));
      expect(found.single.text, _long);
      expect(found.single.where, contains('phone_layout_test.dart:'));
      expect(found.single.toString(), contains(_long));
    });

    testWidgets('Sad Path: a one-line text with no maxLines, ellipsized, is '
        'found', (tester) async {
      // 1. Arrange / 2. Act
      await pumpOnPhone(
        tester,
        const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: Text(
                _long,
                style: _manrope,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

      // 3. Assert
      expect(truncatedTexts(tester), [_long]);
    });

    testWidgets('Edge Case: tells a family-less text from one in Manrope', (
      tester,
    ) async {
      // 1. Arrange
      await pumpOnPhone(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: DefaultTextStyle(
                style: const TextStyle(fontSize: 16),
                child: Column(
                  children: [
                    const Text(
                      _long,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _long,
                      style: _manrope,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // 2. Act
      final found = findTruncatedTexts(tester);

      // 3. Assert
      expect(found.map((cut) => cut.familyless), [true, false]);
      expect(found.first.toString(), contains('family-less'));
    });

    testWidgets('Edge Case: finds nothing before anything was drawn', (
      tester,
    ) async {
      // 1. Arrange / 2. Act / 3. Assert
      expect(truncatedTexts(tester), isEmpty);
    });
  });

  group('expectNoNewTruncation - Widget Test Suite', () {
    // The text is longer in French than in Portuguese.
    Future<void> openText(
      WidgetTester tester,
      Locale locale, {
      required String portuguese,
      required String french,
    }) => pumpOnPhone(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            child: Text(
              locale.languageCode == 'pt' ? portuguese : french,
              style: _manrope,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      locale: locale,
    );

    testWidgets('Happy Path: a translation that fits passes', (tester) async {
      // 1. Arrange / 2. Act / 3. Assert
      await expectNoNewTruncation(
        tester,
        const Locale('fr', 'FR'),
        (locale) =>
            openText(tester, locale, portuguese: 'Court', french: 'Court'),
      );
    });

    testWidgets('Edge Case: a text cut in Portuguese too does not count '
        'against the translation', (tester) async {
      // 1. Arrange / 2. Act / 3. Assert
      await expectNoNewTruncation(
        tester,
        const Locale('fr', 'FR'),
        (locale) => openText(tester, locale, portuguese: _long, french: _long),
      );
    });

    testWidgets('Edge Case: a cut text that is data is left out', (
      tester,
    ) async {
      // 1. Arrange / 2. Act / 3. Assert
      await expectNoNewTruncation(
        tester,
        const Locale('fr', 'FR'),
        (locale) => openText(
          tester,
          locale,
          portuguese: 'Court',
          french: 'une.adresse.beaucoup.trop.longue@example.com',
        ),
        ignoring: ['@example.com'],
      );
    });

    testWidgets('Edge Case: a family-less text, drawn in Ahem, is a test-only '
        'cut and passes', (tester) async {
      // 1. Arrange / 2. Act / 3. Assert
      await expectNoNewTruncation(tester, const Locale('fr', 'FR'), (locale) {
        final long = locale.languageCode == 'pt' ? 'Court' : _long;
        return pumpOnPhone(
          tester,
          Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                child: DefaultTextStyle(
                  style: const TextStyle(fontSize: 16),
                  child: Text(
                    long,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          locale: locale,
        );
      });
    });

    testWidgets('Sad Path: a translation cut at another place than '
        'Portuguese fails', (tester) async {
      // 1. Arrange: both cut a text, drawn by widgets created in two places.
      Future<void> open(Locale locale) => pumpOnPhone(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: locale.languageCode == 'pt'
                  ? const Text(
                      _long,
                      style: _manrope,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const Padding(
                      padding: EdgeInsets.all(1),
                      child: Text(
                        _long,
                        style: _manrope,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),
        ),
        locale: locale,
      );

      // 2. Act
      final check = expectNoNewTruncation(
        tester,
        const Locale('fr', 'FR'),
        open,
      );

      // 3. Assert
      await expectLater(check, throwsA(isA<TestFailure>()));
    });

    testWidgets('Sad Path: a translation cut where Portuguese is not '
        'fails', (tester) async {
      // 1. Arrange / 2. Act
      final check = expectNoNewTruncation(
        tester,
        const Locale('fr', 'FR'),
        (locale) =>
            openText(tester, locale, portuguese: 'Court', french: _long),
      );

      // 3. Assert
      await expectLater(check, throwsA(isA<TestFailure>()));
    });

    testWidgets('Sad Path: an error that is not an overflow fails', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      final check = expectNoNewTruncation(tester, const Locale('fr', 'FR'), (
        locale,
      ) async {
        FlutterError.reportError(
          FlutterErrorDetails(exception: StateError('boom')),
        );
      });

      // 3. Assert
      await expectLater(check, throwsA(isA<TestFailure>()));
    });
  });
}
