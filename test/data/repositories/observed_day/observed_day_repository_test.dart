import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/repositories/observed_day/observed_day_repository.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  group('ObservedDayRepository - Unit Test Suite', () {
    test('Happy Path: Deve começar observando hoje, à meia-noite', () {
      // 1. Arrange
      final repository = ObservedDayRepository();

      // 2. Act
      final day = repository.observedDay.value;

      // 3. Assert
      expect(day, _today());
      expect(repository.isObservingToday, isTrue);
      repository.dispose();
    });

    test('Happy Path: Deve observar o dia escolhido, à meia-noite', () {
      // 1. Arrange
      final repository = ObservedDayRepository();

      // 2. Act
      repository.select(DateTime(2026, 9, 16, 20, 30, 15));

      // 3. Assert
      expect(repository.observedDay.value, DateTime(2026, 9, 16));
      expect(repository.isObservingToday, isFalse);
      repository.dispose();
    });

    test('Happy Path: Deve voltar para hoje com goToToday()', () {
      // 1. Arrange
      final repository = ObservedDayRepository()..select(DateTime(2026, 9, 16));

      // 2. Act
      repository.goToToday();

      // 3. Assert
      expect(repository.observedDay.value, _today());
      expect(repository.isObservingToday, isTrue);
      repository.dispose();
    });

    test('Edge Case: Deve tratar outro horário de hoje como hoje', () {
      // 1. Arrange
      final repository = ObservedDayRepository();
      final now = DateTime.now();

      // 2. Act
      repository.select(DateTime(now.year, now.month, now.day, 23, 59));

      // 3. Assert
      expect(repository.observedDay.value, _today());
      expect(repository.isObservingToday, isTrue);
      repository.dispose();
    });

    test('Happy Path: Deve avisar uma vez quando o dia muda', () {
      // 1. Arrange
      final repository = ObservedDayRepository();
      var notified = 0;
      repository.observedDay.addListener(() => notified++);

      // 2. Act
      repository.select(DateTime(2026, 9, 16, 8));

      // 3. Assert
      expect(notified, 1);
      repository.dispose();
    });

    test(
      'Edge Case: Não deve avisar ao escolher outro horário do mesmo dia',
      () {
        // 1. Arrange
        final repository = ObservedDayRepository()
          ..select(DateTime(2026, 9, 16, 8));
        var notified = 0;
        repository.observedDay.addListener(() => notified++);

        // 2. Act
        repository.select(DateTime(2026, 9, 16, 18));
        repository.goToToday();
        repository.goToToday();

        // 3. Assert
        expect(notified, 1);
        repository.dispose();
      },
    );

    test(
      'Sad Path: Deve ignorar select() e goToToday() depois de dispose()',
      () {
        // 1. Arrange
        final repository = ObservedDayRepository()..dispose();

        // 2. Act
        void act() {
          repository.select(DateTime(2026, 9, 16));
          repository.goToToday();
        }

        // 3. Assert
        expect(act, returnsNormally);
      },
    );

    test('Edge Case: Deve aceitar um segundo dispose() sem lançar', () {
      // 1. Arrange
      final repository = ObservedDayRepository()..dispose();

      // 2. Act
      void act() => repository.dispose();

      // 3. Assert
      expect(act, returnsNormally);
    });
  });
}
