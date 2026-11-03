import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/config/dependencies.dart';

import '../../testing/fakes/repositories/fake_organization_branding_loader.dart';
import '../../testing/fakes/repositories/fake_organization_session.dart';
import '../support/test_app.dart';

/// The composition root is checked against [TestApp.dependencies], the
/// list the router tests open every route and the organization's scope
/// with: those tests fail when a route or the scope reads a type that list
/// does not provide, and this one fails when `appDependencies` does not
/// provide a type of that list, under the very same type.
///
/// The types are compared by the providers' runtime types
/// (`Provider<GroupsRepository>`), not by reading them: `appDependencies`
/// creates its objects lazily, on the first read, and creating them would
/// reach Firebase, Hive and the plugins, which tests do not have. Building
/// the list itself creates nothing.
void main() {
  group('appDependencies - Unit Test Suite', () {
    final provided = appDependencies(
      organizationSession: FakeOrganizationSession(),
      brandingLoader: FakeOrganizationBrandingLoader(),
    ).map((provider) => provider.runtimeType).toList();

    test('Happy Path: it provides every type the routes and the '
        "organization's scope read", () {
      // 1. Arrange
      final read = TestApp().dependencies.map((p) => p.runtimeType).toSet();

      // 2. Act
      final missing = read.difference(provided.toSet());

      // 3. Assert
      expect(missing, isEmpty);
    });

    test('Edge Case: it provides each type once', () {
      // 1. Arrange & 2. Act
      final repeated = [
        for (final type in provided.toSet())
          if (provided.where((t) => t == type).length > 1) type,
      ];

      // 3. Assert
      expect(repeated, isEmpty);
    });
  });
}
