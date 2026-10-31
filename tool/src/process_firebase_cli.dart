import 'dart:convert';
import 'dart:io';

import 'firebase_cli.dart';
import 'organizations.dart';

/// Hint appended to every failure: the CLI's own messages rarely say that the
/// cause is a missing project, sign-in or permission. Google answers 403 both
/// when the project does not exist and when the caller cannot read it.
String _accessHint(String? projectId) =>
    'Check that the Firebase project '
    "${projectId == null ? '' : "'$projectId' "}exists and that you can "
    'read it. Locally, sign in with `firebase login` (or '
    '`firebase login --reauth`). In CI, check that the config service account '
    'can read the project (docs/en-us/publish-internal-testing.md, steps A6 '
    'and C4).';

/// [FirebaseCli] backed by the `firebase` executable (firebase-tools).
///
/// Every call passes `--json`, so stdout holds only the CLI's
/// `{"status": ..., "result" | "error": ...}` envelope.
class ProcessFirebaseCli implements FirebaseCli {
  const ProcessFirebaseCli({this.executable = 'firebase'});

  final String executable;

  @override
  Future<List<FirebaseAndroidApp>> listAndroidApps(String projectId) async {
    final stdout = await _run([
      'apps:list',
      'ANDROID',
      '--project',
      projectId,
    ], projectId: projectId);
    return parseAppsListOutput(stdout, projectId: projectId);
  }

  @override
  Future<String> androidConfig({
    required String projectId,
    required String appId,
  }) async {
    final stdout = await _run([
      'apps:sdkconfig',
      'ANDROID',
      appId,
      '--project',
      projectId,
    ], projectId: projectId);
    return parseSdkConfigOutput(stdout, projectId: projectId);
  }

  @override
  Future<List<FirebaseWebApp>> listWebApps(String projectId) async {
    final stdout = await _run([
      'apps:list',
      'WEB',
      '--project',
      projectId,
    ], projectId: projectId);
    final result = _envelopeResult(stdout, 'apps:list', projectId);
    if (result is! List) throw _unexpectedOutput('apps:list');
    return [
      for (final app in result)
        if (app case {'appId': final String appId})
          FirebaseWebApp(
            appId: appId,
            displayName: app['displayName'] is String
                ? app['displayName'] as String
                : '',
          )
        else
          throw _unexpectedOutput('apps:list'),
    ];
  }

  @override
  Future<Map<String, Object?>> webConfig({
    required String projectId,
    required String appId,
  }) async {
    final stdout = await _run([
      'apps:sdkconfig',
      'WEB',
      appId,
      '--project',
      projectId,
    ], projectId: projectId);
    final result = _envelopeResult(stdout, 'apps:sdkconfig', projectId);
    if (result case {'sdkConfig': final Map<String, Object?> config}) {
      return config;
    }
    throw _unexpectedOutput('apps:sdkconfig');
  }

  Future<String> _run(List<String> args, {required String projectId}) async {
    final ProcessResult result;
    try {
      result = await Process.run(executable, [
        ...args,
        '--json',
        '--non-interactive',
      ], runInShell: Platform.isWindows);
    } on ProcessException {
      throw OrganizationToolException(
        "Could not run '$executable'. Install the Firebase CLI: "
        'npm install -g firebase-tools',
      );
    }
    // On failure the envelope still carries the error message, so the exit
    // code is only reported when stdout has no envelope.
    final stdout = result.stdout as String;
    if (result.exitCode != 0 && !_hasEnvelope(stdout)) {
      throw OrganizationToolException(
        "'$executable ${args.first}' failed with exit code "
        '${result.exitCode}. ${_accessHint(projectId)}',
      );
    }
    return stdout;
  }
}

/// Returns the apps in the `--json` output of `firebase apps:list ANDROID`.
///
/// Throws a [OrganizationToolException] when the CLI reported an error or the
/// output is not the expected envelope. [projectId], when given, is named in
/// the error message.
List<FirebaseAndroidApp> parseAppsListOutput(
  String stdout, {
  String? projectId,
}) {
  final result = _envelopeResult(stdout, 'apps:list', projectId);
  if (result is! List) throw _unexpectedOutput('apps:list');
  return [
    for (final app in result)
      if (app case {
        'appId': final String appId,
        'packageName': final String packageName,
      })
        FirebaseAndroidApp(appId: appId, packageName: packageName)
      else
        throw _unexpectedOutput('apps:list'),
  ];
}

/// Returns the `google-services.json` contents in the `--json` output of
/// `firebase apps:sdkconfig ANDROID <appId>`.
///
/// Throws a [OrganizationToolException] when the CLI reported an error or the
/// output is not the expected envelope. Messages never include the contents.
/// [projectId], when given, is named in the error message.
String parseSdkConfigOutput(String stdout, {String? projectId}) {
  final result = _envelopeResult(stdout, 'apps:sdkconfig', projectId);
  if (result case {'fileContents': final String contents}) return contents;
  throw _unexpectedOutput('apps:sdkconfig');
}

bool _hasEnvelope(String stdout) {
  try {
    return switch (jsonDecode(stdout)) {
      {'status': String _} => true,
      _ => false,
    };
  } on FormatException {
    return false;
  }
}

Object? _envelopeResult(String stdout, String command, String? projectId) {
  final Object? decoded;
  try {
    decoded = jsonDecode(stdout);
  } on FormatException {
    throw _unexpectedOutput(command);
  }
  switch (decoded) {
    case {'status': 'success', 'result': final result}:
      return result;
    case {'status': 'error', 'error': final String error}:
      throw OrganizationToolException(
        "'firebase $command' failed"
        "${projectId == null ? '' : " for project '$projectId'"}: "
        '$error ${_accessHint(projectId)}',
      );
    default:
      throw _unexpectedOutput(command);
  }
}

OrganizationToolException _unexpectedOutput(String command) =>
    OrganizationToolException(
      "Unexpected output from 'firebase $command --json'. "
      'Expected firebase-tools 15.x.',
    );
