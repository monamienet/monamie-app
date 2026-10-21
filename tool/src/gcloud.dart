import 'dart:convert';
import 'dart:io';

import 'access_token_source.dart';
import 'group_directory.dart';
import 'partners.dart';

Future<String> _gcloud(List<String> args) async {
  final ProcessResult result;
  try {
    result = await Process.run('gcloud', args, runInShell: Platform.isWindows);
  } on ProcessException {
    throw PartnerToolException(
      "Could not run 'gcloud'. Install the Google Cloud CLI and sign in with "
      '`gcloud auth login` using your monamienet.org account.',
    );
  }
  if (result.exitCode != 0) {
    throw PartnerToolException(
      "'gcloud ${args.take(3).join(' ')}' failed: "
      '${(result.stderr as String).trim()}',
    );
  }
  return (result.stdout as String).trim();
}

/// [AccessTokenSource] from `gcloud auth print-access-token`.
class GcloudAccessTokenSource implements AccessTokenSource {
  const GcloudAccessTokenSource();

  @override
  Future<String> accessToken() => _gcloud(['auth', 'print-access-token']);
}

/// [GroupDirectory] from `gcloud identity groups memberships list`.
class GcloudGroupDirectory implements GroupDirectory {
  const GcloudGroupDirectory();

  @override
  Future<List<GroupMember>> members(String groupEmail) async {
    final stdout = await _gcloud([
      'identity',
      'groups',
      'memberships',
      'list',
      '--group-email=$groupEmail',
      '--format=json',
    ]);
    final decoded = jsonDecode(stdout.isEmpty ? '[]' : stdout);
    if (decoded is! List) {
      throw PartnerToolException(
        "Unexpected output from 'gcloud identity groups memberships list'.",
      );
    }
    return [
      for (final membership in decoded)
        if (membership case {'preferredMemberKey': {'id': final String email}})
          GroupMember(email: email, isGroup: membership['type'] == 'GROUP'),
    ];
  }
}
