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

final _subgroupSuffix = RegExp(r'^[0-9]{2}$');

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
}) async {
  checkPartnerId(id);
  final projectId = firebaseProjectId(id);
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
          : 'subgroups not named ${id}NN@monamienet.org, so the app cannot '
                'find their members: ${misnamed.join(', ')}.';
    }),
    await _check('Branding name ($brandingDocumentPath)', () async {
      final branding = await firestore.get(
        projectId: projectId,
        path: brandingDocumentPath,
      );
      final name = branding?['name'];
      return name is String && name.trim().isNotEmpty
          ? null
          : 'missing. Run `dart run tool/partner.dart publish $id --name ...`.';
    }),
  ];
}

bool _isSubgroupOf(String id, String email) {
  final normalized = email.trim().toLowerCase();
  const domain = '@monamienet.org';
  if (!normalized.endsWith(domain)) return false;
  final local = normalized.substring(0, normalized.length - domain.length);
  return local.length == id.length + 2 &&
      local.startsWith(id) &&
      _subgroupSuffix.hasMatch(local.substring(id.length));
}

Future<CheckResult> _check(String label, Future<String?> Function() run) async {
  try {
    return CheckResult(label, await run());
  } on PartnerToolException catch (error) {
    return CheckResult(label, error.message);
  }
}
