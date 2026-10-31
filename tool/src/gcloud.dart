import 'dart:io';

import 'access_token_source.dart';
import 'organizations.dart';

Future<String> _gcloud(List<String> args) async {
  final ProcessResult result;
  try {
    result = await Process.run('gcloud', args, runInShell: Platform.isWindows);
  } on ProcessException {
    throw OrganizationToolException(
      "Could not run 'gcloud'. Install the Google Cloud CLI and sign in with "
      '`gcloud auth login` using your monamienet.org account.',
    );
  }
  if (result.exitCode != 0) {
    throw OrganizationToolException(
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
