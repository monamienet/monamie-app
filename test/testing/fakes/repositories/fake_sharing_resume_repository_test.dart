import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/utils/result.dart';

import '../../../../testing/fakes/repositories/fake_outcomes.dart';
import '../../../../testing/fakes/repositories/fake_sharing_resume_repository.dart';

const _kIntent = SharingIntent(email: 'ana@example.com', name: 'Ana');

void main() {
  group('FakeSharingResumeRepository - Unit Test Suite', () {
    test('Happy Path: the option is off until restore reads the stored '
        'one', () async {
      // 1. Arrange
      final fake = FakeSharingResumeRepository(storedOption: true);
      final before = fake.resumeOnRestart.value;

      // 2. Act
      await fake.restore();

      // 3. Assert
      expect(before, isFalse);
      expect(fake.resumeOnRestart.value, isTrue);
      expect(fake.callCount('restore'), 1);
    });

    test('Happy Path: setResumeOnRestart uses and stores the option', () async {
      // 1. Arrange
      final fake = FakeSharingResumeRepository();

      // 2. Act
      final result = await fake.setResumeOnRestart(true);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(fake.resumeOnRestart.value, isTrue);
      expect(fake.storedOption, isTrue);
    });

    test('Sad Path: a failing setResumeOnRestart returns the failure and '
        'changes nothing', () async {
      // 1. Arrange
      final fake = FakeSharingResumeRepository();
      fake.fail('setResumeOnRestart', const Failure.resumeOptionNotSaved());

      // 2. Act
      final result = await fake.setResumeOnRestart(true);

      // 3. Assert
      expect(
        result,
        isA<Err<void>>().having(
          (err) => err.failure,
          'failure',
          const Failure.resumeOptionNotSaved(),
        ),
      );
      expect(fake.resumeOnRestart.value, isFalse);
      expect(fake.storedOption, isFalse);
    });

    test('Happy Path: saveIntent keeps the intent and clearIntent forgets '
        'it', () async {
      // 1. Arrange
      final fake = FakeSharingResumeRepository();
      await fake.saveIntent(_kIntent);
      final saved = fake.intent;

      // 2. Act
      await fake.clearIntent();

      // 3. Assert
      expect(saved, _kIntent);
      expect(fake.intent, isNull);
    });

    test(
      'Sad Path: a failing clearIntent throws and keeps the intent',
      () async {
        // 1. Arrange
        final fake = FakeSharingResumeRepository();
        await fake.saveIntent(_kIntent);
        fake.fail('clearIntent', const Failure.resumeOptionNotSaved());

        // 2. Act
        final clearing = fake.clearIntent();

        // 3. Assert
        await expectLater(clearing, throwsA(isA<FakeFailure>()));
        expect(fake.intent, _kIntent);
      },
    );
  });
}
