import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';
import 'package:monamie_app/app/data/theme/theme_catalog.dart';
import 'package:monamie_app/app/modules/creation/create_organization_controller.dart';
import 'package:monamie_app/app/modules/creation/create_organization_view.dart';
import 'package:monamie_app/app/modules/creation/creation_backend.dart';

const _white = Color(0xFFFFFFFF);

final oceano = PartnerTheme(
  id: 'oceano',
  name: 'Oceano',
  primary: const Color(0xFF0B7F7B),
  dark: const Color(0xFF0A3D3B),
  light: const Color(0xFFD3EEEC),
  onPrimary: _white,
  onDark: _white,
  order: 1,
  active: true,
);

/// One `create` call as the fake recorded it.
typedef CreateCall = ({String id, String name, String themeId, String plan});

/// [CreationBackend] where every id is available and `create` is recorded,
/// optionally waiting on [gate] and failing with [failure].
class FakeCreationBackend implements CreationBackend {
  final creates = <CreateCall>[];
  String status = 'active';
  Completer<void>? gate;
  Object? failure;

  @override
  Future<String?> idProblem(String id) async => null;

  @override
  Future<String> create({
    required String id,
    required String name,
    required String themeId,
    required String plan,
  }) async {
    creates.add((id: id, name: name, themeId: themeId, plan: plan));
    await gate?.future;
    if (failure case final failure?) throw failure;
    return status;
  }

  @override
  Future<List<Creation>> mine() => throw UnimplementedError();
}

class FakeThemeCatalog implements ThemeCatalog {
  @override
  Future<Map<String, PartnerTheme>> themes() async => {
    for (final t in [defaultPartnerTheme, oceano]) t.id: t,
  };
}

late FakeCreationBackend backend;

final _createButton = find.widgetWithText(FilledButton, 'Criar organização');
final _planFooter = find.widgetWithText(
  FilledButton,
  'Continuar com Community',
);

/// Shows the view on a screen tall enough for every step without scrolling.
Future<void> pumpView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final controller = CreateOrganizationController(
    backend: backend,
    themes: FakeThemeCatalog(),
    debounce: Duration.zero,
  );
  await tester.pumpWidget(
    GetMaterialApp(
      home: CreateOrganizationView(
        controller: controller..onStart(),
        ownerEmail: 'ana@example.com',
        onReady: () async {},
      ),
    ),
  );
  await tester.pump();
}

/// Name "Rota Sul" (id "rotasul", available), theme Oceano, plan Community:
/// leaves the view on the Review.
Future<void> goToReview(WidgetTester tester) async {
  await pumpView(tester);
  await tester.enterText(find.byType(TextField).first, 'Rota Sul');
  // Lets the zero debounce fire and the availability answer arrive.
  await tester.pump();
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pump();
  await tester.tap(find.text('Oceano'));
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pump();
  await tester.tap(_planFooter);
  await tester.pump();
}

Future<void> acceptTerms(WidgetTester tester) async {
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = FakeCreationBackend();
  });

  tearDown(Get.reset);

  group('CreateOrganizationView - Unit Test Suite', () {
    testWidgets(
      'Happy Path: the Plan footer opens the Review listing the plan, '
      'without creating',
      (tester) async {
        // 1. Arrange
        await goToReview(tester);
        await tester.tap(find.text('Alterar').last); // the Plano row
        await tester.pump();

        // 2. Act
        await tester.tap(_planFooter);
        await tester.pump();

        // 3. Assert
        expect(backend.creates, isEmpty);
        expect(_createButton, findsOneWidget);
        expect(find.text('Community'), findsOneWidget);
      },
    );

    testWidgets(
      'Edge Case: changing the plan from the Review and coming back keeps '
      'name, identifier, theme and the accepted terms',
      (tester) async {
        // 1. Arrange
        await goToReview(tester);
        await acceptTerms(tester);
        await tester.tap(find.text('Alterar').last); // the Plano row
        await tester.pump();

        // 2. Act
        await tester.tap(_planFooter);
        await tester.pump();

        // 3. Assert
        expect(find.text('Rota Sul'), findsWidgets);
        expect(find.text('rotasul'), findsOneWidget);
        expect(find.text('Oceano'), findsOneWidget);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
        expect(tester.widget<FilledButton>(_createButton).enabled, isTrue);
      },
    );

    testWidgets(
      'Edge Case: Criar organização does nothing until the terms are accepted',
      (tester) async {
        // 1. Arrange
        await goToReview(tester);

        // 2. Act
        await tester.tap(_createButton);
        await tester.pump();

        // 3. Assert
        expect(tester.widget<FilledButton>(_createButton).enabled, isFalse);
        expect(backend.creates, isEmpty);
      },
    );

    testWidgets(
      'Edge Case: a second tap while creating shows the busy button and does '
      'not create twice',
      (tester) async {
        // 1. Arrange
        backend.gate = Completer<void>();
        await goToReview(tester);
        await acceptTerms(tester);
        await tester.tap(_createButton);
        await tester.pump();

        // 2. Act
        await tester.tap(find.widgetWithText(FilledButton, 'Criando…'));
        await tester.pump();

        // 3. Assert
        expect(backend.creates, hasLength(1));
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Criando…'),
              )
              .enabled,
          isFalse,
        );
        backend.gate!.complete();
        await tester.pump();
      },
    );

    testWidgets(
      'Sad Path: a CreationException shows its message on the Review',
      (tester) async {
        // 1. Arrange
        backend.failure = const CreationException('Identificador já em uso.');
        await goToReview(tester);
        await acceptTerms(tester);

        // 2. Act
        await tester.tap(_createButton);
        await tester.pump();

        // 3. Assert
        expect(find.text('Identificador já em uso.'), findsOneWidget);
        expect(_createButton, findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: Criar organização creates once with the choices and shows '
      'the outcome',
      (tester) async {
        // 1. Arrange
        await goToReview(tester);
        await acceptTerms(tester);

        // 2. Act
        await tester.tap(_createButton);
        await tester.pump();

        // 3. Assert
        expect(backend.creates, [
          (
            id: 'rotasul',
            name: 'Rota Sul',
            themeId: 'oceano',
            plan: 'community',
          ),
        ]);
        expect(_createButton, findsNothing);
        expect(
          find.widgetWithText(FilledButton, 'Entrar na Rota Sul'),
          findsOneWidget,
        );
      },
    );
  });
}
