import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/language/language_repository_preferences.dart';
import 'package:monamie_app/data/services/language_preferences_service.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<LanguagePreferencesService>()])
import 'language_repository_preferences_test.mocks.dart';

void main() {
  late MockLanguagePreferencesService service;
  late LanguageRepositoryPreferences repository;

  setUp(() {
    service = MockLanguagePreferencesService();
    repository = LanguageRepositoryPreferences(service: service);
  });

  group('LanguageRepositoryPreferences.restore - Unit Test Suite', () {
    test('Happy Path: no language is chosen before restore', () {
      // 1. Arrange / 2. Act
      final language = repository.language.value;

      // 3. Assert
      expect(language, isNull);
      verifyZeroInteractions(service);
    });

    test('Happy Path: restore reads the stored choice', () async {
      // 1. Arrange
      when(service.read()).thenAnswer((_) async => 'en');

      // 2. Act
      await repository.restore();

      // 3. Assert
      expect(repository.language.value, AppLanguage.en);
      verify(service.read()).called(1);
    });

    test('Edge Case: nothing stored leaves no language chosen', () async {
      // 1. Arrange
      when(service.read()).thenAnswer((_) async => null);

      // 2. Act
      await repository.restore();

      // 3. Assert
      expect(repository.language.value, isNull);
    });

    test(
      'Edge Case: a name this build does not have gives no language',
      () async {
        // 1. Arrange
        when(service.read()).thenAnswer((_) async => 'es');

        // 2. Act
        await repository.restore();

        // 3. Assert
        expect(repository.language.value, isNull);
      },
    );

    test('Sad Path: a throwing storage leaves no language and does not '
        'throw', () async {
      // 1. Arrange
      when(service.read()).thenThrow(Exception('storage unavailable'));

      // 2. Act
      await repository.restore();

      // 3. Assert
      expect(repository.language.value, isNull);
    });

    test(
      'Edge Case: restore notifies only when the language changes',
      () async {
        // 1. Arrange
        when(service.read()).thenAnswer((_) async => 'pt');
        var notifications = 0;
        repository.language.addListener(() => notifications++);

        // 2. Act
        await repository.restore();
        await repository.restore();

        // 3. Assert
        expect(notifications, 1);
      },
    );
  });

  group('LanguageRepositoryPreferences.choose - Unit Test Suite', () {
    test(
      'Happy Path: choose writes the name, then uses the language',
      () async {
        // 1. Arrange
        when(service.write(any)).thenAnswer((_) async {});

        // 2. Act
        final result = await repository.choose(AppLanguage.pt);

        // 3. Assert
        expect(result, isA<Ok<void>>());
        expect(repository.language.value, AppLanguage.pt);
        verify(service.write('pt')).called(1);
      },
    );

    test('Edge Case: the language is not in use until it is stored', () async {
      // 1. Arrange
      final seenWhileWriting = <AppLanguage?>[];
      when(service.write(any)).thenAnswer((_) async {
        seenWhileWriting.add(repository.language.value);
      });

      // 2. Act
      await repository.choose(AppLanguage.en);

      // 3. Assert
      expect(seenWhileWriting, [null]);
      expect(repository.language.value, AppLanguage.en);
    });

    test(
      'Edge Case: choosing notifies only when the language changes',
      () async {
        // 1. Arrange
        when(service.write(any)).thenAnswer((_) async {});
        var notifications = 0;
        repository.language.addListener(() => notifications++);

        // 2. Act
        await repository.choose(AppLanguage.en);
        await repository.choose(AppLanguage.en);
        await repository.choose(AppLanguage.pt);

        // 3. Assert
        expect(notifications, 2);
        verify(service.write('en')).called(2);
        verify(service.write('pt')).called(1);
      },
    );

    test('Sad Path: a failing write returns the failure and keeps the '
        'language', () async {
      // 1. Arrange
      final error = Exception('disk full');
      when(service.write(any)).thenThrow(error);
      var notifications = 0;
      repository.language.addListener(() => notifications++);

      // 2. Act
      final result = await repository.choose(AppLanguage.pt);

      // 3. Assert
      expect(result, isA<Err<void>>());
      final err = result as Err<void>;
      expect(err.failure, const Failure.languageNotSaved());
      expect(err.error, error);
      expect(err.stackTrace, isNotNull);
      expect(repository.language.value, isNull);
      expect(notifications, 0);
    });

    test(
      'Sad Path: a failing write keeps the language chosen before',
      () async {
        // 1. Arrange
        when(service.write('en')).thenAnswer((_) async {});
        when(service.write('pt')).thenThrow(Exception('disk full'));
        await repository.choose(AppLanguage.en);

        // 2. Act
        final result = await repository.choose(AppLanguage.pt);

        // 3. Assert
        expect(result, isA<Err<void>>());
        expect(repository.language.value, AppLanguage.en);
      },
    );
  });
}
