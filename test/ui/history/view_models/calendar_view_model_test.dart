import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/data/repositories/observed_day/observed_day_repository.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/domain/models/history_month.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/map_group.dart';

@GenerateNiceMocks([
  MockSpec<PositionsRepository>(),
  MockSpec<MembershipRepository>(),
])
import 'calendar_view_model_test.mocks.dart';

const _kGroup = MapGroup(id: 'g1', name: 'Equipe Norte');
const _kBia = GroupMember(name: 'Bia', email: 'bia@example.com');

/// Today's date at midnight (the controller reads the real clock).
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// The collaborators of a [CalendarViewModel]: the group [_kGroup] on the
/// map, whose history has [_kBia], trail days answered by [positions], and
/// a real [ObservedDayRepository] (in memory) holding the observed day.
class _Harness {
  _Harness({MapGroup? group = _kGroup}) {
    when(groupMap.selectedGroup).thenReturn(ValueNotifier<MapGroup?>(group));
    when(groupMap.loadHistoryMembers()).thenAnswer((_) async => const [_kBia]);
    when(
      positions.trailDays(any, any, any),
    ).thenAnswer((_) async => const <String>{});
    controller = CalendarViewModel(
      memberships: groupMap,
      observedDay: observedDay,
      positions: positions,
    );
  }

  final groupMap = MockMembershipRepository();
  final observedDay = ObservedDayRepository();
  final positions = MockPositionsRepository();
  late final CalendarViewModel controller;
}

void main() {
  group('CalendarViewModel - meses do histórico', () {
    test(
      'Happy Path: Deve marcar os dias com trilha do mês do dia observado',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final dayKey =
            '${_today().year.toString().padLeft(4, '0')}-'
            '${_today().month.toString().padLeft(2, '0')}-01';
        when(
          harness.positions.trailDays(_kGroup.id, [_kBia.email], any),
        ).thenAnswer((_) async => {dayKey});

        // 2. Act
        harness.controller.showObservedMonth();
        await pumpEventQueue();

        // 3. Assert
        final month = harness.controller.viewMonth.value;
        expect(month.first, DateTime(_today().year, _today().month));
        expect(month.trailDays, {dayKey});
        expect(harness.controller.isLoadingMonth.value, isFalse);
      },
    );

    test(
      'Happy Path: Deve mostrar e carregar o mês anterior ao voltar um mês',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final previous = DateTime(_today().year, _today().month - 1);

        // 2. Act
        harness.controller.showMonth(-1);
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.viewMonth.value.first, previous);
        final month =
            verify(
                  harness.positions.trailDays(_kGroup.id, any, captureAny),
                ).captured.single
                as HistoryMonth;
        expect(month.first, previous);
      },
    );

    test(
      'Edge Case: Deve marcar isLoadingMonth enquanto os dias com trilha são lidos',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final pending = Completer<Set<String>>();
        when(
          harness.positions.trailDays(any, any, any),
        ).thenAnswer((_) => pending.future);

        // 2. Act
        harness.controller.showObservedMonth();
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.isLoadingMonth.value, isTrue);
        pending.complete(const {});
        await pumpEventQueue();
      },
    );

    test(
      'Edge Case: Deve descartar os dias de um mês que a pessoa já deixou para trás',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final first = Completer<Set<String>>();
        final second = Completer<Set<String>>();
        final answers = [first, second];
        when(
          harness.positions.trailDays(any, any, any),
        ).thenAnswer((_) => answers.removeAt(0).future);
        harness.controller.showMonth(-1);
        await pumpEventQueue();
        harness.controller.showMonth(-1);
        await pumpEventQueue();

        // 2. Act
        first.complete({'stale'});
        await pumpEventQueue();

        // 3. Assert
        final month = harness.controller.viewMonth.value;
        expect(month.first, DateTime(_today().year, _today().month - 2));
        expect(month.trailDays, isEmpty);
        second.complete(const {});
        await pumpEventQueue();
      },
    );

    test(
      'Edge Case: Não deve ler dias com trilha quando nenhum grupo está no mapa',
      () async {
        // 1. Arrange
        final harness = _Harness(group: null);

        // 2. Act
        harness.controller.showObservedMonth();
        await pumpEventQueue();

        // 3. Assert
        verifyNever(harness.positions.trailDays(any, any, any));
        expect(harness.controller.isLoadingMonth.value, isFalse);
      },
    );

    test(
      'Sad Path: Deve manter o mês sem marcas e liberar isLoadingMonth quando a leitura falha',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.trailDays(any, any, any),
        ).thenAnswer((_) async => throw StateError('sem rede'));

        // 2. Act
        harness.controller.showObservedMonth();
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.viewMonth.value.trailDays, isEmpty);
        expect(harness.controller.isLoadingMonth.value, isFalse);
      },
    );
  });

  group('CalendarViewModel - avisos do mês à vista', () {
    test(
      'Edge Case: Não deve avisar viewMonth ao mostrar de novo o mês à vista sem dias com trilha',
      () async {
        // 1. Arrange
        final harness = _Harness();
        var notified = 0;
        harness.controller.viewMonth.addListener(() => notified++);

        // 2. Act
        harness.controller.showObservedMonth();
        await pumpEventQueue();

        // 3. Assert
        expect(notified, 0);
      },
    );

    test(
      'Happy Path: Deve avisar viewMonth uma vez quando os dias com trilha chegam',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final dayKey =
            '${_today().year.toString().padLeft(4, '0')}-'
            '${_today().month.toString().padLeft(2, '0')}-01';
        when(
          harness.positions.trailDays(any, any, any),
        ).thenAnswer((_) async => {dayKey});
        var notified = 0;
        harness.controller.viewMonth.addListener(() => notified++);

        // 2. Act
        harness.controller.showObservedMonth();
        await pumpEventQueue();

        // 3. Assert
        expect(notified, 1);
      },
    );
  });

  group('CalendarViewModel - dia observado', () {
    test('Happy Path: Deve observar o dia escolhido, sem a hora', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.controller.selectDay(DateTime(2026, 10, 30, 18, 45));

      // 3. Assert
      expect(harness.controller.observedDay.value, DateTime(2026, 10, 30));
      expect(harness.controller.isObservingToday, isFalse);
    });

    test('Happy Path: Deve voltar a observar hoje', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.selectDay(DateTime(2026, 10, 30));

      // 2. Act
      harness.controller.goToToday();

      // 3. Assert
      expect(harness.controller.observedDay.value, _today());
      expect(harness.controller.isObservingToday, isTrue);
    });

    test(
      'Happy Path: Deve guardar o dia escolhido no repositório compartilhado',
      () {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        harness.controller.selectDay(DateTime(2026, 10, 30, 18, 45));

        // 3. Assert
        expect(harness.observedDay.observedDay.value, DateTime(2026, 10, 30));
      },
    );

    test(
      'Edge Case: Deve seguir um dia escolhido diretamente no repositório',
      () {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        harness.observedDay.select(DateTime(2025, 3, 7));

        // 3. Assert
        expect(harness.controller.observedDay.value, DateTime(2025, 3, 7));
        expect(harness.controller.isObservingToday, isFalse);
      },
    );

    test('Edge Case: Deve começar observando hoje', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final observingToday = harness.controller.isObservingToday;

      // 3. Assert
      expect(observingToday, isTrue);
    });

    test('Happy Path: Deve reconhecer o dia de hoje', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final label = harness.controller.observedRelativeDay;

      // 3. Assert
      expect(label, RelativeDay.today);
    });

    test('Edge Case: Deve reconhecer o dia anterior como ontem', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.selectDay(_today().subtract(const Duration(days: 1)));

      // 2. Act
      final label = harness.controller.observedRelativeDay;

      // 3. Assert
      expect(label, RelativeDay.yesterday);
    });

    test('Edge Case: Deve tratar outros dias como um dia qualquer', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.selectDay(DateTime(2025, 3, 7));

      // 2. Act
      final label = harness.controller.observedRelativeDay;

      // 3. Assert
      expect(label, RelativeDay.other);
    });
  });

  group('CalendarViewModel - avisos e descarte', () {
    test('Happy Path: Deve avisar uma vez quando outro dia é observado', () {
      // 1. Arrange
      final harness = _Harness();
      var notified = 0;
      harness.controller.observedDay.addListener(() => notified++);

      // 2. Act
      harness.controller.selectDay(DateTime(2025, 3, 7, 9));

      // 3. Assert
      expect(notified, 1);
    });

    test(
      'Edge Case: Não deve avisar quando o mesmo dia é escolhido em outra hora',
      () {
        // 1. Arrange
        final harness = _Harness();
        harness.controller.selectDay(DateTime(2025, 3, 7, 9));
        var notified = 0;
        harness.controller.observedDay.addListener(() => notified++);

        // 2. Act
        harness.controller.selectDay(DateTime(2025, 3, 7, 18, 45));

        // 3. Assert
        expect(notified, 0);
      },
    );

    test(
      'Edge Case: Não deve avisar ao voltar para hoje já observando hoje',
      () {
        // 1. Arrange
        final harness = _Harness();
        var notified = 0;
        harness.controller.observedDay.addListener(() => notified++);

        // 2. Act
        harness.controller.goToToday();

        // 3. Assert
        expect(notified, 0);
      },
    );

    test(
      'Sad Path: Deve ignorar sem erro os dias com trilha que chegam depois do descarte',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final pending = Completer<Set<String>>();
        when(
          harness.positions.trailDays(any, any, any),
        ).thenAnswer((_) => pending.future);
        harness.controller.showObservedMonth();
        await pumpEventQueue();
        harness.controller.dispose();

        // 2. Act
        pending.complete({'2026-11-01'});

        // 3. Assert
        await expectLater(pumpEventQueue(), completes);
      },
    );

    test('Sad Path: Não deve lançar ao escolher um dia depois do descarte', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.dispose();

      // 2. Act
      void act() => harness.controller.selectDay(DateTime(2026, 10, 30));

      // 3. Assert
      expect(act, returnsNormally);
    });

    test(
      'Edge Case: Deve deixar o repositório do dia observado aberto ao ser descartado',
      () {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        harness.controller.dispose();
        harness.observedDay.select(DateTime(2025, 3, 7));

        // 3. Assert
        expect(harness.observedDay.observedDay.value, DateTime(2025, 3, 7));
      },
    );

    test(
      'Sad Path: Não deve mudar o dia observado ao escolher um dia depois do descarte',
      () {
        // 1. Arrange
        final harness = _Harness();
        final before = harness.observedDay.observedDay.value;
        harness.controller.dispose();

        // 2. Act
        harness.controller.selectDay(DateTime(2025, 3, 7));

        // 3. Assert
        expect(harness.observedDay.observedDay.value, before);
      },
    );

    test(
      'Sad Path: Não deve mudar o dia observado ao voltar para hoje depois do descarte',
      () {
        // 1. Arrange
        final harness = _Harness();
        harness.observedDay.select(DateTime(2025, 3, 7));
        harness.controller.dispose();

        // 2. Act
        harness.controller.goToToday();

        // 3. Assert
        expect(harness.observedDay.observedDay.value, DateTime(2025, 3, 7));
      },
    );

    test('Edge Case: Deve aceitar um segundo descarte sem lançar', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.dispose();

      // 2. Act
      void act() => harness.controller.dispose();

      // 3. Assert
      expect(act, returnsNormally);
    });
  });
}
