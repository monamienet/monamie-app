import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

import 'partner_directory.dart';

/// [PartnerDirectory] backed by the central `resolvePartners` function.
class CentralPartnerDirectory implements PartnerDirectory {
  CentralPartnerDirectory({this.functions, String? platform})
    : _platform = platform ?? (kIsWeb ? 'web' : 'android');

  /// Defaults to the central project's functions.
  final FirebaseFunctions? functions;
  final String _platform;

  @override
  Future<List<PartnerCandidate>> partnersOfSignedInUser() async {
    final functions = this.functions ?? CentralFirebase.functions;
    final result = await functions
        .httpsCallable(
          'resolvePartners',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call<Object?>({'platform': _platform});
    return parsePartnerCandidates(result.data);
  }
}

/// Reads the `resolvePartners` response. Only partners whose `status` is
/// `active` are kept: the screens for the other statuses come with the
/// in-app creation, plans and deletion flows. Entries with an invalid id or
/// incomplete options are skipped, so one bad partner cannot block the
/// others.
List<PartnerCandidate> parsePartnerCandidates(Object? data) {
  final partners = data is Map ? data['partners'] : null;
  if (partners is! List) return const [];
  final candidates = <PartnerCandidate>[];
  for (final entry in partners) {
    if (entry case {
      'id': final String id,
      'status': 'active',
      'options': final Map<Object?, Object?> options,
    } when partnerIdProblem(id) == null) {
      String? text(String key) {
        final value = options[key];
        return value is String && value.isNotEmpty ? value : null;
      }

      final apiKey = text('apiKey');
      final appId = text('appId');
      final projectId = text('projectId');
      final senderId = text('messagingSenderId');
      if (apiKey == null ||
          appId == null ||
          projectId == null ||
          senderId == null) {
        debugPrint('Skipping partner $id: incomplete Firebase options.');
        continue;
      }
      candidates.add(
        PartnerCandidate(
          id: id,
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            projectId: projectId,
            messagingSenderId: senderId,
            authDomain: text('authDomain'),
            storageBucket: text('storageBucket'),
          ),
        ),
      );
    }
  }
  candidates.sort((a, b) => a.id.compareTo(b.id));
  return candidates;
}
