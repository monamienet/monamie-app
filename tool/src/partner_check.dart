import 'package:monamie_app/app/config/partner/group_address.dart';

import 'branding.dart';
import 'firebase_cli.dart';
import 'firestore_documents.dart';
import 'group_directory.dart';
import 'partners.dart';

/// The outcome of one readiness check: [problem] is `null` when it passed.
class CheckResult {
  const CheckResult(this.label, [this.problem]);

  final String label;
  final String? problem;

  bool get passed => problem == null;
}

/// Checks that partner [id] has the three things the app needs before it can
/// be activated: its Firebase project with the MonAmie apps registered, its
/// root group with subgroups named `<id>NN`, and a branding name.
///
/// Every check runs even when an earlier one fails, so one run lists
/// everything left to do.
Future<List<CheckResult>> checkPartner({
  required String id,
  required FirebaseCli cli,
  required GroupDirectory groups,
  required FirestoreDocuments firestore,
  String? plan,
}) async {
  checkPartnerId(id);
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
    await _check('Root group ${rootGroupEmail(id)}', () async {
      final members = await groups.members(rootGroupEmail(id));
      final misnamed = [
        for (final member in members)
          if (member.isGroup && !_isSubgroupOf(id, member.email)) member.email,
      ];
      return misnamed.isEmpty
          ? null
          : 'subgroups not named ${id}NN@monamienet.org (a team), so the app '
                'cannot find their members: ${misnamed.join(', ')}.';
    }),
    await _check('Branding name (${brandingDocumentPath(id)})', () async {
      final branding = await firestore.get(
        projectId: projectId,
        path: brandingDocumentPath(id),
      );
      final name = branding?['name'];
      return name is String && name.trim().isNotEmpty
          ? null
          : 'missing. Run `dart run tool/partner.dart publish $id --name ...`.';
    }),
  ];
}

/// Whether [email] is a team group of partner [id]: `<id>NN@`, 01–99.
bool _isSubgroupOf(String id, String email) {
  final address = parseGroupAddress(email);
  return address != null &&
      address.partnerId == id &&
      address.level == GroupLevel.team;
}

Future<CheckResult> _check(String label, Future<String?> Function() run) async {
  try {
    return CheckResult(label, await run());
  } on PartnerToolException catch (error) {
    return CheckResult(label, error.message);
  }
}
