import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/utils/result.dart';

import '../../../../testing/fakes/repositories/fake_language_repository.dart';
import '../../../../testing/fakes/repositories/fake_outcomes.dart';

void main() {
  group('FakeLanguageRepository - Unit Test Suite', () {
    test('Happy Path: no language is chosen until restore reads the stored '
        'one', () async {
      // 1. Arrange
      final fake = FakeLanguageRepository(stored: AppLanguage.en);
      final before = fake.language.value;

      // 2. Act
      await fake.restore();

      // 3. Assert
      expect(before, isNull);
      expect(fake.language.value, AppLanguage.en);
      expect(fake.callCount('restore'), 1);
    });

    test('Edge Case: restore with nothing stored leaves no language', () async {
      // 1. Arrange
      final fake = FakeLanguageRepository();

      // 2. Act
      await fake.restore();

      // 3. Assert
      expect(fake.language.value, isNull);
    });

    test('Happy Path: choose uses and stores the language', () async {
      // 1. Arrange
      final fake = FakeLanguageRepository();

      // 2. Act
      final result = await fake.choose(AppLanguage.pt);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(fake.language.value, AppLanguage.pt);
      expect(fake.stored, AppLanguage.pt);
      expect(fake.argumentsOf('choose'), [
        [AppLanguage.pt],
      ]);
    });

    test('Edge Case: a language chosen survives a new launch', () async {
      // 1. Arrange
      final fake = FakeLanguageRepository();
      await fake.choose(AppLanguage.en);
      final relaunched = FakeLanguageRepository(stored: fake.stored);

      // 2. Act
      await relaunched.restore();

      // 3. Assert
      expect(relaunched.language.value, AppLanguage.en);
    });

    test('Edge Case: choosing the same language notifies once', () async {
      // 1. Arrange
      final fake = FakeLanguageRepository();
      var notifications = 0;
      fake.language.addListener(() => notifications++);

      // 2. Act
      await fake.choose(AppLanguage.en);
      await fake.choose(AppLanguage.en);

      // 3. Assert
      expect(notifications, 1);
    });

    test('Sad Path: a failing choose returns the failure and changes '
        'nothing', () async {
      // 1. Arrange
      final fake = FakeLanguageRepository(stored: AppLanguage.pt);
      await fake.restore();
      fake.fail('choose', const Failure.languageNotSaved());

      // 2. Act
      final result = await fake.choose(AppLanguage.en);

      // 3. Assert
      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, const Failure.languageNotSaved());
      expect(fake.language.value, AppLanguage.pt);
      expect(fake.stored, AppLanguage.pt);
    });

    test('Sad Path: a failing restore throws a FakeFailure', () async {
      // 1. Arrange
      final fake = FakeLanguageRepository(stored: AppLanguage.en)
        ..fail('restore', const Failure.languageNotSaved());

      // 2. Act
      final restoring = fake.restore();

      // 3. Assert
      await expectLater(restoring, throwsA(isA<FakeFailure>()));
      expect(fake.language.value, isNull);
    });

    test('Edge Case: a held choose changes nothing until released', () async {
      // 1. Arrange
      final fake = FakeLanguageRepository();
      final hold = fake.hold('choose');

      // 2. Act
      final pending = fake.choose(AppLanguage.en);
      await Future<void>.delayed(Duration.zero);
      final whileHeld = fake.language.value;
      hold.complete();
      final result = await pending;

      // 3. Assert
      expect(whileHeld, isNull);
      expect(result, isA<Ok<void>>());
      expect(fake.language.value, AppLanguage.en);
    });
  });
}
