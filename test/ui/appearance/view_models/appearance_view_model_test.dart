import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_repository.dart';
import 'package:monamie_app/ui/appearance/view_models/appearance_view_model.dart';
import 'package:monamie_app/data/services/logo_converter.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<AppearanceRepository>()])
import 'appearance_view_model_test.mocks.dart';

const oceano = OrganizationTheme(
  id: 'oceano',
  name: 'Oceano',
  primary: Color(0xFF0B7F7B),
  dark: Color(0xFF0A3D3B),
  light: Color(0xFFD3EEEC),
  onPrimary: Color(0xFFFFFFFF),
  onDark: Color(0xFFFFFFFF),
);

/// The organization as saved: Grafite, no logo.
const rotaSul = OrganizationConfig(
  id: 'rotasul',
  name: 'Rota Sul',
  themeId: 'grafite',
  theme: defaultOrganizationTheme,
);

final savedLogo = Uint8List.fromList([1, 1, 1]);

/// [rotaSul] with a logo already saved.
final rotaSulWithLogo = OrganizationConfig(
  id: 'rotasul',
  name: 'Rota Sul',
  themeId: 'grafite',
  theme: defaultOrganizationTheme,
  logoVersion: 5,
  logoPng: savedLogo,
);

final pickedFile = Uint8List.fromList([9, 9, 9]);
final convertedPng = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

/// Makes `saveBranding` wait on [wait], then succeed or, with [failure],
/// return an [Err] with that message.
void stubSave(Future<void> Function() wait, {String? failure}) {
  when(
    repository.saveBranding(
      any,
      name: anyNamed('name'),
      themeId: anyNamed('themeId'),
      logo: anyNamed('logo'),
    ),
  ).thenAnswer((_) async {
    await wait();
    return failure == null ? const Ok(null) : Err(failure);
  });
}

/// Verifies `saveBranding` was called once for Rota Sul and returns the
/// fields it was sent.
({String? name, String? themeId, String? logo}) savedBranding() {
  final fields = verify(
    repository.saveBranding(
      'rotasul',
      name: captureAnyNamed('name'),
      themeId: captureAnyNamed('themeId'),
      logo: captureAnyNamed('logo'),
    ),
  ).captured;
  expect(fields, hasLength(3), reason: 'saveBranding called once');
  return (
    name: fields[0] as String?,
    themeId: fields[1] as String?,
    logo: fields[2] as String?,
  );
}

late MockAppearanceRepository repository;
late List<OrganizationConfig> onSavedWith;

/// A controller for [organization] whose themes are not loaded yet.
AppearanceViewModel newController(OrganizationConfig organization) =>
    AppearanceViewModel(
      organization: organization,
      repository: repository,
      convertLogo: (_) async => convertedPng,
      onSaved: (saved) async => onSavedWith.add(saved),
    );

/// A controller for [organization] whose themes are already loaded, with a
/// converter that returns [convertedPng] (or [convert] when given).
Future<AppearanceViewModel> controllerFor(
  OrganizationConfig organization, {
  Future<Uint8List> Function(Uint8List bytes)? convert,
}) async {
  final controller = AppearanceViewModel(
    organization: organization,
    repository: repository,
    convertLogo: convert ?? (_) async => convertedPng,
    onSaved: (saved) async => onSavedWith.add(saved),
  );
  controller.load();
  await pumpEventQueue();
  clearInteractions(repository);
  return controller;
}

/// Picks [pickedFile] and keeps the converted logo.
Future<void> pickAndUse(AppearanceViewModel controller) async {
  await controller.pickLogo(pickedFile);
  controller.useCandidate();
}

void main() {
  provideDummy<Result<List<OrganizationTheme>>>(const Ok([]));
  provideDummy<Result<void>>(const Ok(null));

  setUp(() {
    repository = MockAppearanceRepository();
    when(
      repository.pickableThemes(),
    ).thenAnswer((_) async => const Ok([oceano, defaultOrganizationTheme]));
    when(
      repository.uploadLogo(any, any),
    ).thenAnswer((_) async => const Ok(null));
    when(repository.deleteLogo(any)).thenAnswer((_) async => const Ok(null));
    stubSave(() async {});
    onSavedWith = [];
  });

  group('AppearanceViewModel.hasChanges - Unit Test Suite', () {
    test('Happy Path: a new name is a change', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);

      // 2. Act
      controller.setName('Rota Norte');

      // 3. Assert
      expect(controller.hasChanges, isTrue);
    });

    test('Happy Path: a new theme is a change', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);

      // 2. Act
      controller.pickTheme('oceano');

      // 3. Assert
      expect(controller.hasChanges, isTrue);
    });

    test('Happy Path: a new logo is a change', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);

      // 2. Act
      await pickAndUse(controller);

      // 3. Assert
      expect(controller.hasChanges, isTrue);
    });

    test('Edge Case: removing a saved logo is a change', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSulWithLogo);

      // 2. Act
      controller.removeLogo();

      // 3. Assert
      expect(controller.hasChanges, isTrue);
    });

    test('Sad Path: nothing touched is no change', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);

      // 2. Act
      final changed = controller.hasChanges;

      // 3. Assert
      expect(changed, isFalse);
    });

    test(
      'Sad Path: a name changed back to the saved one is no change',
      () async {
        // 1. Arrange
        final controller = await controllerFor(rotaSul);
        controller.setName('Rota Norte');

        // 2. Act
        controller.setName('Rota Sul');

        // 3. Assert
        expect(controller.hasChanges, isFalse);
      },
    );
  });

  group('AppearanceViewModel.save - Unit Test Suite', () {
    test('Happy Path: a new name alone sends only the name', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(savedBranding(), (name: 'Rota Norte', themeId: null, logo: null));
      verifyNoMoreInteractions(repository);
    });

    test('Happy Path: a new theme alone sends only the theme', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.pickTheme('oceano');

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(savedBranding(), (name: null, themeId: 'oceano', logo: null));
    });

    test('Happy Path: a new logo is uploaded, then saved as "set"', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      await pickAndUse(controller);

      // 2. Act
      await controller.save();

      // 3. Assert
      verifyInOrder([
        repository.uploadLogo('rotasul', convertedPng),
        repository.saveBranding(
          'rotasul',
          name: null,
          themeId: null,
          logo: 'set',
        ),
      ]);
      verifyNoMoreInteractions(repository);
    });

    test('Happy Path: a removed logo is deleted, then saved as '
        '"removed"', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSulWithLogo);
      controller.removeLogo();

      // 2. Act
      await controller.save();

      // 3. Assert
      verifyInOrder([
        repository.deleteLogo('rotasul'),
        repository.saveBranding(
          'rotasul',
          name: null,
          themeId: null,
          logo: 'removed',
        ),
      ]);
      verifyNoMoreInteractions(repository);
    });

    test('Happy Path: onSaved receives the new name and theme', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');
      controller.pickTheme('oceano');

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(
        [
          onSavedWith.single.name,
          onSavedWith.single.themeId,
          onSavedWith.single.effectiveTheme.id,
        ],
        ['Rota Norte', 'oceano', 'oceano'],
      );
    });

    test('Happy Path: a successful save returns true', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');

      // 2. Act
      final ok = await controller.save();

      // 3. Assert
      expect(ok, isTrue);
    });

    test('Edge Case: the name is trimmed before it is sent', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('  Rota Norte ');

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(savedBranding().name, 'Rota Norte');
    });

    test('Sad Path: no changes returns false and calls nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);

      // 2. Act
      final ok = await controller.save();

      // 3. Assert
      expect([ok, onSavedWith], [false, isEmpty]);
      verifyNoMoreInteractions(repository);
    });

    test('Sad Path: an Err from saveBranding lands in errorMessage and save '
        'returns false', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');
      stubSave(() async {}, failure: 'Nome inválido.');

      // 2. Act
      final ok = await controller.save();

      // 3. Assert
      expect(
        [ok, controller.state.errorMessage, onSavedWith],
        [false, 'Nome inválido.', isEmpty],
      );
    });

    test('Sad Path: a failed upload returns false with its message and '
        'saves no branding', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      await pickAndUse(controller);
      when(
        repository.uploadLogo(any, any),
      ).thenAnswer((_) async => const Err('Não foi possível salvar agora.'));

      // 2. Act
      final ok = await controller.save();

      // 3. Assert
      expect(
        [ok, controller.state.errorMessage, onSavedWith],
        [false, 'Não foi possível salvar agora.', isEmpty],
      );
      verify(repository.uploadLogo('rotasul', convertedPng)).called(1);
      verifyNoMoreInteractions(repository);
      expect(controller.state.isSaving, isFalse);
    });

    test('Sad Path: a failed logo delete returns false with its message and '
        'saves no branding', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSulWithLogo);
      controller.removeLogo();
      when(
        repository.deleteLogo(any),
      ).thenAnswer((_) async => const Err('Sem permissão.'));

      // 2. Act
      final ok = await controller.save();

      // 3. Assert
      expect(
        [ok, controller.state.errorMessage, onSavedWith],
        [false, 'Sem permissão.', isEmpty],
      );
      verify(repository.deleteLogo('rotasul')).called(1);
      verifyNoMoreInteractions(repository);
    });
  });

  group('AppearanceViewModel.save reentrancy - Unit Test Suite', () {
    test('Happy Path: isSaving is true while the save is in flight', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');
      final gate = Completer<void>();
      stubSave(() => gate.future);

      // 2. Act
      final pending = controller.save();

      // 3. Assert
      expect(controller.state.isSaving, isTrue);
      gate.complete();
      await pending;
    });

    test('Happy Path: isSaving is false after the save', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(controller.state.isSaving, isFalse);
    });

    test('Edge Case: a second save while the first is in flight returns '
        'false and does not call the repository again', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');
      final gate = Completer<void>();
      stubSave(() => gate.future);
      final first = controller.save();
      await pumpEventQueue();

      // 2. Act
      final second = await controller.save();

      // 3. Assert
      gate.complete();
      await first;
      expect(second, isFalse);
      savedBranding();
      verifyNoMoreInteractions(repository);
    });

    test('Sad Path: isSaving is false after an Err', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');
      stubSave(() async {}, failure: 'Sem permissão.');

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(controller.state.isSaving, isFalse);
    });
  });

  group('AppearanceViewModel logo sheet - Unit Test Suite', () {
    test('Happy Path: picking a file shows the converted preview', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);

      // 2. Act
      await controller.pickLogo(pickedFile);

      // 3. Assert
      expect(
        [controller.state.sheet, controller.candidate],
        [LogoSheet.preview, convertedPng],
      );
    });

    test('Happy Path: the sheet is processing while converting', () async {
      // 1. Arrange
      final conversion = Completer<Uint8List>();
      final controller = await controllerFor(
        rotaSul,
        convert: (_) => conversion.future,
      );

      // 2. Act
      final pending = controller.pickLogo(pickedFile);

      // 3. Assert
      expect(controller.state.sheet, LogoSheet.processing);
      conversion.complete(convertedPng);
      await pending;
    });

    test(
      'Happy Path: useCandidate keeps the logo and closes the sheet',
      () async {
        // 1. Arrange
        final controller = await controllerFor(rotaSul);
        await controller.pickLogo(pickedFile);

        // 2. Act
        controller.useCandidate();

        // 3. Assert
        expect(
          [
            controller.state.logoPng,
            controller.candidate,
            controller.state.sheet,
          ],
          [convertedPng, null, LogoSheet.closed],
        );
      },
    );

    test('Edge Case: closeSheet is ignored while processing', () async {
      // 1. Arrange
      final conversion = Completer<Uint8List>();
      final controller = await controllerFor(
        rotaSul,
        convert: (_) => conversion.future,
      );
      final pending = controller.pickLogo(pickedFile);

      // 2. Act
      controller.closeSheet();

      // 3. Assert
      expect(controller.state.sheet, LogoSheet.processing);
      conversion.complete(convertedPng);
      await pending;
    });

    test(
      'Edge Case: closeSheet after the preview drops the candidate',
      () async {
        // 1. Arrange
        final controller = await controllerFor(rotaSul);
        await controller.pickLogo(pickedFile);

        // 2. Act
        controller.closeSheet();

        // 3. Assert
        expect(
          [
            controller.state.sheet,
            controller.candidate,
            controller.state.logoPng,
          ],
          [LogoSheet.closed, null, null],
        );
      },
    );

    test(
      'Sad Path: a LogoException shows the error with its message',
      () async {
        // 1. Arrange
        final controller = await controllerFor(
          rotaSul,
          convert: (_) async => throw const LogoException(
            'O arquivo tem 12 MB. Envie um de até '
            '10 MB.',
          ),
        );

        // 2. Act
        await controller.pickLogo(pickedFile);

        // 3. Assert
        expect(
          [controller.state.sheet, controller.state.sheetError],
          [LogoSheet.error, 'O arquivo tem 12 MB. Envie um de até 10 MB.'],
        );
      },
    );
  });

  group('AppearanceViewModel.load - Unit Test Suite', () {
    test('Happy Path: loads the pickable themes', () async {
      // 1. Arrange
      final controller = newController(rotaSul);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.state.themes, [oceano, defaultOrganizationTheme]);
      expect(controller.state.isLoadingThemes, isFalse);
    });

    test('Edge Case: isLoadingThemes is true while the themes are '
        'read', () async {
      // 1. Arrange
      final gate = Completer<List<OrganizationTheme>>();
      when(
        repository.pickableThemes(),
      ).thenAnswer((_) async => Ok(await gate.future));
      final controller = newController(rotaSul);

      // 2. Act
      final pending = controller.load();

      // 3. Assert
      expect(controller.state.isLoadingThemes, isTrue);
      gate.complete([oceano]);
      await pending;
      expect(controller.state.isLoadingThemes, isFalse);
    });

    test('Edge Case: an empty catalog leaves the saved theme '
        'picked', () async {
      // 1. Arrange
      when(
        repository.pickableThemes(),
      ).thenAnswer((_) async => const Ok(<OrganizationTheme>[]));
      final controller = newController(rotaSul);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.state.themes, isEmpty);
      expect(controller.pickedTheme, defaultOrganizationTheme);
    });

    test('Sad Path: an unreadable catalog offers only the saved '
        'theme', () async {
      // 1. Arrange
      when(repository.pickableThemes()).thenAnswer(
        (_) async => Err(
          'Não foi possível carregar os temas.',
          error: StateError('offline'),
        ),
      );
      final controller = newController(rotaSul);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.state.themes, [defaultOrganizationTheme]);
      expect(controller.state.isLoadingThemes, isFalse);
    });
  });

  group('AppearanceViewModel (listeners) - Unit Test Suite', () {
    test('Happy Path: typing a new name notifies once', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.setName('Rota Norte');

      // 3. Assert
      expect(notifications, 1);
      expect(controller.hasChanges, isTrue);
    });

    test('Happy Path: picking another theme notifies once', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.pickTheme('oceano');

      // 3. Assert
      expect(notifications, 1);
      expect(controller.pickedTheme, oceano);
    });

    test('Edge Case: picking the theme already picked notifies '
        'nobody', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.pickTheme(defaultOrganizationTheme.id);

      // 3. Assert
      expect(notifications, 0);
    });

    test('Edge Case: reloading themes equal by content notifies only for '
        'the loading flag', () async {
      // 1. Arrange
      // Fresh objects on every read, as the repository builds them from
      // Firestore documents.
      when(repository.pickableThemes()).thenAnswer(
        (_) async => Ok([
          OrganizationTheme(
            id: 'oceano',
            name: 'Oceano',
            primary: const Color(0xFF0B7F7B),
            dark: const Color(0xFF0A3D3B),
            light: const Color(0xFFD3EEEC),
            onPrimary: const Color(0xFFFFFFFF),
            onDark: const Color(0xFFFFFFFF),
          ),
        ]),
      );
      final controller = newController(rotaSul);
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(notifications, 2);
    });

    test('Sad Path: a save finishing after dispose notifies nobody and does '
        'not throw', () async {
      // 1. Arrange
      final controller = await controllerFor(rotaSul);
      controller.setName('Rota Norte');
      final gate = Completer<void>();
      stubSave(() => gate.future);
      var notifications = 0;
      final pending = controller.save();
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      gate.complete();

      // 3. Assert
      await expectLater(pending, completion(isTrue));
      expect(notifications, 0);
    });
  });
}
