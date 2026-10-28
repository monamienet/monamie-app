import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';
import 'package:monamie_app/app/data/theme/theme_catalog.dart';
import 'package:monamie_app/app/modules/creation/create_organization_controller.dart';
import 'package:monamie_app/app/modules/creation/creation_backend.dart';

const _white = Color(0xFFFFFFFF);

PartnerTheme _theme(String id, int order, {bool active = true}) => PartnerTheme(
  id: id,
  name: id,
  primary: const Color(0xFF0B7F7B),
  dark: const Color(0xFF0A3D3B),
  light: const Color(0xFFD3EEEC),
  onPrimary: _white,
  onDark: _white,
  order: order,
  active: active,
);

final sol = _theme('sol', 0);
final lava = _theme('lava', 1, active: false);
final oceano = _theme('oceano', 2);

/// One `create` call as the fake recorded it.
typedef CreateCall = ({String id, String name, String themeId, String plan});

/// [CreationBackend] answering `idProblem` from [problems] (or waiting on
/// a per-id completer in [pendingChecks]) and recording `create`, which
/// optionally waits on [gate] and fails with [failure].
class FakeCreationBackend implements CreationBackend {
  final checks = <String>[];
  final problems = <String, String>{};
  final pendingChecks = <String, Completer<String?>>{};
  final creates = <CreateCall>[];
  String status = 'active';
  Completer<void>? gate;
  Object? failure;

  @override
  Future<String?> idProblem(String id) async {
    checks.add(id);
    if (pendingChecks[id] case final pending?) return pending.future;
    return problems[id];
  }

  @override
  Future<String> create({
    required String id,
    required String name,
    required String themeId,
    required String plan,
  }) async {
    creates.add((id: id, name: name, themeId: themeId, plan: plan));
    await gate?.future;
    if (failure case final failure?) throw failure;
    return status;
  }

  @override
  Future<List<Creation>> mine() => throw UnimplementedError();
}

/// [ThemeCatalog] returning [catalog], or throwing when [failing].
class FakeThemeCatalog implements ThemeCatalog {
  FakeThemeCatalog({this.failing = false});

  final bool failing;

  @override
  Future<Map<String, PartnerTheme>> themes() async {
    if (failing) throw Exception('catalog unavailable');
    return {
      for (final t in [oceano, lava, defaultPartnerTheme, sol]) t.id: t,
    };
  }
}

late FakeCreationBackend backend;

CreateOrganizationController startedController({ThemeCatalog? themes}) =>
    CreateOrganizationController(
      backend: backend,
      themes: themes ?? FakeThemeCatalog(),
      debounce: Duration.zero,
    )..onStart();

/// Lets the debounce timer fire and the fake answers resolve.
Future<void> settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

/// A started controller with name "Rota Sul" and id "rotasul" available.
Future<CreateOrganizationController> readyController() async {
  final controller = startedController();
  controller.setName('Rota Sul');
  await settle();
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = FakeCreationBackend();
  });

  group('suggestPartnerId - Unit Test Suite', () {
    final cases = [
      ('Happy Path', 'Rota Sul Turismo', 'rotasulturismo'),
      ('Edge Case', 'São João 2', 'saojoao'),
      ('Edge Case', 'abcdefghij klmnopqrst uvwxy', 'abcdefghijklmnopqrst'),
      ('Sad Path', '123 - !!', ''),
    ];
    for (final (label, name, expected) in cases) {
      test('$label: "$name" suggests "$expected"', () {
        // 1. Arrange
        final input = name;

        // 2. Act
        final id = suggestPartnerId(input);

        // 3. Assert
        expect(id, expected);
      });
    }
  });

  group('idFormatProblem - Unit Test Suite', () {
    for (final (label, id) in [
      ('Happy Path', 'rotasul'),
      ('Edge Case', 'abc'),
      ('Edge Case', 'abcdefghijklmnopqrst'),
    ]) {
      test('$label: "$id" has no problem', () {
        // 1. Arrange
        final candidate = id;

        // 2. Act
        final problem = idFormatProblem(candidate);

        // 3. Assert
        expect(problem, isNull);
      });
    }

    for (final id in ['', 'ab']) {
      test('Sad Path: "$id" asks for at least 3 letters', () {
        // 1. Arrange
        final candidate = id;

        // 2. Act
        final problem = idFormatProblem(candidate);

        // 3. Assert
        expect(problem, 'Mínimo 3 letras');
      });
    }

    for (final (why, id) in [
      ('a digit', 'rotasul1'),
      ('upper case', 'RotaSul'),
      ('an accent', 'rotaçul'),
      ('a space', 'rota sul'),
      ('a hyphen', 'rota-sul'),
      ('21 letters', 'abcdefghijklmnopqrstu'),
      ('reserved app', 'app'),
      ('reserved community', 'community'),
    ]) {
      test('Sad Path: $why has its own problem', () {
        // 1. Arrange
        final candidate = id;

        // 2. Act
        final problem = idFormatProblem(candidate);

        // 3. Assert
        expect(problem, isNotNull);
        expect(problem, isNot('Mínimo 3 letras'));
      });
    }
  });

  group('CreateOrganizationController (id suggestion) - Unit Test Suite', () {
    test('Happy Path: the name suggests the id', () {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      controller.setName('Rota Sul');

      // 3. Assert
      expect(controller.id.value, 'rotasul');
    });

    test('Edge Case: every name change suggests again', () {
      // 1. Arrange
      final controller = startedController()..setName('Rota');

      // 2. Act
      controller.setName('Rota Sul');

      // 3. Assert
      expect(controller.id.value, 'rotasul');
    });

    test('Sad Path: after the id is edited the name no longer changes it', () {
      // 1. Arrange
      final controller = startedController()
        ..setName('Rota Sul')
        ..setId('rsul');

      // 2. Act
      controller.setName('Rota Sul Turismo');

      // 3. Assert
      expect(controller.id.value, 'rsul');
    });
  });

  group('CreateOrganizationController (id check) - Unit Test Suite', () {
    test('Happy Path: a valid id is checking right away', () {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      controller.setId('rotasul');

      // 3. Assert
      expect(controller.idCheck.value, IdCheck.checking);
    });

    test(
      'Happy Path: a free id becomes available after the debounce',
      () async {
        // 1. Arrange
        final controller = startedController()..setId('rotasul');

        // 2. Act
        await settle();

        // 3. Assert
        expect(controller.idCheck.value, IdCheck.available);
        expect(backend.checks, ['rotasul']);
      },
    );

    test(
      'Sad Path: a taken id becomes unavailable with the backend problem',
      () async {
        // 1. Arrange
        backend.problems['rotasul'] = 'Esse identificador já está em uso.';
        final controller = startedController()..setId('rotasul');

        // 2. Act
        await settle();

        // 3. Assert
        expect(controller.idCheck.value, IdCheck.unavailable);
        expect(
          controller.idProblem.value,
          'Esse identificador já está em uso.',
        );
      },
    );

    test(
      'Sad Path: a bad format is unavailable without asking the backend',
      () async {
        // 1. Arrange
        final controller = startedController();

        // 2. Act
        controller.setId('Rota Sul');
        await settle();

        // 3. Assert
        expect(controller.idCheck.value, IdCheck.unavailable);
        expect(controller.idProblem.value, isNotEmpty);
        expect(backend.checks, isEmpty);
      },
    );

    test(
      'Edge Case: an answer for an id changed meanwhile is ignored',
      () async {
        // 1. Arrange
        backend.pendingChecks['rotasul'] = Completer<String?>();
        backend.pendingChecks['rotanorte'] = Completer<String?>();
        final controller = startedController()..setId('rotasul');
        await settle();
        controller.setId('rotanorte');
        await settle();

        // 2. Act
        backend.pendingChecks['rotasul']!.complete(null);
        await settle();

        // 3. Assert
        expect(controller.idCheck.value, IdCheck.checking);
      },
    );
  });

  group(
    'CreateOrganizationController (canContinueFromName) - Unit Test Suite',
    () {
      for (final (label, name, expected) in [
        ('Happy Path', 'Rota Sul', true),
        ('Edge Case', 'Ri', true),
        ('Edge Case', 'a' * 40, true),
        ('Edge Case', '  Rota Sul  ', true),
        ('Sad Path', 'R', false),
        ('Sad Path', 'a' * 41, false),
        ('Sad Path', 'MonAmie Sul', false),
        ('Sad Path', 'monamie sul', false),
      ]) {
        test(
          '$label: name "$name" with an available id -> $expected',
          () async {
            // 1. Arrange
            final controller = startedController()..setId('rotasul');
            await settle();

            // 2. Act
            controller.setName(name);

            // 3. Assert
            expect(controller.canContinueFromName, expected);
          },
        );
      }

      test(
        'Sad Path: a valid name with the id still checking cannot continue',
        () {
          // 1. Arrange
          final controller = startedController()..setName('Rota Sul');

          // 2. Act
          final canContinue = controller.canContinueFromName;

          // 3. Assert
          expect(canContinue, isFalse);
        },
      );

      test(
        'Sad Path: a valid name with an unavailable id cannot continue',
        () async {
          // 1. Arrange
          backend.problems['rotasul'] = 'Esse identificador já está em uso.';
          final controller = startedController()..setName('Rota Sul');
          await settle();

          // 2. Act
          final canContinue = controller.canContinueFromName;

          // 3. Assert
          expect(canContinue, isFalse);
        },
      );
    },
  );

  group('CreateOrganizationController (create) - Unit Test Suite', () {
    test('Happy Path: sends id, trimmed name, theme and plan', () async {
      // 1. Arrange
      final controller = startedController()..setName('  Rota Sul  ');
      await settle();
      controller.themeId.value = 'oceano';
      controller.plan.value = 'standard';

      // 2. Act
      await controller.create();

      // 3. Assert
      expect(backend.creates, [
        (id: 'rotasul', name: 'Rota Sul', themeId: 'oceano', plan: 'standard'),
      ]);
    });

    test('Happy Path: returns true and keeps the returned status', () async {
      // 1. Arrange
      backend.status = 'awaiting_billing';
      final controller = await readyController();

      // 2. Act
      final ok = await controller.create();

      // 3. Assert
      expect(ok, isTrue);
      expect(controller.result.value, 'awaiting_billing');
    });

    test('Happy Path: isCreating resets after success', () async {
      // 1. Arrange
      final controller = await readyController();

      // 2. Act
      await controller.create();

      // 3. Assert
      expect(controller.isCreating.value, isFalse);
    });

    test('Edge Case: isCreating is true while the call is in flight', () async {
      // 1. Arrange
      backend.gate = Completer<void>();
      final controller = await readyController();

      // 2. Act
      final pending = controller.create();

      // 3. Assert
      expect(controller.isCreating.value, isTrue);
      backend.gate!.complete();
      await pending;
    });

    test(
      'Edge Case: a second create while one is in flight is refused',
      () async {
        // 1. Arrange
        backend.gate = Completer<void>();
        final controller = await readyController();
        final first = controller.create();

        // 2. Act
        final second = await controller.create();

        // 3. Assert
        expect(second, isFalse);
        expect(backend.creates, hasLength(1));
        backend.gate!.complete();
        await first;
      },
    );

    test(
      'Sad Path: a CreationException returns false with its message',
      () async {
        // 1. Arrange
        backend.failure = const CreationException(
          'Esse identificador já está em uso.',
        );
        final controller = await readyController();

        // 2. Act
        final ok = await controller.create();

        // 3. Assert
        expect(ok, isFalse);
        expect(
          controller.errorMessage.value,
          'Esse identificador já está em uso.',
        );
      },
    );

    test('Sad Path: isCreating resets after a failure', () async {
      // 1. Arrange
      backend.failure = const CreationException('Falhou.');
      final controller = await readyController();

      // 2. Act
      await controller.create();

      // 3. Assert
      expect(controller.isCreating.value, isFalse);
    });

    test(
      'Sad Path: refuses without calling the backend when the name step is invalid',
      () async {
        // 1. Arrange
        final controller = startedController()..setName('R');
        await settle();

        // 2. Act
        final ok = await controller.create();

        // 3. Assert
        expect(ok, isFalse);
        expect(backend.creates, isEmpty);
      },
    );
  });

  group('CreateOrganizationController.offeredPlans - Unit Test Suite', () {
    test('Happy Path: only community is offered for now', () {
      // 1. Arrange
      const expected = {'community'};

      // 2. Act
      final offered = CreateOrganizationController.offeredPlans;

      // 3. Assert
      expect(offered, expected);
    });
  });

  group('CreateOrganizationController.pickPlan - Unit Test Suite', () {
    test('Happy Path: community is picked', () {
      // 1. Arrange
      final controller = startedController();
      controller.plan.value = 'standard';

      // 2. Act
      controller.pickPlan('community');

      // 3. Assert
      expect(controller.plan.value, 'community');
    });

    test('Sad Path: standard leaves the plan unchanged', () {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      controller.pickPlan('standard');

      // 3. Assert
      expect(controller.plan.value, 'community');
    });

    test('Sad Path: an unknown plan leaves the plan unchanged', () {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      controller.pickPlan('premium');

      // 3. Assert
      expect(controller.plan.value, 'community');
    });

    test('Edge Case: nothing is picked while creating', () async {
      // 1. Arrange
      backend.gate = Completer<void>();
      final controller = await readyController();
      controller.plan.value = 'standard';
      final pending = controller.create();

      // 2. Act
      controller.pickPlan('community');

      // 3. Assert
      expect(controller.plan.value, 'standard');
      backend.gate!.complete();
      await pending;
    });
  });

  group('CreateOrganizationController (themes) - Unit Test Suite', () {
    test('Happy Path: loads the active themes sorted by order', () async {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      await settle();

      // 3. Assert
      expect(controller.themes.map((t) => t.id), [
        'sol',
        'oceano',
        defaultPartnerTheme.id,
      ]);
    });

    test('Sad Path: a failing catalog leaves only the default theme', () async {
      // 1. Arrange
      final controller = startedController(
        themes: FakeThemeCatalog(failing: true),
      );

      // 2. Act
      await settle();

      // 3. Assert
      expect(controller.themes.map((t) => t.id), [defaultPartnerTheme.id]);
    });
  });
}
