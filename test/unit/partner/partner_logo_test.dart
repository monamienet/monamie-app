import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_icon.dart';
import 'package:monamie_app/app/config/partner/partner_logo.dart';

import '../../support/test_partner.dart';

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
    testWidgets('Happy Path: an explicit partner shows its icon tile', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      await tester.pumpWidget(
        host(const PartnerLogo(width: 100, height: 50, partner: partner)),
      );

      // 3. Assert
      expect(
        [find.byType(PartnerIcon), find.text('A')],
        [findsOneWidget, findsOneWidget],
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
      expect(find.text('B'), findsOneWidget);
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

    testWidgets('Sad Path: an explicit partner wins over the bound one', (
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
      expect([find.text('A'), find.text('B')], [findsOneWidget, findsNothing]);
    });
  });
}
