import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/partner/central_partner_directory.dart';

/// Complete Android options of partner [id], as `resolvePartners` returns
/// them.
Map<String, Object?> optionsOf(String id) => {
  'apiKey': 'key-$id',
  'appId': '1:111:android:$id',
  'projectId': 'monamienet-$id',
  'messagingSenderId': '111',
  'storageBucket': 'monamienet-$id.firebasestorage.app',
};

Map<String, Object?> entry(String id, [Map<String, Object?>? options]) => {
  'id': id,
  'options': options ?? optionsOf(id),
};

Map<String, Object?> response(List<Object?> partners) => {'partners': partners};

void main() {
  group('parsePartnerCandidates - Unit Test Suite', () {
    test('Happy Path: returns every valid partner sorted by id', () {
      // 1. Arrange
      final data = response([entry('zeta'), entry('aquariustur'), entry('m')]);

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates.map((c) => c.id), ['aquariustur', 'm', 'zeta']);
    });

    test('Happy Path: carries the Firebase options of each partner', () {
      // 1. Arrange
      final data = response([
        entry('acme', {
          ...optionsOf('acme'),
          'authDomain': 'monamienet-acme.firebaseapp.com',
        }),
      ]);

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(
        candidates.single.options,
        const FirebaseOptions(
          apiKey: 'key-acme',
          appId: '1:111:android:acme',
          projectId: 'monamienet-acme',
          messagingSenderId: '111',
          storageBucket: 'monamienet-acme.firebasestorage.app',
          authDomain: 'monamienet-acme.firebaseapp.com',
        ),
      );
    });

    test('Edge Case: missing optional options are null', () {
      // 1. Arrange
      final data = response([
        entry('acme', {...optionsOf('acme')}..remove('storageBucket')),
      ]);

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(
        [
          candidates.single.options.storageBucket,
          candidates.single.options.authDomain,
        ],
        [null, null],
      );
    });

    test('Edge Case: empty optional options are null', () {
      // 1. Arrange
      final data = response([
        entry('acme', {...optionsOf('acme'), 'authDomain': ''}),
      ]);

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates.single.options.authDomain, isNull);
    });

    test('Edge Case: an empty partner list gives no candidates', () {
      // 1. Arrange
      final data = response([]);

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates, isEmpty);
    });

    const invalidIds = ['app', 'Acme', '2tur', 'aquarius-tur', ''];
    for (final id in invalidIds) {
      test('Sad Path: an entry with the invalid id "$id" is skipped', () {
        // 1. Arrange
        final data = response([entry('acme'), entry(id, optionsOf('x'))]);

        // 2. Act
        final candidates = parsePartnerCandidates(data);

        // 3. Assert
        expect(candidates.map((c) => c.id), ['acme']);
      });
    }

    const requiredKeys = ['apiKey', 'appId', 'projectId', 'messagingSenderId'];
    for (final key in requiredKeys) {
      test('Sad Path: an entry without options.$key is skipped', () {
        // 1. Arrange
        final data = response([
          entry('acme'),
          entry('beta', optionsOf('beta')..remove(key)),
        ]);

        // 2. Act
        final candidates = parsePartnerCandidates(data);

        // 3. Assert
        expect(candidates.map((c) => c.id), ['acme']);
      });
    }

    test('Sad Path: an entry with an empty required option is skipped', () {
      // 1. Arrange
      final data = response([
        entry('beta', {...optionsOf('beta'), 'apiKey': ''}),
        entry('acme'),
      ]);

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates.map((c) => c.id), ['acme']);
    });

    test('Sad Path: an entry with a non-string required option is skipped', () {
      // 1. Arrange
      final data = response([
        entry('beta', {...optionsOf('beta'), 'messagingSenderId': 111}),
        entry('acme'),
      ]);

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates.map((c) => c.id), ['acme']);
    });

    test('Sad Path: entries that are not maps or lack options are skipped', () {
      // 1. Arrange
      final data = response([
        'acme',
        null,
        {'id': 'beta'},
        {'id': 'gamma', 'options': 'api-key'},
        entry('acme'),
      ]);

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates.map((c) => c.id), ['acme']);
    });

    test('Sad Path: null data gives no candidates', () {
      // 1. Arrange
      const Object? data = null;

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates, isEmpty);
    });

    test('Sad Path: a list as data gives no candidates', () {
      // 1. Arrange
      final data = [entry('acme')];

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates, isEmpty);
    });

    test('Sad Path: a map without "partners" gives no candidates', () {
      // 1. Arrange
      final data = {'error': 'internal'};

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates, isEmpty);
    });

    test('Sad Path: "partners" that is not a list gives no candidates', () {
      // 1. Arrange
      final data = {'partners': entry('acme')};

      // 2. Act
      final candidates = parsePartnerCandidates(data);

      // 3. Assert
      expect(candidates, isEmpty);
    });
  });
}
