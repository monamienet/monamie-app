import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/src/partners.dart';

/// Creates `partners/<id>/partner.json` under [repoRoot] with [json].
void writePartner(Directory repoRoot, String id, {String json = '{}'}) {
  File(p.join(repoRoot.path, 'partners', id, partnerConfigFileName))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(json);
}

void main() {
  late Directory repoRoot;

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('partner_tool_partners_');
  });

  tearDown(() {
    if (repoRoot.existsSync()) {
      repoRoot.deleteSync(recursive: true);
    }
  });

  group('partnerIdProblem - Unit Test Suite', () {
    test('Happy Path: returns null for a lowercase alphabetic id', () {
      // 1. Arrange
      const id = 'acme';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Happy Path: returns null for an id mixing letters and digits', () {
      // 1. Arrange
      const id = 'acme2go';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: returns null for a single lowercase letter', () {
      // 1. Arrange
      const id = 'a';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: returns null for an id containing but not starting '
        'with "test"', () {
      // 1. Arrange
      const id = 'mytest';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: returns null for an id that only extends a reserved '
        'name', () {
      // 1. Arrange
      const id = 'mainstreet';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Sad Path: rejects an empty id', () {
      // 1. Arrange
      const id = '';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects an id with an uppercase letter and names it', () {
      // 1. Arrange
      const id = 'Test';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, contains("'Test'"));
    });

    test('Sad Path: rejects an id starting with a digit', () {
      // 1. Arrange
      const id = '1abc';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects an id containing a hyphen', () {
      // 1. Arrange
      const id = 'a-b';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects an id containing an underscore', () {
      // 1. Arrange
      const id = 'a_b';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects a path traversal id', () {
      // 1. Arrange
      const id = '../x';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects an id with surrounding whitespace', () {
      // 1. Arrange
      const id = ' acme ';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects an id with a trailing newline', () {
      // 1. Arrange
      const id = 'acme\n';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects an id starting with "test" and explains why', () {
      // 1. Arrange
      const id = 'testing';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, contains('test'));
    });

    test('Sad Path: rejects the id "test" itself', () {
      // 1. Arrange
      const id = 'test';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects the reserved id "lint"', () {
      // 1. Arrange
      const id = 'lint';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects the reserved id "main"', () {
      // 1. Arrange
      const id = 'main';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects the reserved id "debug"', () {
      // 1. Arrange
      const id = 'debug';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects the reserved id "release"', () {
      // 1. Arrange
      const id = 'release';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: rejects the reserved id "profile"', () {
      // 1. Arrange
      const id = 'profile';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });
  });

  group('reservedPartnerIds - Unit Test Suite', () {
    test('Happy Path: holds exactly the names reserved by the Android '
        'build', () {
      // 1. Arrange
      const expected = {'lint', 'main', 'debug', 'release', 'profile'};

      // 2. Act
      final reserved = reservedPartnerIds;

      // 3. Assert
      expect(reserved, equals(expected));
    });
  });

  group('listPartnerIds - Unit Test Suite', () {
    test('Happy Path: returns the partner ids sorted alphabetically', () {
      // 1. Arrange
      writePartner(repoRoot, 'zeta');
      writePartner(repoRoot, 'acme');
      writePartner(repoRoot, 'mid');

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme', 'mid', 'zeta']);
    });

    test('Edge Case: returns an empty list when partners/ is missing', () {
      // 1. Arrange
      final emptyRepo = repoRoot;

      // 2. Act
      final ids = listPartnerIds(emptyRepo);

      // 3. Assert
      expect(ids, isEmpty);
    });

    test('Edge Case: returns an empty list when partners/ is empty', () {
      // 1. Arrange
      Directory(p.join(repoRoot.path, 'partners')).createSync();

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, isEmpty);
    });

    test('Edge Case: ignores folders without partner.json', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      Directory(
        p.join(repoRoot.path, 'partners', 'draft', 'android'),
      ).createSync(recursive: true);

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme']);
    });

    test('Edge Case: ignores stray files directly under partners/', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      File(
        p.join(repoRoot.path, 'partners', 'README.md'),
      ).writeAsStringSync('# Partners');
      File(
        p.join(repoRoot.path, 'partners', partnerConfigFileName),
      ).writeAsStringSync('{}');

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme']);
    });

    test('Edge Case: ignores partner.json nested deeper than one level', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      File(p.join(repoRoot.path, 'partners', 'group', 'inner', 'partner.json'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{}');

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme']);
    });

    test('Sad Path: ignores a folder whose partner.json is a directory', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      Directory(
        p.join(repoRoot.path, 'partners', 'broken', partnerConfigFileName),
      ).createSync(recursive: true);

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme']);
    });
  });

  group('listPartnerIds symlinks - Unit Test Suite', () {
    test('Happy Path: lists a symlink pointing to a partner folder', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      final outside = Directory(p.join(repoRoot.path, 'elsewhere', 'beta'))
        ..createSync(recursive: true);
      File(p.join(outside.path, partnerConfigFileName)).writeAsStringSync('{}');
      Link(p.join(repoRoot.path, 'partners', 'beta')).createSync(outside.path);

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme', 'beta']);
    });

    test('Edge Case: lists the link name, not the target folder name', () {
      // 1. Arrange
      final outside = Directory(p.join(repoRoot.path, 'elsewhere', 'target'))
        ..createSync(recursive: true);
      File(p.join(outside.path, partnerConfigFileName)).writeAsStringSync('{}');
      Directory(p.join(repoRoot.path, 'partners')).createSync();
      Link(p.join(repoRoot.path, 'partners', 'alias')).createSync(outside.path);

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['alias']);
    });

    test('Edge Case: ignores a symlink to a folder without partner.json', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      final outside = Directory(p.join(repoRoot.path, 'elsewhere', 'empty'))
        ..createSync(recursive: true);
      Link(p.join(repoRoot.path, 'partners', 'empty')).createSync(outside.path);

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme']);
    });

    test('Sad Path: ignores a dangling symlink under partners/', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      Link(
        p.join(repoRoot.path, 'partners', 'ghost'),
      ).createSync(p.join(repoRoot.path, 'does-not-exist'));

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme']);
    });

    test('Sad Path: ignores a symlink pointing to a file', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      final file = File(p.join(repoRoot.path, 'notes.txt'))
        ..writeAsStringSync('x');
      Link(p.join(repoRoot.path, 'partners', 'notes')).createSync(file.path);

      // 2. Act
      final ids = listPartnerIds(repoRoot);

      // 3. Assert
      expect(ids, ['acme']);
    });
  });

  group('partnerConfigFile - Unit Test Suite', () {
    test('Happy Path: returns partners/<id>/partner.json for a known '
        'partner', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');
      final expectedPath = p.join(
        repoRoot.path,
        'partners',
        'acme',
        partnerConfigFileName,
      );

      // 2. Act
      final file = partnerConfigFile(repoRoot, 'acme');

      // 3. Assert
      expect(p.equals(file.path, expectedPath), isTrue);
    });

    test('Edge Case: returns the file even when its content is not valid '
        'JSON', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', json: 'not json');

      // 2. Act
      final file = partnerConfigFile(repoRoot, 'acme');

      // 3. Assert
      expect(file.existsSync(), isTrue);
    });

    test('Happy Path: resolves a partner whose folder is a symlink', () {
      // 1. Arrange
      final outside = Directory(p.join(repoRoot.path, 'elsewhere', 'beta'))
        ..createSync(recursive: true);
      File(p.join(outside.path, partnerConfigFileName)).writeAsStringSync('{}');
      Directory(p.join(repoRoot.path, 'partners')).createSync();
      Link(p.join(repoRoot.path, 'partners', 'beta')).createSync(outside.path);

      // 2. Act
      final file = partnerConfigFile(repoRoot, 'beta');

      // 3. Assert
      expect(file.readAsStringSync(), '{}');
    });

    test('Sad Path: throws PartnerToolException for an invalid id', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme');

      // 2. Act
      File action() => partnerConfigFile(repoRoot, 'Acme');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: throws PartnerToolException for a reserved id even when '
        'its folder exists', () {
      // 1. Arrange
      writePartner(repoRoot, 'main');

      // 2. Act
      File action() => partnerConfigFile(repoRoot, 'main');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: throws PartnerToolException for a path traversal id', () {
      // 1. Arrange
      File(
        p.join(repoRoot.path, partnerConfigFileName),
      ).writeAsStringSync('{}');

      // 2. Act
      File action() => partnerConfigFile(repoRoot, '..');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: the message for an unknown id names the id and lists '
        'the existing partners', () {
      // 1. Arrange
      writePartner(repoRoot, 'zeta');
      writePartner(repoRoot, 'acme');

      // 2. Act
      File action() => partnerConfigFile(repoRoot, 'nope');

      // 3. Assert
      expect(
        action,
        throwsA(
          isA<PartnerToolException>().having(
            (error) => error.message,
            'message',
            allOf(contains('nope'), contains('acme'), contains('zeta')),
          ),
        ),
      );
    });

    test('Sad Path: throws for an unknown id when partners/ is missing', () {
      // 1. Arrange
      final emptyRepo = repoRoot;

      // 2. Act
      File action() => partnerConfigFile(emptyRepo, 'acme');

      // 3. Assert
      expect(
        action,
        throwsA(
          isA<PartnerToolException>().having(
            (error) => error.message,
            'message',
            contains('acme'),
          ),
        ),
      );
    });

    test('Sad Path: throws for a folder that exists without partner.json', () {
      // 1. Arrange
      Directory(
        p.join(repoRoot.path, 'partners', 'draft'),
      ).createSync(recursive: true);

      // 2. Act
      File action() => partnerConfigFile(repoRoot, 'draft');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });
  });

  group('partnerDisplayName - Unit Test Suite', () {
    test('Happy Path: prefixes the partner name with "MonAmie "', () {
      // 1. Arrange
      const name = 'AquariusTur';

      // 2. Act
      final displayName = partnerDisplayName(name);

      // 3. Assert
      expect(displayName, 'MonAmie AquariusTur');
    });

    test('Edge Case: keeps spaces inside the partner name', () {
      // 1. Arrange
      const name = 'Rio Tur';

      // 2. Act
      final displayName = partnerDisplayName(name);

      // 3. Assert
      expect(displayName, 'MonAmie Rio Tur');
    });

    test('Edge Case: keeps accents and non-ASCII letters', () {
      // 1. Arrange
      const name = 'Acmé Ção';

      // 2. Act
      final displayName = partnerDisplayName(name);

      // 3. Assert
      expect(displayName, 'MonAmie Acmé Ção');
    });

    test('Edge Case: keeps the letter case of the partner name', () {
      // 1. Arrange
      const name = 'aQuArIuStUr';

      // 2. Act
      final displayName = partnerDisplayName(name);

      // 3. Assert
      expect(displayName, 'MonAmie aQuArIuStUr');
    });

    test(
      'Sad Path: does not deduplicate a name that already starts with "MonAmie"',
      () {
        // 1. Arrange
        const name = 'MonAmie Acme';

        // 2. Act
        final displayName = partnerDisplayName(name);

        // 3. Assert
        expect(displayName, 'MonAmie MonAmie Acme');
      },
    );
  });

  group('isHexColor - Unit Test Suite', () {
    test('Happy Path: accepts an uppercase #RRGGBB color', () {
      // 1. Arrange
      const value = '#0ABAB5';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isTrue);
    });

    test('Happy Path: accepts black #000000', () {
      // 1. Arrange
      const value = '#000000';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isTrue);
    });

    test('Edge Case: accepts a lowercase #rrggbb color', () {
      // 1. Arrange
      const value = '#0abab5';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isTrue);
    });

    test('Edge Case: accepts a mixed-case color', () {
      // 1. Arrange
      const value = '#0aBaB5';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isTrue);
    });

    test('Edge Case: rejects a color with surrounding whitespace', () {
      // 1. Arrange
      const value = ' #0ABAB5 ';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Edge Case: rejects a color followed by a newline', () {
      // 1. Arrange
      const value = '#0ABAB5\n';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Edge Case: rejects an empty string', () {
      // 1. Arrange
      const value = '';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Edge Case: rejects a lone "#"', () {
      // 1. Arrange
      const value = '#';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects the short #RGB form', () {
      // 1. Arrange
      const value = '#FFF';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects the #AARRGGBB form', () {
      // 1. Arrange
      const value = '#FF0ABAB5';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects a color without the leading "#"', () {
      // 1. Arrange
      const value = '0ABAB5';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects the 0x prefix', () {
      // 1. Arrange
      const value = '0x0ABAB5';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects non-hex digits', () {
      // 1. Arrange
      const value = '#GGHHII';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects a color name', () {
      // 1. Arrange
      const value = 'teal';

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects an integer value', () {
      // 1. Arrange
      const value = 0x0ABAB5;

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects null', () {
      // 1. Arrange
      const Object? value = null;

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects a list holding a valid color', () {
      // 1. Arrange
      const value = ['#0ABAB5'];

      // 2. Act
      final isValid = isHexColor(value);

      // 3. Assert
      expect(isValid, isFalse);
    });
  });

  group('firebaseProjectId - Unit Test Suite', () {
    test('Happy Path: prefixes the id with "monamienet-"', () {
      // 1. Arrange
      const id = 'acme';

      // 2. Act
      final projectId = firebaseProjectId(id);

      // 3. Assert
      expect(projectId, 'monamienet-acme');
    });

    test('Edge Case: keeps digits and a single-letter id as they are', () {
      // 1. Arrange
      const id = 'a2';

      // 2. Act
      final projectId = firebaseProjectId(id);

      // 3. Assert
      expect(projectId, 'monamienet-a2');
    });

    test('Sad Path: two different ids never share a Firebase project', () {
      // 1. Arrange
      const id = 'acme';
      final otherProjectId = firebaseProjectId('acmex');

      // 2. Act
      final projectId = firebaseProjectId(id);

      // 3. Assert
      expect(projectId, isNot(otherProjectId));
    });
  });

  group('androidApplicationId - Unit Test Suite', () {
    test('Happy Path: prefixes the id with "org.monamienet."', () {
      // 1. Arrange
      const id = 'acme';

      // 2. Act
      final applicationId = androidApplicationId(id);

      // 3. Assert
      expect(applicationId, 'org.monamienet.acme');
    });

    test('Edge Case: keeps digits and a single-letter id as they are', () {
      // 1. Arrange
      const id = 'a2';

      // 2. Act
      final applicationId = androidApplicationId(id);

      // 3. Assert
      expect(applicationId, 'org.monamienet.a2');
    });

    test('Sad Path: two different ids never share an application id', () {
      // 1. Arrange
      const id = 'acme';
      final otherApplicationId = androidApplicationId('acmex');

      // 2. Act
      final applicationId = androidApplicationId(id);

      // 3. Assert
      expect(applicationId, isNot(otherApplicationId));
    });
  });

  group('PartnerToolException - Unit Test Suite', () {
    test('Happy Path: exposes the message it was created with', () {
      // 1. Arrange
      const message = 'Something went wrong.';

      // 2. Act
      final text = PartnerToolException(message).message;

      // 3. Assert
      expect(text, 'Something went wrong.');
    });
  });
}
