import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_member_model.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/person_row_tile.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/presence.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/team_rows.dart';

TeamRow rowOf(Presence presence, {String name = 'Ana Souza'}) => TeamRow(
  member: GoogleGroupMember(name: name, email: 'ana@x.org'),
  user: null,
  presence: presence,
);

const live = Presence(PresenceKind.live, 'Agora');
const stale = Presence(PresenceKind.stale, 'Há 12 min');
const off = Presence(PresenceKind.off, 'Localização desligada');
const never = Presence(PresenceKind.never, 'Ainda não ativou a localização');

class Taps {
  int trail = 0;
  int call = 0;
}

Future<void> pumpTile(
  WidgetTester tester, {
  required TeamRow row,
  required Taps taps,
  bool highlighted = false,
  bool withCall = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonRowTile(
          row: row,
          highlighted: highlighted,
          onToggleTrail: () => taps.trail++,
          onCall: withCall ? () => taps.call++ : null,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PersonRowTile - Widget Test Suite', () {
    testWidgets('Happy Path: shows the name and the presence label', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(stale), taps: taps);

      // 3. Assert
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Há 12 min'), findsOneWidget);
    });

    testWidgets('Happy Path: a live, highlighted person gets the trail note', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(live), taps: taps, highlighted: true);

      // 3. Assert
      expect(find.text('Agora · trajeto visível'), findsOneWidget);
    });

    testWidgets(
      'Happy Path: tapping the trail button calls onToggleTrail once',
      (tester) async {
        // 1. Arrange
        final taps = Taps();
        await pumpTile(tester, row: rowOf(live), taps: taps);

        // 2. Act
        await tester.tap(find.byTooltip('Mostrar trajeto de Ana Souza'));
        await tester.pump();

        // 3. Assert
        expect(taps.trail, 1);
      },
    );

    testWidgets('Happy Path: tapping the Meet button calls onCall once only', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();
      await pumpTile(tester, row: rowOf(live), taps: taps);

      // 2. Act
      await tester.tap(find.byTooltip('Chamar Ana Souza no Meet'));
      await tester.pump();

      // 3. Assert
      expect((taps.call, taps.trail), (1, 0));
    });

    testWidgets('Edge Case: a live person not highlighted has no trail note', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(live), taps: taps);

      // 3. Assert
      expect(find.text('Agora'), findsOneWidget);
      expect(find.textContaining('trajeto visível'), findsNothing);
    });

    testWidgets('Edge Case: a stale, highlighted person gets no trail note', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(stale), taps: taps, highlighted: true);

      // 3. Assert
      expect(find.text('Há 12 min'), findsOneWidget);
      expect(find.textContaining('trajeto visível'), findsNothing);
    });

    testWidgets('Edge Case: an off, highlighted person gets no trail note', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(off), taps: taps, highlighted: true);

      // 3. Assert
      expect(find.text('Localização desligada'), findsOneWidget);
      expect(find.textContaining('trajeto visível'), findsNothing);
    });

    testWidgets('Edge Case: a never-shared, highlighted person gets no note', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(never), taps: taps, highlighted: true);

      // 3. Assert
      expect(find.text('Ainda não ativou a localização'), findsOneWidget);
      expect(find.textContaining('trajeto visível'), findsNothing);
    });

    testWidgets('Edge Case: highlighted offers to hide the trail', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(live), taps: taps, highlighted: true);

      // 3. Assert
      expect(find.byTooltip('Esconder trajeto de Ana Souza'), findsOneWidget);
      expect(find.byTooltip('Mostrar trajeto de Ana Souza'), findsNothing);
    });

    testWidgets('Edge Case: not highlighted offers to show the trail', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(live), taps: taps);

      // 3. Assert
      expect(find.byTooltip('Mostrar trajeto de Ana Souza'), findsOneWidget);
      expect(find.byTooltip('Esconder trajeto de Ana Souza'), findsNothing);
    });

    testWidgets('Edge Case: the buttons are labeled for screen readers', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();
      final semantics = tester.ensureSemantics();

      // 2. Act
      await pumpTile(tester, row: rowOf(live), taps: taps, highlighted: true);

      // 3. Assert
      expect(
        find.bySemanticsLabel('Esconder trajeto de Ana Souza'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Chamar Ana Souza no Meet'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'Edge Case: tapping the trail button of a highlighted row calls it',
      (tester) async {
        // 1. Arrange
        final taps = Taps();
        await pumpTile(tester, row: rowOf(live), taps: taps, highlighted: true);

        // 2. Act
        await tester.tap(find.byTooltip('Esconder trajeto de Ana Souza'));
        await tester.pump();

        // 3. Assert
        expect((taps.trail, taps.call), (1, 0));
      },
    );

    testWidgets('Sad Path: without onCall there is no Meet button at all', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();

      // 2. Act
      await pumpTile(tester, row: rowOf(live), taps: taps, withCall: false);

      // 3. Assert
      expect(find.byTooltip('Chamar Ana Souza no Meet'), findsNothing);
      expect(find.byTooltip('Mostrar trajeto de Ana Souza'), findsOneWidget);
    });

    testWidgets('Sad Path: without onCall the trail button still works', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();
      await pumpTile(tester, row: rowOf(live), taps: taps, withCall: false);

      // 2. Act
      await tester.tap(find.byTooltip('Mostrar trajeto de Ana Souza'));
      await tester.pump();

      // 3. Assert
      expect((taps.trail, taps.call), (1, 0));
    });

    testWidgets('Sad Path: a long name is shown on one line without overflow', (
      tester,
    ) async {
      // 1. Arrange
      final taps = Taps();
      final longName = 'Maria ${'Sobrenome ' * 20}Final';

      // 2. Act
      await pumpTile(
        tester,
        row: rowOf(live, name: longName),
        taps: taps,
      );

      // 3. Assert
      expect(tester.takeException(), isNull);
      expect(find.text(longName), findsOneWidget);
    });
  });
}
