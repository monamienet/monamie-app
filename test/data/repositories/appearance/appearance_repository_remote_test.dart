import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_repository_remote.dart';
import 'package:monamie_app/data/repositories/theme/theme_repository.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/data/services/storage/organization_storage_service.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([
  MockSpec<OrganizationFunctionsService>(),
  MockSpec<OrganizationStorageService>(),
  MockSpec<ThemeRepository>(),
])
import 'appearance_repository_remote_test.mocks.dart';

const _saveFailed =
    'Não foi possível salvar agora. Verifique a conexão e tente de novo.';

const _logoPath = 'organizations/rotasul/logo.png';

OrganizationTheme _theme(String id, int order, {bool active = true}) =>
    OrganizationTheme(
      id: id,
      name: id,
      primary: const Color(0xFF0B7F7B),
      dark: const Color(0xFF0A3D3B),
      light: const Color(0xFFD3EEEC),
      onPrimary: const Color(0xFFFFFFFF),
      onDark: const Color(0xFFFFFFFF),
      order: order,
      active: active,
    );

final _png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

late MockOrganizationFunctionsService functions;
late MockOrganizationStorageService storage;
late MockThemeRepository themes;
late AppearanceRepositoryRemote repository;

/// Makes `setBranding` fail with [error].
void brandingFails(Object error) => when(
  functions.call('setBranding', any, timeout: anyNamed('timeout')),
).thenAnswer((_) async => throw error);

/// The data `setBranding` was called with, verifying one call.
Object? sentBranding() => verify(
  functions.call('setBranding', captureAny, timeout: anyNamed('timeout')),
).captured.single;

String messageOf(Result<Object?> result) => switch (result) {
  Err(:final message) => message,
  Ok() => fail('expected an Err, got $result'),
};

T valueOf<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err() => fail('expected an Ok, got $result'),
};

void main() {
  setUp(() {
    functions = MockOrganizationFunctionsService();
    storage = MockOrganizationStorageService();
    themes = MockThemeRepository();
    repository = AppearanceRepositoryRemote(
      themes: themes,
      functions: functions,
      storage: storage,
    );
  });

  group('AppearanceRepositoryRemote.pickableThemes - Unit Test Suite', () {
    test('Happy Path: returns the active themes in picker order', () async {
      // 1. Arrange
      final sol = _theme('sol', 0);
      final lava = _theme('lava', 1, active: false);
      final oceano = _theme('oceano', 2);
      when(themes.themes()).thenAnswer(
        (_) async => {
          for (final t in [oceano, lava, sol]) t.id: t,
        },
      );

      // 2. Act
      final result = await repository.pickableThemes();

      // 3. Assert
      expect(valueOf(result), [sol, oceano]);
    });

    test('Sad Path: an unreadable catalog gives the themes message', () async {
      // 1. Arrange
      when(
        themes.themes(),
      ).thenAnswer((_) async => throw StateError('offline'));

      // 2. Act
      final result = await repository.pickableThemes();

      // 3. Assert
      expect(messageOf(result), 'Não foi possível carregar os temas.');
    });
  });

  group('AppearanceRepositoryRemote (logo) - Unit Test Suite', () {
    test('Happy Path: uploadLogo writes the PNG at the organization\'s logo '
        'path', () async {
      // 1. Arrange
      // (the storage and functions mocks succeed by default)

      // 2. Act
      final result = await repository.uploadLogo('rotasul', _png);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(
        storage.upload(_logoPath, _png, contentType: 'image/png'),
      ).called(1);
    });

    test('Happy Path: deleteLogo deletes the organization\'s logo', () async {
      // 1. Arrange
      // (the storage and functions mocks succeed by default)

      // 2. Act
      final result = await repository.deleteLogo('rotasul');

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(storage.delete(_logoPath)).called(1);
    });

    test('Sad Path: a failed upload gives the save hint', () async {
      // 1. Arrange
      when(
        storage.upload(any, any, contentType: anyNamed('contentType')),
      ).thenAnswer((_) async => throw Exception('unauthorized'));

      // 2. Act
      final result = await repository.uploadLogo('rotasul', _png);

      // 3. Assert
      expect(messageOf(result), _saveFailed);
    });

    test('Sad Path: a failed delete gives the save hint', () async {
      // 1. Arrange
      when(
        storage.delete(any),
      ).thenAnswer((_) async => throw Exception('unauthorized'));

      // 2. Act
      final result = await repository.deleteLogo('rotasul');

      // 3. Assert
      expect(messageOf(result), _saveFailed);
    });
  });

  group('AppearanceRepositoryRemote.saveBranding - Unit Test Suite', () {
    test('Happy Path: sends only the changed fields', () async {
      // 1. Arrange
      // (the storage and functions mocks succeed by default)

      // 2. Act
      final result = await repository.saveBranding(
        'rotasul',
        name: 'Rota Norte',
        logo: 'set',
      );

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(sentBranding(), {
        'organizationId': 'rotasul',
        'name': 'Rota Norte',
        'logo': 'set',
      });
    });

    test('Edge Case: a theme alone sends only the theme', () async {
      // 1. Arrange
      // (the storage and functions mocks succeed by default)

      // 2. Act
      await repository.saveBranding('rotasul', themeId: 'oceano');

      // 3. Assert
      expect(sentBranding(), {
        'organizationId': 'rotasul',
        'themeId': 'oceano',
      });
    });

    for (final code in ['invalid-argument', 'permission-denied']) {
      test('Sad Path: a $code refusal gives the server\'s own words', () async {
        // 1. Arrange
        brandingFails(FunctionsFailure(code, 'Nome inválido.'));

        // 2. Act
        final result = await repository.saveBranding('rotasul', name: 'X');

        // 3. Assert
        expect(messageOf(result), 'Nome inválido.');
      });
    }

    test('Edge Case: an explained refusal with no words gives the save '
        'fallback', () async {
      // 1. Arrange
      brandingFails(const FunctionsFailure('invalid-argument', null));

      // 2. Act
      final result = await repository.saveBranding('rotasul', name: 'X');

      // 3. Assert
      expect(messageOf(result), 'Não foi possível salvar.');
    });

    test('Sad Path: a failed-precondition refusal is not explained here: it '
        'gives the save hint', () async {
      // 1. Arrange
      brandingFails(const FunctionsFailure('failed-precondition', 'No.'));

      // 2. Act
      final result = await repository.saveBranding('rotasul', name: 'X');

      // 3. Assert
      expect(messageOf(result), _saveFailed);
    });

    test('Sad Path: an unexpected error gives the save hint', () async {
      // 1. Arrange
      brandingFails(StateError('offline'));

      // 2. Act
      final result = await repository.saveBranding('rotasul', name: 'X');

      // 3. Assert
      expect(messageOf(result), _saveFailed);
    });
  });
}
