import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/branding.dart';
import '../../../tool/src/organizations.dart';

const themeIds = ['grafite', 'oceano'];

/// Returns the message of the [OrganizationToolException] thrown by [action], or
/// fails the test when it does not throw one.
String messageOf(void Function() action) {
  try {
    action();
  } on OrganizationToolException catch (error) {
    return error.message;
  }
  fail('Expected an OrganizationToolException.');
}

void main() {
  group('buildBrandingDocument - Unit Test Suite', () {
    test('Happy Path: a name and a catalog theme give the document', () {
      // 1. Arrange
      const name = 'AquariusTur';

      // 2. Act
      final document = buildBrandingDocument(
        name: name,
        themeId: 'oceano',
        themeIds: themeIds,
      );

      // 3. Assert
      expect(document, {'name': 'AquariusTur', 'themeId': 'oceano'});
    });

    test('Edge Case: the name is trimmed', () {
      // 1. Arrange
      const name = '  AquariusTur \n';

      // 2. Act
      final document = buildBrandingDocument(
        name: name,
        themeId: 'grafite',
        themeIds: themeIds,
      );

      // 3. Assert
      expect(document['name'], 'AquariusTur');
    });

    test('Edge Case: a name that only starts with "MonAmie" is accepted', () {
      // 1. Arrange
      const name = 'MonAmieTur';

      // 2. Act
      final document = buildBrandingDocument(
        name: name,
        themeId: 'grafite',
        themeIds: themeIds,
      );

      // 3. Assert
      expect(document['name'], 'MonAmieTur');
    });

    test('Sad Path: a blank name is rejected', () {
      // 1. Arrange
      const name = '   ';

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(
          name: name,
          themeId: 'grafite',
          themeIds: themeIds,
        ),
      );

      // 3. Assert
      expect(message, isNotEmpty);
    });

    const prefixedNames = [
      'MonAmie AquariusTur',
      '  monamie AquariusTur',
      'MONAMIE Tur',
    ];
    for (final name in prefixedNames) {
      test(
        'Sad Path: the "MonAmie " prefix is rejected ("${name.trim()}")',
        () {
          // 1. Arrange
          final input = name;

          // 2. Act
          final message = messageOf(
            () => buildBrandingDocument(
              name: input,
              themeId: 'grafite',
              themeIds: themeIds,
            ),
          );

          // 3. Assert
          expect(message, contains('MonAmie'));
        },
      );
    }

    test('Sad Path: a theme outside the catalog is rejected naming the '
        'valid ids', () {
      // 1. Arrange
      const themeId = 'neon';

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(
          name: 'Acme',
          themeId: themeId,
          themeIds: themeIds,
        ),
      );

      // 3. Assert
      expect(message, allOf(contains('grafite'), contains('oceano')));
    });

    test('Sad Path: no theme is valid with an empty catalog', () {
      // 1. Arrange
      const List<String> catalog = [];

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(
          name: 'Acme',
          themeId: 'grafite',
          themeIds: catalog,
        ),
      );

      // 3. Assert
      expect(message, contains('grafite'));
    });
  });

  group('brandingDocumentPath - Unit Test Suite', () {
    test('Happy Path: the branding lives under the organization', () {
      // 1. Arrange
      const id = 'rotasul';

      // 2. Act
      final path = brandingDocumentPath(id);

      // 3. Assert
      expect(path, 'organizations/rotasul/config/branding');
    });
  });
}
