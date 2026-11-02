import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

/// An app with [rootScaffoldMessengerKey] and a button that runs [action]
/// through [runReportingErrors], storing what it returned in [returned].
Future<void> _pumpApp(
  WidgetTester tester, {
  Future<Result<int>> Function()? action,
  void Function(int?)? returned,
}) => tester.pumpWidget(
  MaterialApp(
    scaffoldMessengerKey: rootScaffoldMessengerKey,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final value = await runReportingErrors(
              context,
              action ?? () async => const Ok(0),
            );
            returned?.call(value);
          },
          child: const Text('run'),
        ),
      ),
    ),
  ),
);

void main() {
  group('runReportingErrors', () {
    testWidgets('Happy Path: an Ok returns its value and shows nothing', (
      tester,
    ) async {
      // 1. Arrange
      int? value;
      await _pumpApp(
        tester,
        action: () async => const Ok(7),
        returned: (v) => value = v,
      );

      // 2. Act
      await tester.tap(find.text('run'));
      await tester.pump();

      // 3. Assert
      expect(value, 7);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Sad Path: an Err returns null and shows title and message', (
      tester,
    ) async {
      // 1. Arrange
      int? value = -1;
      await _pumpApp(
        tester,
        action: () async => const Err('Tente de novo.', title: 'Erro de Login'),
        returned: (v) => value = v,
      );

      // 2. Act
      await tester.tap(find.text('run'));
      await tester.pump();

      // 3. Assert
      expect(value, isNull);
      expect(find.text('Tente de novo.'), findsOneWidget);
      expect(find.text('Erro de Login'), findsOneWidget);
    });

    testWidgets('Edge Case: an Err without a title shows only the message', (
      tester,
    ) async {
      // 1. Arrange
      await _pumpApp(tester, action: () async => const Err('Sem rede.'));

      // 2. Act
      await tester.tap(find.text('run'));
      await tester.pump();

      // 3. Assert
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Text>());
      expect(find.text('Sem rede.'), findsOneWidget);
    });
  });

  group('ScaffoldNoticePresenter', () {
    testWidgets('Happy Path: shows the notice through the root messenger', (
      tester,
    ) async {
      // 1. Arrange
      await _pumpApp(tester);

      // 2. Act
      const ScaffoldNoticePresenter().show(
        const UserNotice('Ele será encerrado.', title: 'Rastreamento'),
      );
      await tester.pump();

      // 3. Assert
      expect(find.text('Ele será encerrado.'), findsOneWidget);
      expect(find.text('Rastreamento'), findsOneWidget);
    });

    testWidgets('Sad Path: does nothing when no messenger is mounted', (
      tester,
    ) async {
      // 1. Arrange
      await tester.pumpWidget(const SizedBox.shrink());

      // 2. Act
      void act() =>
          const ScaffoldNoticePresenter().show(const UserNotice('Aviso.'));

      // 3. Assert
      expect(act, returnsNormally);
    });
  });
}
