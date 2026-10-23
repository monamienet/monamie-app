import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'monamie_brand.dart';
import 'partner.dart';
import 'partner_config.dart';
import 'partner_palette.dart';

/// The logo with the name: the bound partner's, or MonAmie's when no
/// partner is bound.
///
/// A partner without a usable logo (missing, or an SVG that does not parse)
/// gets its name written in its own colors instead.
class PartnerLogo extends StatelessWidget {
  const PartnerLogo({
    super.key,
    required this.width,
    required this.height,
    this.partner,
    this.useBoundPartner = true,
  });

  final double width;
  final double height;

  /// The partner to show. When `null` and [useBoundPartner] is true, the
  /// bound partner ([Partner.current]) is used.
  final PartnerConfig? partner;

  /// Whether a `null` [partner] means the bound partner (true) or MonAmie.
  final bool useBoundPartner;

  @override
  Widget build(BuildContext context) {
    final partner = this.partner ?? (useBoundPartner ? Partner.current : null);
    if (partner == null) {
      return SvgPicture.asset(
        MonAmieBrand.logoAsset,
        width: width,
        height: height,
        semanticsLabel: MonAmieBrand.name,
      );
    }

    Widget nameAsText(BuildContext context, [Object? error, StackTrace? _]) {
      if (error != null) debugPrint('Could not load the partner logo: $error');
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            partner.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: PartnerPalette.fromConfig(partner).primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final svg = partner.logoSvg;
    if (svg == null) return nameAsText(context);
    return SvgPicture.string(
      svg,
      width: width,
      height: height,
      semanticsLabel: partner.name,
      errorBuilder: nameAsText,
    );
  }
}
