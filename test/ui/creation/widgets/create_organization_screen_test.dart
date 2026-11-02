import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/data/repositories/theme/theme_catalog.dart';
import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'package:monamie_app/ui/creation/widgets/create_organization_screen.dart';
import 'package:monamie_app/data/repositories/creation/creation_repository.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<CreationRepository>(), MockSpec<ThemeCatalog>()])
import 'create_organization_screen_test.mocks.dart';

const _white = Color(0xFFFFFFFF);

final oceano = OrganizationTheme(
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

/// The `create` stub of [repository], with any arguments.
Future<Result<String>> anyCreate() => repository.create(
  id: anyNamed('id'),
  name: anyNamed('name'),
  themeId: anyNamed('themeId'),
  plan: anyNamed('plan'),
);

/// Makes `create` wait on [wait] before returning `active` or, with
/// [failure], an [Err] with that message.
void stubCreate(Future<void> Function() wait, {String? failure}) {
  when(anyCreate()).thenAnswer((_) async {
    await wait();
    return failure == null ? const Ok('active') : Err(failure);
  });
}

late MockCreationRepository repository;
late MockThemeCatalog catalog;

final _createButton = find.widgetWithText(FilledButton, 'Criar organização');
final _enterButton = find.widgetWithText(FilledButton, 'Entrar na Rota Sul');
final _planFooter = find.widgetWithText(
  FilledButton,
  'Continuar com Community',
);

/// Shows the view on a screen tall enough for every step without scrolling.
Future<void> pumpView(
  WidgetTester tester, {
  Future<Result<void>> Function()? onReady,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final controller = CreateOrganizationViewModel(
    repository: repository,
    themes: catalog,
    debounce: Duration.zero,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: CreateOrganizationScreen(
        controller: controller,
        ownerEmail: 'ana@example.com',
        onReady: onReady ?? () async => const Ok(null),
      ),
    ),
  );
  await tester.pump();
}

/// Name "Rota Sul" (id "rotasul", available), theme Oceano, plan Community:
/// leaves the view on the Review.
Future<void> goToReview(
  WidgetTester tester, {
  Future<Result<void>> Function()? onReady,
}) async {
  await pumpView(tester, onReady: onReady);
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
  provideDummy<Result<String?>>(const Ok(null));
  provideDummy<Result<String>>(const Ok('active'));

  setUp(() {
    repository = MockCreationRepository();
    when(repository.idProblem(any)).thenAnswer((_) async => const Ok(null));
    stubCreate(() async {});
    catalog = MockThemeCatalog();
    when(catalog.themes()).thenAnswer(
      (_) async => {
        for (final t in [defaultOrganizationTheme, oceano]) t.id: t,
      },
    );
  });

  group('CreateOrganizationScreen - Unit Test Suite', () {
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
        verifyNever(anyCreate());
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
        verifyNever(anyCreate());
      },
    );

    testWidgets(
      'Edge Case: a second tap while creating shows the busy button and does '
      'not create twice',
      (tester) async {
        // 1. Arrange
        final gate = Completer<void>();
        stubCreate(() => gate.future);
        await goToReview(tester);
        await acceptTerms(tester);
        await tester.tap(_createButton);
        await tester.pump();

        // 2. Act
        await tester.tap(find.widgetWithText(FilledButton, 'Criando…'));
        await tester.pump();

        // 3. Assert
        verify(anyCreate()).called(1);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Criando…'),
              )
              .enabled,
          isFalse,
        );
        gate.complete();
        await tester.pump();
      },
    );

    testWidgets('Sad Path: an Err shows its message on the Review', (
      tester,
    ) async {
      // 1. Arrange
      stubCreate(() async {}, failure: 'Identificador já em uso.');
      await goToReview(tester);
      await acceptTerms(tester);

      // 2. Act
      await tester.tap(_createButton);
      await tester.pump();

      // 3. Assert
      expect(find.text('Identificador já em uso.'), findsOneWidget);
      expect(_createButton, findsOneWidget);
    });

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
        final sent = verify(
          repository.create(
            id: captureAnyNamed('id'),
            name: captureAnyNamed('name'),
            themeId: captureAnyNamed('themeId'),
            plan: captureAnyNamed('plan'),
          ),
        ).captured;
        expect(sent, ['rotasul', 'Rota Sul', 'oceano', 'community']);
        expect(_createButton, findsNothing);
        expect(
          find.widgetWithText(FilledButton, 'Entrar na Rota Sul'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Sad Path: Entrar shows the message of an Err from onReady', (
      tester,
    ) async {
      // 1. Arrange
      await goToReview(
        tester,
        onReady: () async => const Err('Não foi possível entrar agora.'),
      );
      await acceptTerms(tester);
      await tester.tap(_createButton);
      await tester.pump();

      // 2. Act
      await tester.tap(_enterButton);
      await tester.pump();

      // 3. Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Não foi possível entrar agora.'), findsOneWidget);
    });

    testWidgets('Happy Path: Entrar calls onReady and shows nothing on Ok', (
      tester,
    ) async {
      // 1. Arrange
      var entered = 0;
      await goToReview(
        tester,
        onReady: () async {
          entered++;
          return const Ok(null);
        },
      );
      await acceptTerms(tester);
      await tester.tap(_createButton);
      await tester.pump();

      // 2. Act
      await tester.tap(_enterButton);
      await tester.pump();

      // 3. Assert
      expect(entered, 1);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('CreateOrganizationScreen (lifecycle) - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the themes', (
      tester,
    ) async {
      // 1. Arrange
      final controller = CreateOrganizationViewModel(
        repository: repository,
        themes: catalog,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          home: CreateOrganizationScreen(
            controller: controller,
            ownerEmail: 'ana@example.com',
            onReady: () async => const Ok(null),
          ),
        ),
      );
      await tester.pump();

      // 3. Assert
      verify(catalog.themes()).called(1);
      expect(
        controller.state.themes.map((t) => t.id),
        unorderedEquals([defaultOrganizationTheme.id, 'oceano']),
      );
    });

    testWidgets('Edge Case: leaving the screen stops the pending id check', (
      tester,
    ) async {
      // 1. Arrange
      // Mounted as its route mounts it: the route's provider owns the
      // controller and disposes it when the route leaves.
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => CreateOrganizationViewModel(
              repository: repository,
              themes: catalog,
              debounce: const Duration(seconds: 1),
            ),
            child: Builder(
              builder: (context) => CreateOrganizationScreen(
                controller: context.read<CreateOrganizationViewModel>(),
                ownerEmail: 'ana@example.com',
                onReady: () async => const Ok(null),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Rota Sul');
      await tester.pump();

      // 2. Act
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));

      // 3. Assert
      verifyNever(repository.idProblem(any));
    });
  });
}
