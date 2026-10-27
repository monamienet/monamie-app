import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_icon.dart';

/// Finds the [SvgPicture] that shows the bundled asset [assetName].
Finder svgAsset(String assetName) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName == assetName,
);

/// The color of the tile behind the initial [letter].
Color? tileColorBehind(WidgetTester tester, String letter) {
  final tile = tester.widget<Container>(
    find.ancestor(of: find.text(letter), matching: find.byType(Container)),
  );
  return (tile.decoration as BoxDecoration?)?.color;
}

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PartnerIcon - Unit Test Suite', () {
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

    testWidgets('Happy Path: a partner without a logo shows its initial', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));

      // 3. Assert
      expect(
        [find.text('A'), find.byType(Image)],
        [findsOneWidget, findsNothing],
      );
    });

    testWidgets('Edge Case: a lower case name gives an upper case initial', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(id: 'acme', name: 'rota sul');

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));

      // 3. Assert
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('Edge Case: a partner without a theme gets a Grafite tile', (
      tester,
    ) async {
      // 1. Arrange
      const partner = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      await tester.pumpWidget(host(const PartnerIcon(partner: partner)));

      // 3. Assert
      expect(tileColorBehind(tester, 'A'), const Color(0xFF3F4754));
    });

    testWidgets('Sad Path: a logo that does not decode falls back to the '
        'initial', (tester) async {
      // 1. Arrange
      final partner = PartnerConfig(
        id: 'beta',
        name: 'beta',
        logoVersion: 3,
        logoPng: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
      );
      await tester.pumpWidget(host(PartnerIcon(partner: partner)));

      // 2. Act
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();

      // 3. Assert
      expect(find.text('B'), findsOneWidget);
    });
  });
}
