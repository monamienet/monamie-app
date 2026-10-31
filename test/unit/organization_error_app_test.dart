import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_error_app.dart';

import '../support/test_organization.dart';

const loadError =
    'Could not fetch http://localhost:5000/organization/id.txt (HTTP 404). Run '
    '"dart run tool/organization.dart web <id>" before building or running the '
    'web app.';

/// Finds the [SelectableText] whose text is exactly [message].
Finder selectableMessage(String message) => find.byWidgetPredicate(
  (widget) => widget is SelectableText && widget.data == message,
);

void main() {
  group('OrganizationErrorApp - Unit Test Suite', () {
    testWidgets('Happy Path: shows the load error message', (tester) async {
      // 1. Arrange
      const app = OrganizationErrorApp(message: loadError);

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      expect(selectableMessage(loadError), findsOneWidget);
    });

    testWidgets('Happy Path: the message is selectable text', (tester) async {
      // 1. Arrange
      const app = OrganizationErrorApp(message: loadError);

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      expect(
        find.descendant(
          of: selectableMessage(loadError),
          matching: find.byType(EditableText),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Happy Path: the message is centered on the screen', (
      tester,
    ) async {
      // 1. Arrange
      const app = OrganizationErrorApp(message: 'No organization.');
      final screenCenter =
          tester.view.physicalSize.center(Offset.zero) /
          tester.view.devicePixelRatio;

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      final messageCenter = tester.getCenter(
        selectableMessage('No organization.'),
      );
      expect(
        [messageCenter.dx, messageCenter.dy],
        [
          moreOrLessEquals(screenCenter.dx, epsilon: 1),
          moreOrLessEquals(screenCenter.dy, epsilon: 1),
        ],
      );
    });

    testWidgets('Happy Path: the message text is center-aligned', (
      tester,
    ) async {
      // 1. Arrange
      const app = OrganizationErrorApp(message: loadError);

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      expect(
        tester.widget<SelectableText>(selectableMessage(loadError)).textAlign,
        TextAlign.center,
      );
    });

    testWidgets('Happy Path: is a MaterialApp titled "MonAmie" without the '
        'debug banner', (tester) async {
      // 1. Arrange
      const app = OrganizationErrorApp(message: loadError);

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        [materialApp.title, materialApp.debugShowCheckedModeBanner],
        ['MonAmie', false],
      );
    });

    testWidgets('Edge Case: a multi-line message renders without errors', (
      tester,
    ) async {
      // 1. Arrange
      final message = List.generate(
        40,
        (index) =>
            'Line ${index + 1}: organizations/acme/organization.json is invalid.',
      ).join('\n');
      final app = OrganizationErrorApp(message: message);

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edge Case: a very long message on a phone-sized screen '
        'renders without overflow errors', (tester) async {
      // 1. Arrange
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final message = List.filled(300, loadError).join(' ');
      final app = OrganizationErrorApp(message: message);

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edge Case: an unbroken message wider than the screen renders '
        'without overflow errors', (tester) async {
      // 1. Arrange
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final message = 'x' * 2000;
      final app = OrganizationErrorApp(message: message);

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edge Case: an empty message renders without errors', (
      tester,
    ) async {
      // 1. Arrange
      const app = OrganizationErrorApp(message: '');

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edge Case: an empty message still builds the selectable '
        'text', (tester) async {
      // 1. Arrange
      const app = OrganizationErrorApp(message: '');

      // 2. Act
      await tester.pumpWidget(app);

      // 3. Assert
      expect(selectableMessage(''), findsOneWidget);
    });

    group('without an organization', () {
      setUp(Organization.debugReset);

      tearDown(() {
        Organization.debugReset();
        Organization.bind(testOrganization);
      });

      testWidgets('Sad Path: renders when no organization could be loaded', (
        tester,
      ) async {
        // 1. Arrange
        const app = OrganizationErrorApp(message: loadError);

        // 2. Act
        await tester.pumpWidget(app);

        // 3. Assert
        expect(
          [tester.takeException(), selectableMessage(loadError).evaluate()],
          [isNull, hasLength(1)],
        );
      });
    });
  });
}
