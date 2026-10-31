import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

import 'organization_directory.dart';

/// [OrganizationDirectory] backed by the central `resolveOrganizations` function.
class CentralOrganizationDirectory implements OrganizationDirectory {
  CentralOrganizationDirectory({this.functions, String? platform})
    : _platform = platform ?? (kIsWeb ? 'web' : 'android');

  /// Defaults to the central project's functions.
  final FirebaseFunctions? functions;
  final String _platform;

  @override
  Future<List<OrganizationCandidate>> organizationsOfSignedInUser({
    bool fresh = false,
  }) async {
    final functions = this.functions ?? CentralFirebase.functions;
    final result = await functions
        .httpsCallable(
          'resolveOrganizations',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call<Object?>({
          'platform': _platform,
          'fresh': ?(fresh ? true : null),
        });
    return parseOrganizationCandidates(result.data);
  }
}

/// Reads the `resolveOrganizations` response. Only organizations whose `status` is
/// `active` are kept (the screens for the other statuses come with the
/// in-app creation, plans and deletion flows), with `owner` true only when
/// the server says so. Entries with an invalid id or
/// incomplete options are skipped, so one bad organization cannot block the
/// others.
List<OrganizationCandidate> parseOrganizationCandidates(Object? data) {
  final organizations = data is Map ? data['organizations'] : null;
  if (organizations is! List) return const [];
  final candidates = <OrganizationCandidate>[];
  for (final entry in organizations) {
    if (entry case {
      'id': final String id,
      'status': 'active',
      'options': final Map<Object?, Object?> options,
    } when organizationIdProblem(id) == null) {
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
        debugPrint('Skipping organization $id: incomplete Firebase options.');
        continue;
      }
      candidates.add(
        OrganizationCandidate(
          id: id,
          owner: entry['owner'] == true,
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
