import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/organization/group_address.dart';

void main() {
  group('organizationIdProblem - Unit Test Suite', () {
    const valid = <(String, String)>[
      ('Happy Path: lowercase letters are valid', 'rotasul'),
      ('Edge Case: three letters (the minimum) are valid', 'abc'),
      ('Edge Case: an id that contains a reserved word is valid', 'apps'),
    ];
    for (final (label, id) in valid) {
      test('$label ("$id")', () {
        // 1. Arrange
        final input = id;

        // 2. Act
        final problem = organizationIdProblem(input);

        // 3. Assert
        expect(problem, isNull);
      });
    }

    const invalid = <(String, String)>[
      ('two letters are too short', 'ab'),
      ('a single letter is too short', 'x'),
      ('a digit makes the id invalid', 'tur2'),
      ('upper case letters are invalid', 'RotaSul'),
      ('a hyphen is invalid', 'rota-sul'),
      ('the reserved id app is invalid', 'app'),
      ('the reserved id community is invalid', 'community'),
      ('an empty id is invalid', ''),
    ];
    for (final (label, id) in invalid) {
      test('Sad Path: $label ("$id")', () {
        // 1. Arrange
        final input = id;

        // 2. Act
        final problem = organizationIdProblem(input);

        // 3. Assert
        expect(problem, isNotNull);
      });
    }
  });

  group('parseGroupAddress - Unit Test Suite', () {
    const parsed =
        <
          (
            String label,
            String email,
            String organizationId,
            String team,
            String? leaf,
            GroupLevel level,
            String teamKey,
          )
        >[
          (
            'Happy Path: the root group is the root level',
            'rotasul00@monamienet.org',
            'rotasul',
            '00',
            null,
            GroupLevel.root,
            'rotasul00',
          ),
          (
            'Happy Path: a team group is the team level',
            'rotasul01@monamienet.org',
            'rotasul',
            '01',
            null,
            GroupLevel.team,
            'rotasul01',
          ),
          (
            'Happy Path: a watch leaf is the leaf level with leaf r',
            'rotasul01r@monamienet.org',
            'rotasul',
            '01',
            'r',
            GroupLevel.leaf,
            'rotasul01',
          ),
          (
            'Happy Path: a share leaf is the leaf level with leaf w',
            'rotasul01w@monamienet.org',
            'rotasul',
            '01',
            'w',
            GroupLevel.leaf,
            'rotasul01',
          ),
          (
            'Edge Case: the last team number 99 is a team',
            'rotasul99@monamienet.org',
            'rotasul',
            '99',
            null,
            GroupLevel.team,
            'rotasul99',
          ),
          (
            'Edge Case: upper case letters are normalized',
            'RotaSul02W@MonAmieNet.ORG',
            'rotasul',
            '02',
            'w',
            GroupLevel.leaf,
            'rotasul02',
          ),
          (
            'Edge Case: surrounding whitespace is ignored',
            '  rotasul03r@monamienet.org \n',
            'rotasul',
            '03',
            'r',
            GroupLevel.leaf,
            'rotasul03',
          ),
        ];
    for (final (label, email, organizationId, team, leaf, level, teamKey)
        in parsed) {
      test('$label ("${email.trim()}")', () {
        // 1. Arrange
        final input = email;

        // 2. Act
        final address = parseGroupAddress(input);

        // 3. Assert
        expect(
          [
            address?.organizationId,
            address?.team,
            address?.leaf,
            address?.level,
            address?.teamKey,
          ],
          [organizationId, team, leaf, level, teamKey],
        );
      });
    }

    test('Happy Path: a leaf knows its team e-mail', () {
      // 1. Arrange
      const email = 'rotasul04r@monamienet.org';

      // 2. Act
      final address = parseGroupAddress(email);

      // 3. Assert
      expect(address?.teamEmail, 'rotasul04@monamienet.org');
    });

    const invalid = <(String, String)>[
      ('a watch leaf of the root group', 'rotasul00r@monamienet.org'),
      ('a share leaf of the root group', 'rotasul00w@monamienet.org'),
      ('an unknown leaf letter', 'rotasul01x@monamienet.org'),
      ('an organization id with digits', 'tur201@monamienet.org'),
      ('an organization id shorter than 3 letters', 'ab01@monamienet.org'),
      ('the reserved id app', 'app01w@monamienet.org'),
      ('the reserved id community', 'community00@monamienet.org'),
      ('no team number', 'rotasul@monamienet.org'),
      ('a one-digit team number', 'rotasul1@monamienet.org'),
      ('a three-digit team number', 'rotasul001@monamienet.org'),
      ('another domain', 'rotasul01w@gmail.com'),
      ('a subdomain', 'rotasul01w@sub.monamienet.org'),
      ('a hyphen in the organization id', 'rota-sul01@monamienet.org'),
      ('a text without @', 'rotasul01w'),
      ('an empty text', ''),
    ];
    for (final (label, email) in invalid) {
      test('Sad Path: $label gives null ("$email")', () {
        // 1. Arrange
        final input = email;

        // 2. Act
        final address = parseGroupAddress(input);

        // 3. Assert
        expect(address, isNull);
      });
    }
  });

  group('organizationIdFromGroupEmail - Unit Test Suite', () {
    const cases = <(String, String, String?)>[
      (
        'Happy Path: the root group gives its organization',
        'rotasul00@monamienet.org',
        'rotasul',
      ),
      (
        'Happy Path: a share leaf gives its organization',
        'rotasul01w@monamienet.org',
        'rotasul',
      ),
      (
        'Happy Path: a watch leaf gives its organization',
        'rotasul01r@monamienet.org',
        'rotasul',
      ),
      (
        'Edge Case: a mixed-case leaf gives its organization',
        ' RotaSul02R@MonAmieNet.org ',
        'rotasul',
      ),
      (
        'Edge Case: a direct team group gives no organization',
        'rotasul01@monamienet.org',
        null,
      ),
      (
        'Sad Path: an organization id with digits gives null',
        'tur201w@monamienet.org',
        null,
      ),
      ('Sad Path: another domain gives null', 'rotasul01w@gmail.com', null),
      (
        'Sad Path: a leaf of the root group gives null',
        'rotasul00r@monamienet.org',
        null,
      ),
    ];
    for (final (label, email, expected) in cases) {
      test('$label ("${email.trim()}")', () {
        // 1. Arrange
        final input = email;

        // 2. Act
        final id = organizationIdFromGroupEmail(input);

        // 3. Assert
        expect(id, expected);
      });
    }
  });

  group('teamEmailForKey - Unit Test Suite', () {
    test('Happy Path: a team key becomes the team e-mail', () {
      // 1. Arrange
      const key = 'rotasul01';

      // 2. Act
      final email = teamEmailForKey(key);

      // 3. Assert
      expect(email, 'rotasul01@monamienet.org');
    });
  });
}
