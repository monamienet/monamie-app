import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'monamie_brand.dart';
import 'organization.dart';
import 'organization_config.dart';
import 'organization_icon.dart';

/// The big brand mark: the bound organization's square logo (or its initial
/// tile), or MonAmie's logo when no organization is bound.
class OrganizationLogo extends StatelessWidget {
  const OrganizationLogo({
    super.key,
    required this.width,
    required this.height,
    this.organization,
    this.useBoundOrganization = true,
  });

  final double width;
  final double height;

  /// The organization to show. When `null` and [useBoundOrganization] is true, the
  /// bound organization ([Organization.current]) is used.
  final OrganizationConfig? organization;

  /// Whether a `null` [organization] means the bound organization (true) or MonAmie.
  final bool useBoundOrganization;

  @override
  Widget build(BuildContext context) {
    final organization =
        this.organization ??
        (useBoundOrganization ? Organization.current : null);
    if (organization == null) {
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
        child: OrganizationIcon(organization: organization, size: side * 0.7),
      ),
    );
  }
}
