import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';

/// A complete invite as `myInvites` returns it.
Map<String, Object?> _inviteJson([Map<String, Object?> overrides = const {}]) =>
    {
      'id': 'inv1',
      'organizationId': 'rotasul',
      'organizationName': 'Rota Sul',
      'groupId': '01',
      'groupName': 'Equipe Norte',
      'email': 'davi@x.com',
      'roles': ['publisher', 'subscriber'],
      'inviterName': 'Rita Lima',
      'expiresAt': '2026-11-09T12:00:00.000Z',
      ...overrides,
    };

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));
  final en = lookupAppLocalizations(const Locale('en'));

  // The ARB dates are formatted by `intl`, whose month names Flutter loads
  // with the Material delegate; a unit test has no delegate, so it loads them.
  setUpAll(() async {
    await initializeDateFormatting('pt');
    await initializeDateFormatting('en');
  });

  group('DomainLabels.roleName - Unit Test Suite', () {
    final cases = <(String, GroupRole, String)>[
      ('Happy Path: publisher', GroupRole.publisher, 'Em campo'),
      ('Happy Path: subscriber', GroupRole.subscriber, 'Vê o mapa'),
      ('Happy Path: maintainer', GroupRole.maintainer, 'Gestor do grupo'),
    ];
    for (final (label, role, expected) in cases) {
      test('$label reads "$expected"', () {
        // 1. Arrange
        final input = role;

        // 2. Act
        final text = pt.roleName(input);

        // 3. Assert
        expect(text, expected);
      });
    }

    test('Edge Case: every role has its own English name', () {
      // 1. Arrange
      const roles = GroupRole.values;

      // 2. Act
      final names = {for (final role in roles) en.roleName(role)};

      // 3. Assert
      expect(names, hasLength(roles.length));
      expect(names, isNot(contains('Em campo')));
    });
  });

  group('DomainLabels.roleDescription - Unit Test Suite', () {
    final cases = <(String, GroupRole, String)>[
      (
        'Happy Path: publisher',
        GroupRole.publisher,
        'Compartilha a própria localização',
      ),
      ('Happy Path: subscriber', GroupRole.subscriber, 'Vê quem está em campo'),
      (
        'Happy Path: maintainer',
        GroupRole.maintainer,
        'Cuida das pessoas e dos convites do grupo',
      ),
    ];
    for (final (label, role, expected) in cases) {
      test('$label reads "$expected"', () {
        // 1. Arrange
        final input = role;

        // 2. Act
        final text = pt.roleDescription(input);

        // 3. Assert
        expect(text, expected);
      });
    }
  });

  group('DomainLabels.rolesLabel - Unit Test Suite', () {
    final cases = <(String, Set<GroupRole>, String)>[
      (
        'Happy Path: both roles in GroupRole order',
        {GroupRole.subscriber, GroupRole.publisher},
        'Em campo · Vê o mapa',
      ),
      ('Edge Case: only Em campo', {GroupRole.publisher}, 'Em campo'),
      ('Edge Case: only Vê o mapa', {GroupRole.subscriber}, 'Vê o mapa'),
      ('Sad Path: no roles give empty text', <GroupRole>{}, ''),
    ];
    for (final (label, input, expected) in cases) {
      test('$label reads "$expected"', () {
        // 1. Arrange
        final roles = input;

        // 2. Act
        final text = pt.rolesLabel(roles);

        // 3. Assert
        expect(text, expected);
      });
    }

    test('Happy Path: an invite read out of order lists Em campo first', () {
      // 1. Arrange
      final invite = Invite.fromJson(
        _inviteJson({
          'roles': ['subscriber', 'publisher'],
        }),
      )!;

      // 2. Act
      final text = pt.rolesLabel(invite.roles);

      // 3. Assert
      expect(text, 'Em campo · Vê o mapa');
    });
  });

  group('AppLocalizations.peopleCount - Unit Test Suite', () {
    final cases = {
      0: 'Ninguém ainda', // Edge Case: nobody
      1: '1 pessoa', // Edge Case: singular
      3: '3 pessoas', // Happy Path: plural
    };
    for (final MapEntry(key: count, value: expected) in cases.entries) {
      final kind = switch (count) {
        3 => 'Happy Path',
        _ => 'Edge Case',
      };
      test('$kind: a group of $count people reads "$expected"', () {
        // 1. Arrange
        final team = Group(
          id: 'g1',
          name: 'Equipe Norte',
          people: [
            for (var i = 0; i < count; i++)
              GroupPerson(email: 'p$i@x.com', roles: {GroupRole.publisher}),
          ],
        );

        // 2. Act
        final label = pt.peopleCount(team.people.length);

        // 3. Assert
        expect(label, expected);
      });
    }
  });

  group('DomainLabels.pendingInvitesLabel - Unit Test Suite', () {
    final cases = <(String, int, String)>[
      ('Happy Path: plural', 3, '3 convites pendentes'),
      ('Edge Case: singular', 1, '1 convite pendente'),
      ('Edge Case: none', 0, ''),
      ('Sad Path: a negative count reads as none', -1, ''),
    ];
    for (final (label, count, expected) in cases) {
      test('$label ($count) reads "$expected"', () {
        // 1. Arrange
        final input = count;

        // 2. Act
        final text = pt.pendingInvitesLabel(input);

        // 3. Assert
        expect(text, expected);
      });
    }
  });

  group('DomainLabels.groupDeletionLines - Unit Test Suite', () {
    const lastLine =
        'Os trajetos publicados neste grupo são apagados junto. Não dá para '
        'desfazer.';

    test('Happy Path: plural counts give one line each, in order', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = pt.groupDeletionLines(
        loses: 3,
        stays: 2,
        invites: 4,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [
        '3 pessoas só estavam neste grupo e perdem o acesso à Rota Sul.',
        '2 pessoas continuam nos outros grupos.',
        'Os 4 convites pendentes são cancelados.',
        lastLine,
      ]);
    });

    test('Edge Case: counts of one use the singular', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = pt.groupDeletionLines(
        loses: 1,
        stays: 1,
        invites: 1,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [
        '1 pessoa só estava neste grupo e perde o acesso à Rota Sul.',
        '1 pessoa continua nos outros grupos.',
        'O convite pendente é cancelado.',
        lastLine,
      ]);
    });

    test('Edge Case: zero counts leave only the last line', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = pt.groupDeletionLines(
        loses: 0,
        stays: 0,
        invites: 0,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [lastLine]);
    });

    test('Sad Path: negative counts are left out', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = pt.groupDeletionLines(
        loses: -1,
        stays: -2,
        invites: -3,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [lastLine]);
    });
  });

  group('DomainLabels.deletedGroupText - Unit Test Suite', () {
    const stays = 'Quem estava em outros grupos continua neles.';
    final cases = <(String, int, String)>[
      (
        'Happy Path: plural',
        3,
        '3 pessoas perderam o acesso à Rota Sul. $stays',
      ),
      ('Edge Case: singular', 1, '1 pessoa perdeu o acesso à Rota Sul. $stays'),
      ('Edge Case: nobody lost access', 0, stays),
      ('Sad Path: a negative count reads as nobody', -2, stays),
    ];
    for (final (label, loses, expected) in cases) {
      test('$label ($loses)', () {
        // 1. Arrange
        const organization = 'Rota Sul';

        // 2. Act
        final text = pt.deletedGroupText(
          loses: loses,
          organization: organization,
        );

        // 3. Assert
        expect(text, expected);
      });
    }
  });

  group('DomainLabels.inviteStatus - Unit Test Suite', () {
    final cases = <(String, Map<String, Object?>, String)>[
      (
        'Happy Path: a valid invite shows its last day',
        {'expiresAt': '2026-11-09T12:00:00.000'},
        'Vale até 9 de novembro',
      ),
      (
        'Happy Path: an expired invite shows the day it expired',
        {'expiresAt': '2026-11-09T12:00:00.000', 'expired': true},
        'Expirado · venceu em 9 de novembro',
      ),
      (
        'Edge Case: an expired invite without a date',
        {'expiresAt': null, 'expired': true},
        'Expirado',
      ),
      (
        'Edge Case: a valid invite without a date is empty',
        {'expiresAt': null},
        '',
      ),
      (
        'Sad Path: an expired flag that is not true reads as valid',
        {'expiresAt': '2026-11-09T12:00:00.000', 'expired': 'true'},
        'Vale até 9 de novembro',
      ),
    ];
    for (final (label, overrides, expected) in cases) {
      test('$label ("$expected")', () {
        // 1. Arrange
        final invite = Invite.fromJson(_inviteJson(overrides))!;

        // 2. Act
        final text = pt.inviteStatus(invite);

        // 3. Assert
        expect(text, expected);
      });
    }

    test('Edge Case: a UTC instant is shown on its local day', () {
      // 1. Arrange
      // Half past midnight local on 1 March, as UTC: the local day must win
      // whatever the machine's time zone.
      final local = DateTime(2026, 3, 1, 0, 30);
      final invite = Invite.fromJson(
        _inviteJson({'expiresAt': local.toUtc().toIso8601String()}),
      )!;

      // 2. Act
      final text = pt.inviteStatus(invite);

      // 3. Assert
      expect(text, 'Vale até 1 de março');
    });
  });

  group('Invite dates (MMMMd) - Unit Test Suite', () {
    test('Happy Path: Nov 9 2026 is "9 de novembro"', () {
      // 1. Arrange
      final date = DateTime(2026, 11, 9);

      // 2. Act
      final text = pt.inviteValidUntil(date);

      // 3. Assert
      expect(text, 'Vale até 9 de novembro');
    });

    test('Edge Case: the first and last months use their names', () {
      // 1. Arrange
      final dates = [DateTime(2027, 1, 1), DateTime(2026, 12, 31)];

      // 2. Act
      final texts = dates.map(pt.inviteValidUntil).toList();

      // 3. Assert
      expect(texts, ['Vale até 1 de janeiro', 'Vale até 31 de dezembro']);
    });

    test('Happy Path: English writes the month first', () {
      // 1. Arrange
      final date = DateTime(2026, 11, 9);

      // 2. Act
      final text = en.inviteValidUntil(date);

      // 3. Assert
      expect(text, contains('November 9'));
    });
  });

  group('Deletion dates (yMMMMd) - Unit Test Suite', () {
    final cases = <(String, DateTime, String)>[
      (
        'Happy Path: a date is written out in Portuguese',
        DateTime(2026, 11, 25, 12),
        '25 de novembro de 2026',
      ),
      (
        'Edge Case: March is spelled with its cedilla',
        DateTime(2026, 3, 1, 0, 30),
        '1 de março de 2026',
      ),
      (
        'Edge Case: December is the last month',
        DateTime(2026, 12, 31, 23, 59),
        '31 de dezembro de 2026',
      ),
    ];
    for (final (label, date, expected) in cases) {
      test('$label ("$expected")', () {
        // 1. Arrange
        final input = date;

        // 2. Act
        final text = pt.deletionPendingAccountBody(input);

        // 3. Assert
        expect(
          text,
          'Em $expected apagamos de vez sua conta e seus dados no MonAmie.',
        );
      });
    }
  });

  group('Days left (plural) - Unit Test Suite', () {
    final cases = <String, (int, String)>{
      'Happy Path: several days': (30, 'em 30 dias'),
      'Edge Case: one day is singular': (1, 'em 1 dia'),
      'Edge Case: zero days is today': (0, 'hoje'),
      'Edge Case: two days are plural': (2, 'em 2 dias'),
    };
    for (final MapEntry(key: label, value: (days, expected)) in cases.entries) {
      test(label, () {
        // 1. Arrange
        final input = days;

        // 2. Act
        final text = pt.deletionPendingAccountTitle(input);

        // 3. Assert
        expect(text, 'Sua conta será excluída $expected');
      });
    }
  });

  group('DomainLabels.presetName - Unit Test Suite', () {
    final cases = <(String, TrackingPreset, String)>[
      ('Happy Path: economia', TrackingPreset.economia, 'Economia'),
      ('Happy Path: equilibrio', TrackingPreset.equilibrio, 'Equilíbrio'),
      ('Happy Path: precisao', TrackingPreset.precisao, 'Precisão'),
      (
        'Edge Case: personalizado',
        TrackingPreset.personalizado,
        'Personalizado',
      ),
    ];
    for (final (label, preset, expected) in cases) {
      test('$label reads "$expected"', () {
        // 1. Arrange
        final input = preset;

        // 2. Act
        final text = pt.presetName(input);

        // 3. Assert
        expect(text, expected);
      });
    }
  });
}
