import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'partner.dart';
import 'partner_config.dart';

/// The partner's logo with its name, shown on the login screen. Every
/// partner provides it at `partners/<id>/logo-com-texto.svg`, the file name
/// of the onboarding form upload.
const partnerLogoFileName = 'logo-com-texto.svg';

/// Path of the logo, relative to the web app's base URL, staged by
/// `dart run tool/partner.dart web <id>`.
const webPartnerLogoPath = 'partner/$partnerLogoFileName';

/// Asset key of partner [id]'s logo: a flavor-only asset, bundled only into
/// the `--flavor <id>` build.
String partnerLogoAssetKey(String id) => 'partners/$id/$partnerLogoFileName';

/// The logo of the partner of this build.
///
/// Mobile builds read the flavor-only asset; web has no flavor assets, so it
/// fetches the staged copy at [webPartnerLogoPath]. If the logo can't be
/// loaded, the partner's display name is shown in its place.
class PartnerLogo extends StatelessWidget {
  const PartnerLogo({
    super.key,
    required this.width,
    required this.height,
    this.partner,
    this.web = kIsWeb,
    this.base,
    this.httpClient,
  });

  final double width;
  final double height;

  /// Defaults to [Partner.current].
  final PartnerConfig? partner;

  /// Whether to fetch the staged web copy instead of the bundled asset.
  final bool web;

  /// Base URL the web copy is resolved against. Defaults to [Uri.base].
  final Uri? base;

  /// Client for the web fetch. Defaults to a new one per request.
  final http.Client? httpClient;

  @override
  Widget build(BuildContext context) {
    final partner = this.partner ?? Partner.current;
    final label = partner.displayName;

    Widget fallback(BuildContext context, Object error, StackTrace _) {
      debugPrint('Could not load the partner logo: $error');
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      );
    }

    // Keeps the layout steady while the web copy downloads.
    Widget placeholder(BuildContext context) =>
        SizedBox(width: width, height: height);

    if (web) {
      return SvgPicture.network(
        (base ?? Uri.base).resolve(webPartnerLogoPath).toString(),
        httpClient: httpClient,
        width: width,
        height: height,
        semanticsLabel: label,
        placeholderBuilder: placeholder,
        errorBuilder: fallback,
      );
    }
    return SvgPicture.asset(
      partnerLogoAssetKey(partner.id),
      width: width,
      height: height,
      semanticsLabel: label,
      placeholderBuilder: placeholder,
      errorBuilder: fallback,
    );
  }
}
