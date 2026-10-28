import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'monamie_brand.dart';
import 'partner.dart';
import 'partner_config.dart';
import 'partner_icon.dart';

/// The big brand mark: the bound partner's square logo (or its initial
/// tile), or MonAmie's logo when no partner is bound.
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
    final side = width < height ? width : height;
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: PartnerIcon(partner: partner, size: side * 0.7),
      ),
    );
  }
}
