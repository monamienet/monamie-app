import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'monamie_brand.dart';
import 'partner_config.dart';
import 'partner_palette.dart';

/// The logo without text, for the partner picker and small spaces.
///
/// [partner] `null` shows the MonAmie mark. A partner without a usable icon
/// gets the first letter of its name in a circle of its primary color.
class PartnerIcon extends StatelessWidget {
  const PartnerIcon({super.key, required this.partner, this.size = 40});

  final PartnerConfig? partner;
  final double size;

  @override
  Widget build(BuildContext context) {
    final partner = this.partner;
    if (partner == null) {
      return SvgPicture.asset(
        MonAmieBrand.iconAsset,
        width: size,
        height: size,
        semanticsLabel: MonAmieBrand.name,
      );
    }

    Widget initial(BuildContext context, [Object? error, StackTrace? _]) {
      if (error != null) debugPrint('Could not load the partner icon: $error');
      final palette = PartnerPalette.fromConfig(partner);
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: palette.primary,
        child: Text(
          partner.name.characters.first.toUpperCase(),
          style: TextStyle(
            color: palette.onPrimary,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final svg = partner.iconSvg;
    if (svg == null) return initial(context);
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      semanticsLabel: partner.name,
      errorBuilder: initial,
    );
  }
}
