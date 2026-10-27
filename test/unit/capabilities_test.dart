import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';

/// Every rotasul team group the gateway lists under the root group.
const rotasulTeams = ['rotasul03', 'rotasul01', 'rotasul02', 'outro01'];

void main() {
  group('Capabilities.fromClaims - Unit Test Suite', () {
    test('Happy Path: reads the three claims as sets', () {
      // 1. Arrange
      final claims = <String, Object?>{
        'share': ['rotasul01'],
        'watch': ['rotasul01', 'rotasul02'],
        'owns': ['rotasul'],
        'email': 'ana@example.com',
      };

      // 2. Act
      final caps = Capabilities.fromClaims(claims);

      // 3. Assert
      expect(
        [caps.share, caps.watch, caps.owns],
        [
          {'rotasul01'},
          {'rotasul01', 'rotasul02'},
          {'rotasul'},
        ],
      );
    });

    test('Edge Case: values are lowercased and duplicates collapse', () {
      // 1. Arrange
      final claims = <String, Object?>{
        'watch': ['RotaSul01', 'rotasul01'],
      };

      // 2. Act
      final caps = Capabilities.fromClaims(claims);

      // 3. Assert
      expect(caps.watch, {'rotasul01'});
    });

    test('Edge Case: missing claims are empty sets', () {
      // 1. Arrange
      final claims = <String, Object?>{'email': 'ana@example.com'};

      // 2. Act
      final caps = Capabilities.fromClaims(claims);

      // 3. Assert
      expect(
        [caps.share, caps.watch, caps.owns],
        [<String>{}, <String>{}, <String>{}],
      );
    });

    test('Sad Path: non-strings and empty strings are dropped', () {
      // 1. Arrange
      final claims = <String, Object?>{
        'share': [42, null, '', 'rotasul01', true],
      };

      // 2. Act
      final caps = Capabilities.fromClaims(claims);

      // 3. Assert
      expect(caps.share, {'rotasul01'});
    });

    test('Sad Path: a claim that is not a list is an empty set', () {
      // 1. Arrange
      final claims = <String, Object?>{
        'share': 'rotasul01',
        'watch': {'rotasul01': true},
        'owns': 7,
      };

      // 2. Act
      final caps = Capabilities.fromClaims(claims);

      // 3. Assert
      expect(
        [caps.share, caps.watch, caps.owns],
        [<String>{}, <String>{}, <String>{}],
      );
    });
  });

  group('Capabilities.isEmpty / canShare - Unit Test Suite', () {
    test('Happy Path: no capability is empty', () {
      // 1. Arrange
      const caps = Capabilities();

      // 2. Act
      final empty = caps.isEmpty;

      // 3. Assert
      expect(empty, isTrue);
    });

    final nonEmpty = <(String, Capabilities)>[
      ('share alone', const Capabilities(share: {'rotasul01'})),
      ('watch alone', const Capabilities(watch: {'rotasul01'})),
      ('owns alone', const Capabilities(owns: {'rotasul'})),
    ];
    for (final (label, caps) in nonEmpty) {
      test('Edge Case: $label is not empty', () {
        // 1. Arrange
        final input = caps;

        // 2. Act
        final empty = input.isEmpty;

        // 3. Assert
        expect(empty, isFalse);
      });
    }

    test('Happy Path: sharing in a team means the person can share', () {
      // 1. Arrange
      const caps = Capabilities(share: {'rotasul01'});

      // 2. Act
      final canShare = caps.canShare;

      // 3. Assert
      expect(canShare, isTrue);
    });

    test('Sad Path: watching and owning do not let the person share', () {
      // 1. Arrange
      const caps = Capabilities(watch: {'rotasul01'}, owns: {'rotasul'});

      // 2. Act
      final canShare = caps.canShare;

      // 3. Assert
      expect(canShare, isFalse);
    });
  });

  group('Capabilities.isOwnerOf - Unit Test Suite', () {
    final cases = <(String, Capabilities, String, bool)>[
      (
        'Happy Path: owns lists the partner',
        const Capabilities(owns: {'rotasul'}),
        'rotasul',
        true,
      ),
      (
        'Edge Case: watching every team is not owning',
        const Capabilities(watch: {'rotasul01', 'rotasul02'}),
        'rotasul',
        false,
      ),
      (
        'Sad Path: owning another partner is not owning this one',
        const Capabilities(owns: {'outro'}),
        'rotasul',
        false,
      ),
    ];
    for (final (label, caps, partnerId, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final input = caps;

        // 2. Act
        final owner = input.isOwnerOf(partnerId);

        // 3. Assert
        expect(owner, expected);
      });
    }
  });

  group('Capabilities.canWatchIn - Unit Test Suite', () {
    final cases = <(String, Capabilities, bool)>[
      (
        'Happy Path: the owner watches in the partner',
        const Capabilities(owns: {'rotasul'}),
        true,
      ),
      (
        'Happy Path: watching one team is watching in the partner',
        const Capabilities(watch: {'rotasul02'}),
        true,
      ),
      (
        'Edge Case: sharing alone is not watching',
        const Capabilities(share: {'rotasul01'}),
        false,
      ),
      (
        'Sad Path: watching a team of another partner is not enough',
        const Capabilities(watch: {'outro01'}, owns: {'outro'}),
        false,
      ),
    ];
    for (final (label, caps, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final input = caps;

        // 2. Act
        final watches = input.canWatchIn('rotasul');

        // 3. Assert
        expect(watches, expected);
      });
    }
  });

  group('Capabilities.canWatchTeam - Unit Test Suite', () {
    final cases = <(String, Capabilities, bool)>[
      (
        'Happy Path: watching the team',
        const Capabilities(watch: {'rotasul01'}),
        true,
      ),
      (
        'Happy Path: owning the team\'s partner',
        const Capabilities(owns: {'rotasul'}),
        true,
      ),
      (
        'Edge Case: sharing in the team is not watching it',
        const Capabilities(share: {'rotasul01'}),
        false,
      ),
      (
        'Sad Path: watching another team of the same partner',
        const Capabilities(watch: {'rotasul02'}),
        false,
      ),
      (
        'Sad Path: owning another partner',
        const Capabilities(owns: {'outro'}),
        false,
      ),
    ];
    for (final (label, caps, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final input = caps;

        // 2. Act
        final watches = input.canWatchTeam('rotasul01');

        // 3. Assert
        expect(watches, expected);
      });
    }
  });

  group('Capabilities.shareTeamsIn - Unit Test Suite', () {
    test('Happy Path: the partner\'s share teams, sorted', () {
      // 1. Arrange
      const caps = Capabilities(share: {'rotasul03', 'rotasul01'});

      // 2. Act
      final teams = caps.shareTeamsIn('rotasul');

      // 3. Assert
      expect(teams, ['rotasul01', 'rotasul03']);
    });

    test('Edge Case: teams of other partners are left out', () {
      // 1. Arrange
      const caps = Capabilities(share: {'outro01', 'rotasul02'});

      // 2. Act
      final teams = caps.shareTeamsIn('rotasul');

      // 3. Assert
      expect(teams, ['rotasul02']);
    });

    test('Sad Path: owning the partner gives no share teams', () {
      // 1. Arrange
      const caps = Capabilities(owns: {'rotasul'}, watch: {'rotasul01'});

      // 2. Act
      final teams = caps.shareTeamsIn('rotasul');

      // 3. Assert
      expect(teams, isEmpty);
    });
  });

  group('Capabilities.watchTeamsIn - Unit Test Suite', () {
    test('Happy Path: the owner sees every team of the partner, sorted', () {
      // 1. Arrange
      const caps = Capabilities(owns: {'rotasul'});

      // 2. Act
      final teams = caps.watchTeamsIn('rotasul', rotasulTeams);

      // 3. Assert
      expect(teams, ['rotasul01', 'rotasul02', 'rotasul03']);
    });

    test('Happy Path: a watcher sees only the teams they watch, sorted', () {
      // 1. Arrange
      const caps = Capabilities(watch: {'rotasul03', 'rotasul01', 'outro01'});

      // 2. Act
      final teams = caps.watchTeamsIn('rotasul', rotasulTeams);

      // 3. Assert
      expect(teams, ['rotasul01', 'rotasul03']);
    });

    test('Edge Case: an owner with no team groups listed sees none', () {
      // 1. Arrange
      const caps = Capabilities(owns: {'rotasul'});

      // 2. Act
      final teams = caps.watchTeamsIn('rotasul', const []);

      // 3. Assert
      expect(teams, isEmpty);
    });

    test('Sad Path: sharing alone sees no team', () {
      // 1. Arrange
      const caps = Capabilities(share: {'rotasul01'});

      // 2. Act
      final teams = caps.watchTeamsIn('rotasul', rotasulTeams);

      // 3. Assert
      expect(teams, isEmpty);
    });
  });
}
