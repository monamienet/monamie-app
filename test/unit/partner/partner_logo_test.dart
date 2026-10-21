import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_logo.dart';

import '../../support/test_partner.dart';

const validSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">'
    '<rect width="10" height="10" fill="#112233"/></svg>';

/// Finds the [SvgPicture] that shows the bundled asset [assetName].
Finder svgAsset(String assetName) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName == assetName,
);

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  tearDown(() => Partner.bind(testPartner));

  group('PartnerLogo - Unit Test Suite', () {
    testWidgets('Happy Path: a partner with a valid logo shows the SVG, not '
        'its name', (tester) async {
      // 1. Arrange
      const partner = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        logoSvg: validSvg,
      );

      // 2. Act
      await tester.pumpWidget(
        host(const PartnerLogo(width: 100, height: 50, partner: partner)),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(
        [find.byType(SvgPicture), find.text('Acme')],
        [findsOneWidget, findsNothing],
      );
    });

    testWidgets('Happy Path: no bound partner shows the MonAmie logo asset', (
      tester,
    ) async {
      // 1. Arrange
      Partner.debugReset();

      // 2. Act
      await tester.pumpWidget(host(const PartnerLogo(width: 100, height: 50)));

      // 3. Assert
      expect(svgAsset(MonAmieBrand.logoAsset), findsOneWidget);
    });

    testWidgets('Happy Path: a null partner uses the bound partner', (
      tester,
    ) async {
      // 1. Arrange
      Partner.bind(const PartnerConfig(id: 'beta', name: 'Beta'));

      // 2. Act
      await tester.pumpWidget(host(const PartnerLogo(width: 100, height: 50)));

      // 3. Assert
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('Edge Case: useBoundPartner false shows MonAmie even with a '
        'bound partner', (tester) async {
      // 1. Arrange
      Partner.bind(const PartnerConfig(id: 'beta', name: 'Beta'));

      // 2. Act
      await tester.pumpWidget(
        host(const PartnerLogo(width: 100, height: 50, useBoundPartner: false)),
      );

      // 3. Assert
      expect(svgAsset(MonAmieBrand.logoAsset), findsOneWidget);
    });

    testWidgets('Edge Case: a partner without a logo shows its name as text', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await tester.pumpWidget(
        host(const PartnerLogo(width: 100, height: 50, partner: partner)),
      );

      // 3. Assert
      expect(find.text('Acme Tours'), findsOneWidget);
    });

    testWidgets('Edge Case: the name is written in the partner primary color', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        primaryColor: Color(0xFF0ABAB5),
      );

      // 2. Act
      await tester.pumpWidget(
        host(const PartnerLogo(width: 100, height: 50, partner: partner)),
      );

      // 3. Assert
      final text = tester.widget<Text>(find.text('Acme'));
      expect(text.style?.color, const Color(0xFF0ABAB5));
    });

    testWidgets('Edge Case: an explicit partner wins over the bound one', (
      tester,
    ) async {
      // 1. Arrange
      Partner.bind(const PartnerConfig(id: 'beta', name: 'Beta'));
      const partner = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      await tester.pumpWidget(
        host(const PartnerLogo(width: 100, height: 50, partner: partner)),
      );

      // 3. Assert
      expect(
        [find.text('Acme'), find.text('Beta')],
        [findsOneWidget, findsNothing],
      );
    });

    testWidgets('Sad Path: an SVG that does not parse shows the name as '
        'text', (tester) async {
      // 1. Arrange
      const partner = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        logoSvg: '<!-- not an svg -->',
      );

      // 2. Act
      await tester.pumpWidget(
        host(const PartnerLogo(width: 100, height: 50, partner: partner)),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.text('Acme'), findsOneWidget);
    });
  });
}
