import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'monamie_brand.dart';
import 'partner_config.dart';
import 'partner_palette.dart';

/// The partner's square logo, for the organization picker, the app bar and
/// small spaces.
///
/// [partner] `null` shows the MonAmie mark. A partner without a logo (or
/// whose PNG does not decode) gets the first letter of its name in a
/// rounded tile of its primary color.
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
    final radius = BorderRadius.circular(size * 0.28);

    Widget initial(BuildContext context, [Object? error, StackTrace? _]) {
      if (error != null)
        debugPrint('Could not decode the partner logo: $error');
      final palette = PartnerPalette.fromConfig(partner);
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: palette.primary, borderRadius: radius),
        child: Text(
          partner.name.characters.first.toUpperCase(),
          semanticsLabel: partner.name,
          style: TextStyle(
            color: palette.onPrimary,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final png = partner.logoPng;
    if (png == null) return initial(context);
    return ClipRRect(
      borderRadius: radius,
      child: Image.memory(
        png,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: partner.name,
        errorBuilder: initial,
      ),
    );
  }
}
