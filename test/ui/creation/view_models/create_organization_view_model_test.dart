import 'dart:async';
import 'dart:ui' show Color;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/data/repositories/theme/theme_catalog.dart';
import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'package:monamie_app/data/repositories/creation/creation_repository.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<CreationRepository>(), MockSpec<ThemeCatalog>()])
import 'create_organization_view_model_test.mocks.dart';

const _white = Color(0xFFFFFFFF);

OrganizationTheme _theme(String id, int order, {bool active = true}) =>
    OrganizationTheme(
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

/// The `create` stub of [repository], with any arguments.
Future<Result<String>> anyCreate() => repository.create(
  id: anyNamed('id'),
  name: anyNamed('name'),
  themeId: anyNamed('themeId'),
  plan: anyNamed('plan'),
);

/// Makes `create` wait on [wait] before returning [status] or, with
/// [failure], an [Err] with that message.
void stubCreate(
  Future<void> Function() wait, {
  String status = 'active',
  String? failure,
}) {
  when(anyCreate()).thenAnswer((_) async {
    await wait();
    return failure == null ? Ok(status) : Err(failure);
  });
}

/// A [MockThemeCatalog] returning four themes (one retired), or failing
/// when [failing].
MockThemeCatalog mockCatalog({bool failing = false}) {
  final catalog = MockThemeCatalog();
  when(catalog.themes()).thenAnswer((_) async {
    if (failing) throw Exception('catalog unavailable');
    return {
      for (final t in [oceano, lava, defaultOrganizationTheme, sol]) t.id: t,
    };
  });
  return catalog;
}

late MockCreationRepository repository;

CreateOrganizationViewModel startedController({ThemeCatalog? themes}) =>
    CreateOrganizationViewModel(
      repository: repository,
      themes: themes ?? mockCatalog(),
      debounce: Duration.zero,
    )..load();

/// Lets the debounce timer fire and the mock answers resolve.
Future<void> settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

/// A started controller with name "Rota Sul" and id "rotasul" available.
Future<CreateOrganizationViewModel> readyController() async {
  final controller = startedController();
  controller.setName('Rota Sul');
  await settle();
  return controller;
}

void main() {
  provideDummy<Result<String?>>(const Ok(null));
  provideDummy<Result<String>>(const Ok('active'));

  setUp(() {
    repository = MockCreationRepository();
    when(repository.idProblem(any)).thenAnswer((_) async => const Ok(null));
    stubCreate(() async {});
  });

  group('suggestOrganizationId - Unit Test Suite', () {
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
        final id = suggestOrganizationId(input);

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

  group('CreateOrganizationViewModel (id suggestion) - Unit Test Suite', () {
    test('Happy Path: the name suggests the id', () {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      controller.setName('Rota Sul');

      // 3. Assert
      expect(controller.state.id, 'rotasul');
    });

    test('Edge Case: every name change suggests again', () {
      // 1. Arrange
      final controller = startedController()..setName('Rota');

      // 2. Act
      controller.setName('Rota Sul');

      // 3. Assert
      expect(controller.state.id, 'rotasul');
    });

    test('Sad Path: after the id is edited the name no longer changes it', () {
      // 1. Arrange
      final controller = startedController()
        ..setName('Rota Sul')
        ..setId('rsul');

      // 2. Act
      controller.setName('Rota Sul Turismo');

      // 3. Assert
      expect(controller.state.id, 'rsul');
    });
  });

  group('CreateOrganizationViewModel (id check) - Unit Test Suite', () {
    test('Happy Path: a valid id is checking right away', () {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      controller.setId('rotasul');

      // 3. Assert
      expect(controller.state.idCheck, IdCheck.checking);
    });

    test(
      'Happy Path: a free id becomes available after the debounce',
      () async {
        // 1. Arrange
        final controller = startedController()..setId('rotasul');

        // 2. Act
        await settle();

        // 3. Assert
        expect(controller.state.idCheck, IdCheck.available);
        expect(verify(repository.idProblem(captureAny)).captured, ['rotasul']);
      },
    );

    test(
      'Sad Path: a taken id becomes unavailable with the repository problem',
      () async {
        // 1. Arrange
        when(repository.idProblem('rotasul')).thenAnswer(
          (_) async => const Ok('Esse identificador já está em uso.'),
        );
        final controller = startedController()..setId('rotasul');

        // 2. Act
        await settle();

        // 3. Assert
        expect(controller.state.idCheck, IdCheck.unavailable);
        expect(
          controller.state.idProblem,
          'Esse identificador já está em uso.',
        );
      },
    );

    test(
      'Sad Path: a bad format is unavailable without asking the repository',
      () async {
        // 1. Arrange
        final controller = startedController();

        // 2. Act
        controller.setId('Rota Sul');
        await settle();

        // 3. Assert
        expect(controller.state.idCheck, IdCheck.unavailable);
        expect(controller.state.idProblem, isNotEmpty);
        verifyNever(repository.idProblem(any));
      },
    );

    test('Sad Path: a check that could not run is unavailable with a hint, '
        'whatever the repository said', () async {
      // 1. Arrange
      when(
        repository.idProblem('rotasul'),
      ).thenAnswer((_) async => const Err('Sem conexão.'));
      final controller = startedController()..setId('rotasul');

      // 2. Act
      await settle();

      // 3. Assert
      expect(controller.state.idCheck, IdCheck.unavailable);
      expect(controller.state.idProblem, 'Não foi possível verificar agora.');
    });

    test(
      'Edge Case: an answer for an id changed meanwhile is ignored',
      () async {
        // 1. Arrange
        final rotasulCheck = Completer<String?>();
        final rotanorteCheck = Completer<String?>();
        when(
          repository.idProblem('rotasul'),
        ).thenAnswer((_) async => Ok(await rotasulCheck.future));
        when(
          repository.idProblem('rotanorte'),
        ).thenAnswer((_) async => Ok(await rotanorteCheck.future));
        final controller = startedController()..setId('rotasul');
        await settle();
        controller.setId('rotanorte');
        await settle();

        // 2. Act
        rotasulCheck.complete(null);
        await settle();

        // 3. Assert
        expect(controller.state.idCheck, IdCheck.checking);
      },
    );
  });

  group(
    'CreateOrganizationViewModel (canContinueFromName) - Unit Test Suite',
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
          when(repository.idProblem('rotasul')).thenAnswer(
            (_) async => const Ok('Esse identificador já está em uso.'),
          );
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

  group('CreateOrganizationViewModel (create) - Unit Test Suite', () {
    test('Happy Path: sends id, trimmed name, theme and plan', () async {
      // 1. Arrange
      final controller = startedController()..setName('  Rota Sul  ');
      await settle();
      controller.pickTheme('oceano');
      controller.pickPlan('community');

      // 2. Act
      await controller.create();

      // 3. Assert
      final sent = verify(
        repository.create(
          id: captureAnyNamed('id'),
          name: captureAnyNamed('name'),
          themeId: captureAnyNamed('themeId'),
          plan: captureAnyNamed('plan'),
        ),
      ).captured;
      expect(sent, ['rotasul', 'Rota Sul', 'oceano', 'community']);
    });

    test('Happy Path: returns true and keeps the returned status', () async {
      // 1. Arrange
      stubCreate(() async {}, status: 'awaiting_billing');
      final controller = await readyController();

      // 2. Act
      final ok = await controller.create();

      // 3. Assert
      expect(ok, isTrue);
      expect(controller.state.result, 'awaiting_billing');
    });

    test('Happy Path: isCreating resets after success', () async {
      // 1. Arrange
      final controller = await readyController();

      // 2. Act
      await controller.create();

      // 3. Assert
      expect(controller.state.isCreating, isFalse);
    });

    test('Edge Case: isCreating is true while the call is in flight', () async {
      // 1. Arrange
      final gate = Completer<void>();
      stubCreate(() => gate.future);
      final controller = await readyController();

      // 2. Act
      final pending = controller.create();

      // 3. Assert
      expect(controller.state.isCreating, isTrue);
      gate.complete();
      await pending;
    });

    test(
      'Edge Case: a second create while one is in flight is refused',
      () async {
        // 1. Arrange
        final gate = Completer<void>();
        stubCreate(() => gate.future);
        final controller = await readyController();
        final first = controller.create();

        // 2. Act
        final second = await controller.create();

        // 3. Assert
        expect(second, isFalse);
        verify(anyCreate()).called(1);
        gate.complete();
        await first;
      },
    );

    test('Sad Path: an Err returns false with its message', () async {
      // 1. Arrange
      stubCreate(() async {}, failure: 'Esse identificador já está em uso.');
      final controller = await readyController();

      // 2. Act
      final ok = await controller.create();

      // 3. Assert
      expect(ok, isFalse);
      expect(
        controller.state.errorMessage,
        'Esse identificador já está em uso.',
      );
    });

    test('Sad Path: isCreating resets after a failure', () async {
      // 1. Arrange
      stubCreate(() async {}, failure: 'Falhou.');
      final controller = await readyController();

      // 2. Act
      await controller.create();

      // 3. Assert
      expect(controller.state.isCreating, isFalse);
    });

    test(
      'Sad Path: refuses without calling the repository when the name step is invalid',
      () async {
        // 1. Arrange
        final controller = startedController()..setName('R');
        await settle();

        // 2. Act
        final ok = await controller.create();

        // 3. Assert
        expect(ok, isFalse);
        verifyNever(anyCreate());
      },
    );
  });

  group('CreateOrganizationViewModel.offeredPlans - Unit Test Suite', () {
    test('Happy Path: only community is offered for now', () {
      // 1. Arrange
      const expected = {'community'};

      // 2. Act
      final offered = CreateOrganizationViewModel.offeredPlans;

      // 3. Assert
      expect(offered, expected);
    });
  });

  group('CreateOrganizationViewModel.pickPlan - Unit Test Suite', () {
    test('Happy Path: picking community keeps it without notifying', () {
      // 1. Arrange
      final controller = startedController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.pickPlan('community');

      // 3. Assert
      expect(controller.state.plan, 'community');
      expect(notifications, 0);
    });

    test('Sad Path: standard leaves the plan unchanged', () {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      controller.pickPlan('standard');

      // 3. Assert
      expect(controller.state.plan, 'community');
    });

    test('Sad Path: an unknown plan leaves the plan unchanged', () {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      controller.pickPlan('premium');

      // 3. Assert
      expect(controller.state.plan, 'community');
    });

    test('Edge Case: picking a plan while creating leaves the state as it '
        'is', () async {
      // 1. Arrange
      final gate = Completer<void>();
      stubCreate(() => gate.future);
      final controller = await readyController();
      final pending = controller.create();
      final creating = controller.state;

      // 2. Act
      controller.pickPlan('community');

      // 3. Assert
      expect(controller.state, creating);
      expect(controller.state.isCreating, isTrue);
      gate.complete();
      await pending;
    });
  });

  group('CreateOrganizationViewModel (themes) - Unit Test Suite', () {
    test('Happy Path: loads the active themes sorted by order', () async {
      // 1. Arrange
      final controller = startedController();

      // 2. Act
      await settle();

      // 3. Assert
      expect(controller.state.themes.map((t) => t.id), [
        'sol',
        'oceano',
        defaultOrganizationTheme.id,
      ]);
    });

    test('Sad Path: a failing catalog leaves only the default theme', () async {
      // 1. Arrange
      final controller = startedController(themes: mockCatalog(failing: true));

      // 2. Act
      await settle();

      // 3. Assert
      expect(controller.state.themes.map((t) => t.id), [
        defaultOrganizationTheme.id,
      ]);
    });
  });

  group('CreateOrganizationViewModel.load - Unit Test Suite', () {
    test('Edge Case: an empty catalog leaves no theme to pick and the '
        'default theme picked', () async {
      // 1. Arrange
      final catalog = MockThemeCatalog();
      when(catalog.themes()).thenAnswer((_) async => {});
      final controller = CreateOrganizationViewModel(
        repository: repository,
        themes: catalog,
      );

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.state.themes, isEmpty);
      expect(controller.pickedTheme, defaultOrganizationTheme);
    });
  });

  group('CreateOrganizationViewModel.dispose - Unit Test Suite', () {
    test('Happy Path: disposing stops the pending id check', () {
      fakeAsync((async) {
        // 1. Arrange
        final controller = CreateOrganizationViewModel(
          repository: repository,
          themes: mockCatalog(),
        )..setId('rotasul');

        // 2. Act
        controller.dispose();
        async.elapse(const Duration(seconds: 1));

        // 3. Assert
        verifyNever(repository.idProblem(any));
      });
    });

    test('Sad Path: an id answer arriving after dispose notifies nobody and '
        'does not throw', () async {
      // 1. Arrange
      final answer = Completer<String?>();
      when(
        repository.idProblem('rotasul'),
      ).thenAnswer((_) async => Ok(await answer.future));
      final controller = startedController()..setId('rotasul');
      await settle();
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      answer.complete(null);
      await settle();

      // 3. Assert
      expect(notifications, 0);
    });

    test('Sad Path: a creation finishing after dispose notifies nobody and '
        'does not throw', () async {
      // 1. Arrange
      final gate = Completer<void>();
      stubCreate(() => gate.future);
      final controller = await readyController();
      var notifications = 0;
      final pending = controller.create();
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      gate.complete();

      // 3. Assert
      await expectLater(pending, completion(isTrue));
      expect(notifications, 0);
    });
  });

  group('CreateOrganizationViewModel (listeners) - Unit Test Suite', () {
    test('Happy Path: picking another theme notifies once', () {
      // 1. Arrange
      final controller = startedController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.pickTheme('oceano');

      // 3. Assert
      expect(notifications, 1);
    });

    test('Edge Case: picking the theme already picked notifies nobody', () {
      // 1. Arrange
      final controller = startedController()..pickTheme('oceano');
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.pickTheme('oceano');

      // 3. Assert
      expect(notifications, 0);
    });

    test('Edge Case: reloading an unchanged catalog notifies nobody', () async {
      // 1. Arrange
      final controller = startedController();
      await settle();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(notifications, 0);
    });
  });
}
