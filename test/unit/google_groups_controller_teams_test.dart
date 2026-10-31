import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/organization_firebase.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';

Map<String, dynamic> groupEntity(String email) => {
  'type': 'GROUP',
  'email': email,
};

Map<String, dynamic> userEntity(String email) => {
  'type': 'USER',
  'email': email,
};

List<(String, String)> namesAndEmails(List<GoogleGroupModel> teams) => [
  for (final team in teams) (team.name, team.email),
];

GoogleGroupModel team(String email) => GoogleGroupModel(
  name: email,
  email: email,
  description: '',
  members: [],
  subgroups: [],
);

GoogleGroupModel namedTeam(String email, String name) => GoogleGroupModel(
  name: name,
  email: email,
  description: '',
  members: [],
  subgroups: [],
);

/// [OrganizationFirebase] whose signed-in user always has an ID token.
class FakeOrganizationFirebase implements OrganizationFirebase {
  @override
  FirebaseAuth get auth => FakeFirebaseAuth();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  FirebaseFunctions get functions => throw UnimplementedError();

  @override
  FirebaseStorage get storage => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get organizationData =>
      throw UnimplementedError();
}

class FakeFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUser implements User {
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The groups gateway: `/members?email=` answers [members] for the leaf
/// (500 when the leaf is in [failing] or unknown), optionally waiting on
/// [gate] first. Every asked e-mail goes to [asked].
class FakeGateway {
  final members = <String, List<Map<String, dynamic>>>{};
  final failing = <String>{};
  final asked = <String>[];
  Completer<void>? gate;

  late final client = MockClient((request) async {
    final email = request.url.queryParameters['email'] ?? '';
    asked.add(email);
    await gate?.future;
    final entities = members[email];
    if (failing.contains(email) || entities == null) {
      return http.Response('boom', 500);
    }
    return http.Response(jsonEncode({'members': entities}), 200);
  });

  /// Runs [body] with the controller's HTTP calls going to this gateway.
  R run<R>(R Function() body) => http.runWithClient(body, () => client);
}

/// A controller that is not started (no group load), with [teams] listed.
GoogleGroupsController controllerWith(List<GoogleGroupModel> teams) {
  final controller = GoogleGroupsController(onAccessLost: () async {});
  controller.googleGroups.addAll(teams);
  return controller;
}

/// Points Hive (the groups cache) at an empty temporary directory, so each
/// test starts with nothing cached. Returns a teardown.
Future<Future<void> Function()> freshGroupsCache() async {
  await Hive.close();
  final dir = Directory.systemTemp.createTempSync('groups_cache_');
  Hive.init(dir.path);
  return () async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  };
}

const centro = 'rotasul01@monamienet.org';
const norte = 'rotasul02@monamienet.org';
const sul = 'rotasul03@monamienet.org';

void main() {
  group('GoogleGroupsController.teamKeysOf - Unit Test Suite', () {
    test('Happy Path: the organization\'s team groups give their keys', () {
      // 1. Arrange
      final entities = [
        groupEntity('rotasul01@monamienet.org'),
        groupEntity('rotasul02@monamienet.org'),
      ];

      // 2. Act
      final keys = GoogleGroupsController.teamKeysOf('rotasul', entities);

      // 3. Assert
      expect(keys, ['rotasul01', 'rotasul02']);
    });

    test('Edge Case: mixed-case team e-mails give lowercase keys', () {
      // 1. Arrange
      final entities = [groupEntity('RotaSul03@MonAmieNet.org')];

      // 2. Act
      final keys = GoogleGroupsController.teamKeysOf('rotasul', entities);

      // 3. Assert
      expect(keys, ['rotasul03']);
    });

    test(
      'Sad Path: users, leaves, the root and other organizations are ignored',
      () {
        // 1. Arrange
        final entities = <Map<String, dynamic>>[
          userEntity('rotasul04@monamienet.org'),
          groupEntity('rotasul01r@monamienet.org'),
          groupEntity('rotasul01w@monamienet.org'),
          groupEntity('rotasul00@monamienet.org'),
          groupEntity('outro01@monamienet.org'),
          {'type': 'GROUP', 'email': 42},
          {'type': 'GROUP'},
          groupEntity('rotasul02@monamienet.org'),
        ];

        // 2. Act
        final keys = GoogleGroupsController.teamKeysOf('rotasul', entities);

        // 3. Assert
        expect(keys, ['rotasul02']);
      },
    );
  });

  group('GoogleGroupsController.teamsFor - Unit Test Suite', () {
    test('Happy Path: one team per key, in order, named from the names', () {
      // 1. Arrange
      final names = {'rotasul02': 'Zona Norte', 'rotasul01': 'Centro'};

      // 2. Act
      final teams = GoogleGroupsController.teamsFor([
        'rotasul01',
        'rotasul02',
      ], names);

      // 3. Assert
      expect(namesAndEmails(teams), [
        ('Centro', 'rotasul01@monamienet.org'),
        ('Zona Norte', 'rotasul02@monamienet.org'),
      ]);
    });

    test('Edge Case: no keys give no teams, whatever the names', () {
      // 1. Arrange
      final names = {'rotasul01': 'Centro'};

      // 2. Act
      final teams = GoogleGroupsController.teamsFor(const [], names);

      // 3. Assert
      expect(teams, isEmpty);
    });

    test('Edge Case: a name for a key not asked for adds no team', () {
      // 1. Arrange
      final names = {'rotasul01': 'Centro', 'rotasul09': 'Outra'};

      // 2. Act
      final teams = GoogleGroupsController.teamsFor(['rotasul01'], names);

      // 3. Assert
      expect(namesAndEmails(teams), [('Centro', 'rotasul01@monamienet.org')]);
    });

    test('Sad Path: a team with no name falls back to "Equipe NN"', () {
      // 1. Arrange
      final names = {'rotasul01': 'Centro'};

      // 2. Act
      final teams = GoogleGroupsController.teamsFor([
        'rotasul01',
        'rotasul07',
      ], names);

      // 3. Assert
      expect(namesAndEmails(teams), [
        ('Centro', 'rotasul01@monamienet.org'),
        ('Equipe 07', 'rotasul07@monamienet.org'),
      ]);
    });

    test('Sad Path: no names at all name every team "Equipe NN"', () {
      // 1. Arrange
      const names = <String, String>{};

      // 2. Act
      final teams = GoogleGroupsController.teamsFor([
        'rotasul12',
        'rotasul03',
      ], names);

      // 3. Assert
      expect(namesAndEmails(teams), [
        ('Equipe 12', 'rotasul12@monamienet.org'),
        ('Equipe 03', 'rotasul03@monamienet.org'),
      ]);
    });
  });

  group('GoogleGroupsController.shareLeafEmail - Unit Test Suite', () {
    final cases = <(String, String, String)>[
      (
        'Happy Path: a team gives its share leaf',
        'rotasul01@monamienet.org',
        'rotasul01w@monamienet.org',
      ),
      (
        'Edge Case: a mixed-case team gives a lowercase leaf',
        'RotaSul02@MonAmieNet.org',
        'rotasul02w@monamienet.org',
      ),
      (
        'Sad Path: an unparsable address is returned unchanged',
        'ti-suporte@monamienet.org',
        'ti-suporte@monamienet.org',
      ),
    ];
    for (final (label, input, expected) in cases) {
      test('$label ("$input")', () {
        // 1. Arrange
        final teamEmail = input;

        // 2. Act
        final leaf = GoogleGroupsController.shareLeafEmail(teamEmail);

        // 3. Assert
        expect(leaf, expected);
      });
    }
  });

  group('GoogleGroupsController.teamToObserve - Unit Test Suite', () {
    test('Happy Path: nothing observed yet opens on the first team', () {
      // 1. Arrange
      final teams = [
        team('rotasul01@monamienet.org'),
        team('rotasul02@monamienet.org'),
      ];

      // 2. Act
      final next = GoogleGroupsController.teamToObserve(teams, null);

      // 3. Assert
      expect(next, same(teams.first));
    });

    test('Edge Case: an observed team that is still listed stays', () {
      // 1. Arrange
      final teams = [
        team('rotasul01@monamienet.org'),
        team('rotasul02@monamienet.org'),
      ];

      // 2. Act
      final next = GoogleGroupsController.teamToObserve(teams, teams.last);

      // 3. Assert
      expect(next, isNull);
    });

    test('Edge Case: the observed team is matched by e-mail, not identity', () {
      // 1. Arrange
      final teams = [
        team('rotasul01@monamienet.org'),
        team('rotasul02@monamienet.org'),
      ];
      final current = team('rotasul02@monamienet.org');

      // 2. Act
      final next = GoogleGroupsController.teamToObserve(teams, current);

      // 3. Assert
      expect(next, isNull);
    });

    test('Edge Case: an observed team that is gone falls to the first', () {
      // 1. Arrange
      final teams = [
        team('rotasul01@monamienet.org'),
        team('rotasul02@monamienet.org'),
      ];
      final current = team('rotasul09@monamienet.org');

      // 2. Act
      final next = GoogleGroupsController.teamToObserve(teams, current);

      // 3. Assert
      expect(next, same(teams.first));
    });

    test('Sad Path: no teams leave the map as it is', () {
      // 1. Arrange / 2. Act
      final next = GoogleGroupsController.teamToObserve(const [], null);

      // 3. Assert
      expect(next, isNull);
    });

    test('Sad Path: no teams do not switch away from the observed one', () {
      // 1. Arrange
      final current = team('rotasul01@monamienet.org');

      // 2. Act
      final next = GoogleGroupsController.teamToObserve(const [], current);

      // 3. Assert
      expect(next, isNull);
    });
  });

  group('GoogleGroupsController.organizationTeams - Unit Test Suite', () {
    test(
      'Happy Path: every team of the organization, in team order, named',
      () {
        // 1. Arrange
        final names = {
          'rotasul13': 'Zona Sul',
          'rotasul01': 'Centro',
          'rotasul02': 'Zona Norte',
        };

        // 2. Act
        final teams = GoogleGroupsController.organizationTeams(
          'rotasul',
          names,
        );

        // 3. Assert
        expect(namesAndEmails(teams), [
          ('Centro', 'rotasul01@monamienet.org'),
          ('Zona Norte', 'rotasul02@monamienet.org'),
          ('Zona Sul', 'rotasul13@monamienet.org'),
        ]);
      },
    );

    test('Edge Case: no names give no teams', () {
      // 1. Arrange
      const names = <String, String>{};

      // 2. Act
      final teams = GoogleGroupsController.organizationTeams('rotasul', names);

      // 3. Assert
      expect(teams, isEmpty);
    });

    test('Edge Case: a name with surrounding spaces is trimmed', () {
      // 1. Arrange
      final names = {'rotasul04': '  Zona Oeste \t'};

      // 2. Act
      final teams = GoogleGroupsController.organizationTeams('rotasul', names);

      // 3. Assert
      expect(namesAndEmails(teams), [
        ('Zona Oeste', 'rotasul04@monamienet.org'),
      ]);
    });

    test('Sad Path: a blank name falls back to "Equipe NN"', () {
      // 1. Arrange
      final names = {'rotasul04': ''};

      // 2. Act
      final teams = GoogleGroupsController.organizationTeams('rotasul', names);

      // 3. Assert
      expect(namesAndEmails(teams), [
        ('Equipe 04', 'rotasul04@monamienet.org'),
      ]);
    });

    test('Sad Path: a whitespace-only name falls back to "Equipe NN"', () {
      // 1. Arrange
      final names = {'rotasul05': ' \t\n '};

      // 2. Act
      final teams = GoogleGroupsController.organizationTeams('rotasul', names);

      // 3. Assert
      expect(namesAndEmails(teams), [
        ('Equipe 05', 'rotasul05@monamienet.org'),
      ]);
    });

    test(
      'Sad Path: other organizations, the root, leaves and non-team keys are '
      'skipped',
      () {
        // 1. Arrange
        final names = {
          'outro01': 'Outra organização',
          'rota01': 'Prefixo da organização',
          'rotasulx01': 'Organização mais longa',
          'rotasul00': 'Administração',
          'rotasul01r': 'Leitura',
          'rotasul01w': 'Envio',
          'RotaSul05': 'Maiúsculas',
          'rotasul1': 'Um dígito',
          'rotasul123': 'Três dígitos',
          'rotasul02@monamienet.org': 'E-mail completo',
          '': 'Vazio',
          'rotasul03': 'Centro',
        };

        // 2. Act
        final teams = GoogleGroupsController.organizationTeams(
          'rotasul',
          names,
        );

        // 3. Assert
        expect(namesAndEmails(teams), [('Centro', 'rotasul03@monamienet.org')]);
      },
    );
  });

  group('GoogleGroupsController.renamedSelection - Unit Test Suite', () {
    test('Happy Path: the observed team with a new name is returned as it '
        'is now', () {
      // 1. Arrange
      final teams = [
        namedTeam(centro, 'Centro'),
        namedTeam(norte, 'Zona Norte Nova'),
      ];
      final current = namedTeam(norte, 'Zona Norte');

      // 2. Act
      final renamed = GoogleGroupsController.renamedSelection(teams, current);

      // 3. Assert
      expect(renamed, same(teams.last));
    });

    test('Edge Case: the observed team with the same name gives null', () {
      // 1. Arrange
      final teams = [namedTeam(centro, 'Centro'), namedTeam(norte, 'Norte')];
      final current = namedTeam(norte, 'Norte');

      // 2. Act
      final renamed = GoogleGroupsController.renamedSelection(teams, current);

      // 3. Assert
      expect(renamed, isNull);
    });

    test('Edge Case: nothing observed gives null', () {
      // 1. Arrange
      final teams = [namedTeam(centro, 'Centro')];

      // 2. Act
      final renamed = GoogleGroupsController.renamedSelection(teams, null);

      // 3. Assert
      expect(renamed, isNull);
    });

    test('Sad Path: an observed team that is gone gives null', () {
      // 1. Arrange
      final teams = [namedTeam(centro, 'Centro'), namedTeam(norte, 'Norte')];
      final current = namedTeam(sul, 'Sul');

      // 2. Act
      final renamed = GoogleGroupsController.renamedSelection(teams, current);

      // 3. Assert
      expect(renamed, isNull);
    });

    test('Sad Path: no teams give null even with a team observed', () {
      // 1. Arrange
      final current = namedTeam(centro, 'Centro');

      // 2. Act
      final renamed = GoogleGroupsController.renamedSelection(
        const [],
        current,
      );

      // 3. Assert
      expect(renamed, isNull);
    });
  });

  group('GoogleGroupsController.pickTeam - Unit Test Suite', () {
    late FakeGateway gateway;

    late Future<void> Function() closeCache;

    setUp(() async {
      Get.testMode = true;
      closeCache = await freshGroupsCache();
      CurrentOrganizationFirebase.set(FakeOrganizationFirebase());
      gateway = FakeGateway()
        ..members['rotasul01w@monamienet.org'] = [userEntity('a@x.org')]
        ..members['rotasul02w@monamienet.org'] = [userEntity('b@x.org')];
    });

    tearDown(() async {
      CurrentOrganizationFirebase.debugReset();
      await closeCache();
    });

    test('Happy Path: the picked team becomes the observed one', () async {
      // 1. Arrange
      final picked = team(norte);
      final controller = controllerWith([team(centro), picked]);
      controller.selectedGroup.value = team(centro);

      // 2. Act
      await gateway.run(() => controller.pickTeam(picked));

      // 3. Assert
      expect(controller.selectedGroup.value?.email, norte);
    });

    test('Happy Path: switchingTeam is true while the people load', () async {
      // 1. Arrange
      gateway.gate = Completer<void>();
      final controller = controllerWith([team(centro), team(norte)]);

      // 2. Act
      final pending = gateway.run(() => controller.pickTeam(team(norte)));

      // 3. Assert
      expect(controller.switchingTeam.value, isTrue);
      gateway.gate!.complete();
      await pending;
    });

    test('Happy Path: switchingTeam is false once the people load', () async {
      // 1. Arrange
      final controller = controllerWith([team(centro), team(norte)]);

      // 2. Act
      await gateway.run(() => controller.pickTeam(team(norte)));

      // 3. Assert
      expect(controller.switchingTeam.value, isFalse);
    });

    test('Sad Path: switchingTeam is false after loading fails', () async {
      // 1. Arrange
      gateway.failing.add('rotasul02w@monamienet.org');
      final controller = controllerWith([team(centro), team(norte)]);

      // 2. Act
      await gateway.run(() => controller.pickTeam(team(norte)));

      // 3. Assert
      expect(controller.switchingTeam.value, isFalse);
    });

    test('Edge Case: picking the observed team does nothing', () async {
      // 1. Arrange
      final controller = controllerWith([team(centro), team(norte)]);
      final observed = team(centro);
      controller.selectedGroup.value = observed;

      // 2. Act
      await gateway.run(() => controller.pickTeam(team(centro)));

      // 3. Assert
      expect(
        [controller.selectedGroup.value, gateway.asked],
        [same(observed), isEmpty],
      );
    });

    test('Edge Case: a pick while another is in flight is ignored', () async {
      // 1. Arrange
      gateway.gate = Completer<void>();
      final controller = controllerWith([team(centro), team(norte)]);
      final first = gateway.run(() => controller.pickTeam(team(norte)));

      // 2. Act
      final second = gateway.run(() => controller.pickTeam(team(centro)));

      // 3. Assert
      gateway.gate!.complete();
      await Future.wait([first, second]);
      expect(
        [controller.selectedGroup.value?.email, gateway.asked],
        [
          norte,
          ['rotasul02w@monamienet.org'],
        ],
      );
    });
  });

  group('GoogleGroupsController.loadTeamSizes - Unit Test Suite', () {
    late FakeGateway gateway;

    late Future<void> Function() closeCache;

    setUp(() async {
      Get.testMode = true;
      closeCache = await freshGroupsCache();
      CurrentOrganizationFirebase.set(FakeOrganizationFirebase());
      gateway = FakeGateway();
    });

    tearDown(() async {
      CurrentOrganizationFirebase.debugReset();
      await closeCache();
    });

    test('Happy Path: each team counts the USER entries of its share '
        'leaf', () async {
      // 1. Arrange
      gateway
        ..members['rotasul01w@monamienet.org'] = [
          userEntity('a@x.org'),
          userEntity('b@x.org'),
          groupEntity('rotasul09@monamienet.org'),
        ]
        ..members['rotasul02w@monamienet.org'] = [userEntity('c@x.org')];
      final controller = controllerWith([team(centro), team(norte)]);

      // 2. Act
      await gateway.run(controller.loadTeamSizes);

      // 3. Assert
      expect(controller.teamSizes, {centro: 2, norte: 1});
    });

    test('Edge Case: a share leaf with no people counts 0', () async {
      // 1. Arrange
      gateway.members['rotasul01w@monamienet.org'] = [
        groupEntity('rotasul09@monamienet.org'),
      ];
      final controller = controllerWith([team(centro)]);

      // 2. Act
      await gateway.run(controller.loadTeamSizes);

      // 3. Assert
      expect(controller.teamSizes, {centro: 0});
    });

    test('Sad Path: a team whose lookup fails gets no entry while the '
        'others do', () async {
      // 1. Arrange
      gateway
        ..members['rotasul01w@monamienet.org'] = [userEntity('a@x.org')]
        ..failing.add('rotasul02w@monamienet.org')
        ..members['rotasul03w@monamienet.org'] = [
          userEntity('b@x.org'),
          userEntity('c@x.org'),
        ];
      final controller = controllerWith([team(centro), team(norte), team(sul)]);

      // 2. Act
      await gateway.run(controller.loadTeamSizes);

      // 3. Assert
      expect(controller.teamSizes, {centro: 1, sul: 2});
    });
  });
}
