import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/config/organization/organization_icon.dart';
import 'package:monamie_app/app/config/organization/organization_logo.dart';

import '../../support/test_organization.dart';

/// Finds the [SvgPicture] that shows the bundled asset [assetName].
Finder svgAsset(String assetName) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName == assetName,
);

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  tearDown(() => Organization.bind(testOrganization));

  group('OrganizationLogo - Unit Test Suite', () {
    testWidgets('Happy Path: an explicit organization shows its icon tile', (
      tester,
    ) async {
      // 1. Arrange
      const organization = OrganizationConfig(id: 'acme', name: 'Acme');

      // 2. Act
      await tester.pumpWidget(
        host(
          const OrganizationLogo(
            width: 100,
            height: 50,
            organization: organization,
          ),
        ),
      );

      // 3. Assert
      expect(
        [find.byType(OrganizationIcon), find.text('A')],
        [findsOneWidget, findsOneWidget],
      );
    });

    testWidgets(
      'Happy Path: no bound organization shows the MonAmie logo asset',
      (tester) async {
        // 1. Arrange
        Organization.debugReset();

        // 2. Act
        await tester.pumpWidget(
          host(const OrganizationLogo(width: 100, height: 50)),
        );

        // 3. Assert
        expect(svgAsset(MonAmieBrand.logoAsset), findsOneWidget);
      },
    );

    testWidgets('Happy Path: a null organization uses the bound organization', (
      tester,
    ) async {
      // 1. Arrange
      Organization.bind(const OrganizationConfig(id: 'beta', name: 'Beta'));

      // 2. Act
      await tester.pumpWidget(
        host(const OrganizationLogo(width: 100, height: 50)),
      );

      // 3. Assert
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets(
      'Edge Case: useBoundOrganization false shows MonAmie even with a '
      'bound organization',
      (tester) async {
        // 1. Arrange
        Organization.bind(const OrganizationConfig(id: 'beta', name: 'Beta'));

        // 2. Act
        await tester.pumpWidget(
          host(
            const OrganizationLogo(
              width: 100,
              height: 50,
              useBoundOrganization: false,
            ),
          ),
        );

        // 3. Assert
        expect(svgAsset(MonAmieBrand.logoAsset), findsOneWidget);
      },
    );

    testWidgets('Sad Path: an explicit organization wins over the bound one', (
      tester,
    ) async {
      // 1. Arrange
      Organization.bind(const OrganizationConfig(id: 'beta', name: 'Beta'));
      const organization = OrganizationConfig(id: 'acme', name: 'Acme');

      // 2. Act
      await tester.pumpWidget(
        host(
          const OrganizationLogo(
            width: 100,
            height: 50,
            organization: organization,
          ),
        ),
      );

      // 3. Assert
      expect([find.text('A'), find.text('B')], [findsOneWidget, findsNothing]);
    });
  });
}
