import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_icon.dart';

const validSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">'
    '<circle cx="5" cy="5" r="5" fill="#112233"/></svg>';

/// Finds the [SvgPicture] that shows the bundled asset [assetName].
Finder svgAsset(String assetName) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName == assetName,
);

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PartnerIcon - Unit Test Suite', () {
    testWidgets('Happy Path: a partner with a valid icon shows the SVG', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        iconSvg: validSvg,
      );

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(
        [find.byType(SvgPicture), find.byType(CircleAvatar)],
        [findsOneWidget, findsNothing],
      );
    });

    testWidgets('Happy Path: no partner shows the MonAmie icon asset', (
      tester,
    ) async {
      // 1. Arrange
      const PartnerConfig? partner = null;

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));

      // 3. Assert
      expect(svgAsset(MonAmieBrand.iconAsset), findsOneWidget);
    });

    testWidgets('Edge Case: a partner without an icon shows its initial', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));

      // 3. Assert
      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.text('A'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Edge Case: a lower case name gives an upper case initial', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(id: 'acme', name: 'acme tours');

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));

      // 3. Assert
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('Edge Case: the circle uses the partner primary color', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        primaryColor: Color(0xFF0ABAB5),
      );

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));

      // 3. Assert
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundColor, const Color(0xFF0ABAB5));
    });

    testWidgets('Edge Case: a partner without colors gets a MonAmie blue '
        'circle', (tester) async {
      // 1. Arrange
      const partner = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));

      // 3. Assert
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundColor, MonAmieBrand.primary);
    });

    testWidgets('Sad Path: an SVG that does not parse shows the initial', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(
        id: 'beta',
        name: 'Beta',
        iconSvg: '<!-- not an svg -->',
      );

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.text('B'), findsOneWidget);
    });
  });
}
