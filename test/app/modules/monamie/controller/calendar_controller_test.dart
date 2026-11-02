import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/modules/monamie/history/history_month.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';

@GenerateNiceMocks([MockSpec<FirebaseProvider>(), MockSpec<GroupMapState>()])
import 'calendar_controller_test.mocks.dart';

const _kGroup = MapGroup(id: 'g1', name: 'Equipe Norte');
const _kBia = GroupMember(name: 'Bia', email: 'bia@example.com');

/// Today's date at midnight (the controller reads the real clock).
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// The collaborators of a [CalendarController]: the group [_kGroup] on the
/// map, whose history has [_kBia], and trail days answered by [trailDays].
class _Harness {
  _Harness({MapGroup? group = _kGroup}) {
    when(groupMap.selectedGroup).thenReturn(Rxn<MapGroup>(group));
    when(groupMap.loadHistoryMembers()).thenAnswer((_) async => const [_kBia]);
    when(
      positions.trailDays(any, any, any),
    ).thenAnswer((_) async => const <String>{});
    controller = CalendarController(groupMap: groupMap, positions: positions);
  }

  final groupMap = MockGroupMapState();
  final positions = MockFirebaseProvider();
  late final CalendarController controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  group('CalendarController - meses do histórico', () {
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

  group('CalendarController - dia observado', () {
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

    test('Edge Case: Deve começar observando hoje', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final observingToday = harness.controller.isObservingToday;

      // 3. Assert
      expect(observingToday, isTrue);
    });

    test('Happy Path: Deve chamar o dia de hoje de "Hoje"', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final label = harness.controller.observedDayFormatted;

      // 3. Assert
      expect(label, 'Hoje');
    });

    test('Edge Case: Deve chamar o dia anterior de "Ontem"', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.selectDay(_today().subtract(const Duration(days: 1)));

      // 2. Act
      final label = harness.controller.observedDayFormatted;

      // 3. Assert
      expect(label, 'Ontem');
    });

    test('Edge Case: Deve mostrar outros dias como dd/mm/aaaa', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.selectDay(DateTime(2025, 3, 7));

      // 2. Act
      final label = harness.controller.observedDayFormatted;

      // 3. Assert
      expect(label, '07/03/2025');
    });
  });
}
