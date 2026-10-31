import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'monamie_brand.dart';
import 'organization_config.dart';
import 'organization_palette.dart';

/// The organization's square logo, for the organization picker, the app bar and
/// small spaces.
///
/// [organization] `null` shows the MonAmie mark. An organization without a logo (or
/// whose PNG does not decode) gets the first letter of its name in a
/// rounded tile of its primary color.
class OrganizationIcon extends StatelessWidget {
  const OrganizationIcon({
    super.key,
    required this.organization,
    this.size = 40,
  });

  final OrganizationConfig? organization;
  final double size;

  @override
  Widget build(BuildContext context) {
    final organization = this.organization;
    if (organization == null) {
      return SvgPicture.asset(
        MonAmieBrand.iconAsset,
        width: size,
        height: size,
        semanticsLabel: MonAmieBrand.name,
      );
    }
    final radius = BorderRadius.circular(size * 0.28);

    Widget initial(BuildContext context, [Object? error, StackTrace? _]) {
      if (error != null) {
        debugPrint('Could not decode the organization logo: $error');
      }
      final palette = OrganizationPalette.fromConfig(organization);
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: palette.primary, borderRadius: radius),
        child: Text(
          organization.name.characters.first.toUpperCase(),
          semanticsLabel: organization.name,
          style: TextStyle(
            color: palette.onPrimary,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final png = organization.logoPng;
    if (png == null) return initial(context);
    return ClipRRect(
      borderRadius: radius,
      child: Image.memory(
        png,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: organization.name,
        errorBuilder: initial,
      ),
    );
  }
}
