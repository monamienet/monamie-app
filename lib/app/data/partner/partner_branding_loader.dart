import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';

import 'partner_binding.dart';
import 'partner_directory.dart';
import 'partner_session.dart';

/// Path of the branding document in every partner project.
const brandingDocumentPath = 'config/branding';

const _brandingTimeout = Duration(seconds: 10);

/// Reads a partner's public branding document and pairs it with the
/// partner's Firebase options.
class PartnerBrandingLoader {
  const PartnerBrandingLoader();

  /// The binding of [candidate]. A branding that cannot be read never blocks
  /// the sign-in: the partner then shows its fallbacks (the capitalized id as
  /// name, MonAmie colors, the name instead of a logo).
  Future<PartnerBinding> load(PartnerCandidate candidate) async {
    final binding = PartnerBinding(
      partner: PartnerConfig.fromBranding(candidate.id, null),
      options: candidate.options,
    );
    return PartnerBinding(
      partner: await readBranding(binding),
      options: candidate.options,
    );
  }

  /// The current branding of [binding]'s partner, or its stored one when the
  /// document cannot be read.
  Future<PartnerConfig> readBranding(PartnerBinding binding) async {
    try {
      final app = await partnerFirebaseApp(binding);
      final snapshot = await FirebaseFirestore.instanceFor(
        app: app,
      ).doc(brandingDocumentPath).get().timeout(_brandingTimeout);
      return PartnerConfig.fromBranding(binding.partner.id, snapshot.data());
    } catch (error) {
      debugPrint('Could not read the branding of ${binding.partner.id}: $error');
      return binding.partner;
    }
  }
}
