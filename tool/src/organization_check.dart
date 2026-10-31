import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

import 'branding.dart';
import 'firebase_cli.dart';
import 'firestore_documents.dart';
import 'memberships.dart';
import 'organizations.dart';

/// The outcome of one readiness check: [problem] is `null` when it passed.
class CheckResult {
  const CheckResult(this.label, [this.problem]);

  final String label;
  final String? problem;

  bool get passed => problem == null;
}

/// Checks that organization [id] has what the app needs before it can be
/// activated: its Firebase project with the MonAmie apps registered, at
/// least one administrator whose memberships agree with the central
/// `accounts` index, and a branding name. [accessToken] reads the
/// memberships and `accounts`, which no client may read.
///
/// Every check runs even when an earlier one fails, so one run lists
/// everything left to do.
Future<List<CheckResult>> checkOrganization({
  required String id,
  required FirebaseCli cli,
  required FirestoreDocuments firestore,
  required String accessToken,
  String? plan,
}) async {
  checkOrganizationId(id);
  final projectId = firebaseProjectId(id, plan: plan);
  return [
    await _check("Android app $appPackageName in $projectId", () async {
      final apps = await cli.listAndroidApps(projectId);
      final count = apps.where((a) => a.packageName == appPackageName).length;
      return count == 1
          ? null
          : 'expected exactly one, found $count. Register it (without a '
                'SHA-1) in the Firebase console.';
    }),
    await _check('Web app in $projectId', () async {
      final apps = await cli.listWebApps(projectId);
      return apps.length == 1
          ? null
          : 'expected exactly one, found ${apps.length}: '
                '${apps.isEmpty ? '(none)' : apps.join(', ')}.';
    }),
    await _check('Memberships (${organizationMembershipsPath(id)})', () async {
      final memberships = await firestore.list(
        projectId: projectId,
        collectionPath: organizationMembershipsPath(id),
        accessToken: accessToken,
      );
      final accounts = {
        for (final membership in memberships)
          membership.id: await firestore.get(
            projectId: centralProjectId,
            path: FirestorePaths.account(membership.id),
            accessToken: accessToken,
          ),
      };
      return membershipProblem(id, memberships, accounts);
    }),
    await _check('Branding name (${brandingDocumentPath(id)})', () async {
      final branding = await firestore.get(
        projectId: projectId,
        path: brandingDocumentPath(id),
      );
      final name = branding?['name'];
      return name is String && name.trim().isNotEmpty
          ? null
          : 'missing. Run `dart run tool/organization.dart publish $id --name ...`.';
    }),
  ];
}

Future<CheckResult> _check(String label, Future<String?> Function() run) async {
  try {
    return CheckResult(label, await run());
  } on OrganizationToolException catch (error) {
    return CheckResult(label, error.message);
  }
}
