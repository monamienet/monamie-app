import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/ui/administrators/view_models/administrators_view_model.dart';
import 'package:monamie_app/ui/administrators/widgets/administrators_screen.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

import '../../../../testing/fakes/repositories/fake_administrators_repository.dart';

void main() {
  group('AdministratorsScreen - Unit Test Suite', () {
    testWidgets('Happy Path: opening the screen loads the administrators', (
      tester,
    ) async {
      // 1. Arrange
      final repository = FakeAdministratorsRepository(
        organizations: {
          'rotasul': const OrganizationAdministrators(
            administrators: [Administrator(email: 'olga@x.com', owner: true)],
          ),
        },
      );
      final controller = AdministratorsViewModel(
        organizationId: 'rotasul',
        repository: repository,
      );

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: AdministratorsScreen(controller: controller),
        ),
      );
      await tester.pump();

      // 3. Assert
      expect(repository.argumentsOf('list'), [
        ['rotasul'],
      ]);
      expect(find.text('olga@x.com'), findsOneWidget);
    });
  });
}
