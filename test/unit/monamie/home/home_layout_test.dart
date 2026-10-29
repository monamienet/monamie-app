import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_layout.dart';

void main() {
  group('HomeLayout.of - Unit Test Suite', () {
    // (label, canShare, canWatch, isWeb, showShareCard, showTeam)
    final cases = <(String, bool, bool, bool, bool, bool)>[
      ('Happy Path: share only on a phone', true, false, false, true, false),
      ('Happy Path: watch only on a phone', false, true, false, false, true),
      ('Happy Path: share and watch on a phone', true, true, false, true, true),
      (
        'Edge Case: share only on the web has no card but keeps the note',
        true,
        false,
        true,
        false,
        false,
      ),
      ('Edge Case: watch only on the web', false, true, true, false, true),
      (
        'Edge Case: share and watch on the web has no card',
        true,
        true,
        true,
        false,
        true,
      ),
      (
        'Sad Path: no capabilities show nothing',
        false,
        false,
        false,
        false,
        false,
      ),
      (
        'Sad Path: no capabilities on the web show nothing',
        false,
        false,
        true,
        false,
        false,
      ),
    ];
    for (final (label, share, watch, web, card, team) in cases) {
      test(label, () {
        // 1. Arrange
        final canShare = share;
        final canWatch = watch;

        // 2. Act
        final layout = HomeLayout.of(
          canShare: canShare,
          canWatch: canWatch,
          isWeb: web,
        );

        // 3. Assert
        expect((layout.showShareCard, layout.showTeam), (card, team));
      });
    }
  });

  group('teamChipLabel - Unit Test Suite', () {
    test('Happy Path: a watcher sees the team they picked', () {
      // 1. Arrange / 2. Act
      final label = teamChipLabel(
        canWatch: true,
        observedTeam: 'Centro',
        shareTeams: const [],
      );

      // 3. Assert
      expect(label, 'Centro');
    });

    test('Happy Path: share only with one team names that team (#110)', () {
      // 1. Arrange / 2. Act
      final label = teamChipLabel(
        canWatch: false,
        observedTeam: null,
        shareTeams: const ['Zona Norte'],
      );

      // 3. Assert
      expect(label, 'Zona Norte');
    });

    test('Edge Case: share only with several teams names the first +N', () {
      // 1. Arrange / 2. Act
      final label = teamChipLabel(
        canWatch: false,
        observedTeam: null,
        shareTeams: const ['Centro', 'Zona Norte', 'Zona Sul'],
      );

      // 3. Assert
      expect(label, 'Centro +2');
    });

    test('Edge Case: share only with two teams reads "+1"', () {
      // 1. Arrange / 2. Act
      final label = teamChipLabel(
        canWatch: false,
        observedTeam: null,
        shareTeams: const ['Centro', 'Zona Norte'],
      );

      // 3. Assert
      expect(label, 'Centro +1');
    });

    test('Edge Case: a watcher who shares too still picks the team', () {
      // 1. Arrange / 2. Act
      final label = teamChipLabel(
        canWatch: true,
        observedTeam: 'Zona Sul',
        shareTeams: const ['Centro'],
      );

      // 3. Assert
      expect(label, 'Zona Sul');
    });

    test('Edge Case: a watcher with no team picked is asked to choose', () {
      // 1. Arrange / 2. Act
      final label = teamChipLabel(
        canWatch: true,
        observedTeam: null,
        shareTeams: const ['Centro'],
      );

      // 3. Assert
      expect(label, 'Escolher equipe');
    });

    test(
      'Sad Path: a person who only shares ignores a stale observed team',
      () {
        // 1. Arrange / 2. Act
        final label = teamChipLabel(
          canWatch: false,
          observedTeam: 'Outra',
          shareTeams: const ['Centro'],
        );

        // 3. Assert
        expect(label, 'Centro');
      },
    );

    test('Sad Path: no capability and no team reads "Sem equipe"', () {
      // 1. Arrange / 2. Act
      final label = teamChipLabel(
        canWatch: false,
        observedTeam: null,
        shareTeams: const [],
      );

      // 3. Assert
      expect(label, 'Sem equipe');
    });
  });

  group('menuSubtitle - Unit Test Suite', () {
    test('Happy Path: an administrator is told so', () {
      // 1. Arrange / 2. Act
      final subtitle = menuSubtitle(
        isAdmin: true,
        canWatch: true,
        canShare: false,
        shareTeams: const [],
      );

      // 3. Assert
      expect(subtitle, 'Administra a organização');
    });

    test('Happy Path: share only names the team, in the field (#110)', () {
      // 1. Arrange / 2. Act
      final subtitle = menuSubtitle(
        isAdmin: false,
        canWatch: false,
        canShare: true,
        shareTeams: const ['Centro'],
      );

      // 3. Assert
      expect(subtitle, 'Centro · em campo');
    });

    test('Happy Path: watch only', () {
      // 1. Arrange / 2. Act
      final subtitle = menuSubtitle(
        isAdmin: false,
        canWatch: true,
        canShare: false,
        shareTeams: const [],
      );

      // 3. Assert
      expect(subtitle, 'Acompanha o mapa');
    });

    test('Happy Path: watch and share', () {
      // 1. Arrange / 2. Act
      final subtitle = menuSubtitle(
        isAdmin: false,
        canWatch: true,
        canShare: true,
        shareTeams: const ['Centro'],
      );

      // 3. Assert
      expect(subtitle, 'Acompanha e compartilha');
    });

    test('Edge Case: an administrator wins even when they also share', () {
      // 1. Arrange / 2. Act
      final subtitle = menuSubtitle(
        isAdmin: true,
        canWatch: true,
        canShare: true,
        shareTeams: const ['Centro'],
      );

      // 3. Assert
      expect(subtitle, 'Administra a organização');
    });

    test('Edge Case: share only with several teams names the first +N', () {
      // 1. Arrange / 2. Act
      final subtitle = menuSubtitle(
        isAdmin: false,
        canWatch: false,
        canShare: true,
        shareTeams: const ['Centro', 'Zona Norte'],
      );

      // 3. Assert
      expect(subtitle, 'Centro +1 · em campo');
    });

    test('Sad Path: no capability and no team still reads sensibly', () {
      // 1. Arrange / 2. Act
      final subtitle = menuSubtitle(
        isAdmin: false,
        canWatch: false,
        canShare: false,
        shareTeams: const [],
      );

      // 3. Assert
      expect(subtitle, 'Sem equipe · em campo');
    });
  });
}
