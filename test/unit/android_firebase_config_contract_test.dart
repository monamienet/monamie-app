import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/android_firebase_config.dart';
import '../../tool/src/partners.dart';

/// Contract of the build-time Firebase config fetch (issue #39).
///
/// `google-services.json` holds API keys, so it is never versioned: the
/// Gradle build fetches it per partner with
/// `dart run tool/partner.dart firebase <id>` into the flavor source set,
/// `.gitignore` keeps it out of git, and the CI authenticates the build with
/// a read-only config service account that is separate from (and used
/// before) the Play publisher account.

const gradlePath = 'android/app/build.gradle.kts';
const gitignorePath = '.gitignore';
const ciWorkflowPath = '.github/workflows/deploy-play-internal.yml';

/// `.gitignore` pattern the spec requires.
const fetchedConfigIgnorePattern = 'android/app/src/*/google-services.json';

/// Previously versioned, unflavored config that must be gone from git.
const legacyConfigPath = 'android/app/google-services.json';

/// Firebase CLI version the CI must install.
const firebaseToolsVersion = '15.30.2';

/// Service account of the build (reads Firebase app configs only).
const configServiceAccount =
    'wlif-monamie-app-config@ci-cd-management.iam.gserviceaccount.com';

/// Service account that publishes to Google Play.
const playServiceAccount =
    'wlif-monamie-app-play@ci-cd-management.iam.gserviceaccount.com';

/// Name of the Gradle task that fetches the config of partner [id], per the
/// spec: `fetchFirebaseConfig<Id>`, with the first letter uppercased.
String specFetchTaskName(String id) =>
    'fetchFirebaseConfig${id[0].toUpperCase()}${id.substring(1)}';

/// Removes `//` line comments so commented-out code does not count.
String stripLineComments(String source) => source
    .split('\n')
    .map((line) {
      final index = line.indexOf('//');
      return index < 0 ? line : line.substring(0, index);
    })
    .join('\n');

/// Returns the pattern of the uncommented Kotlin `Regex("...")` that selects
/// `process<Variant>GoogleServices` tasks, unescaped from the Kotlin string,
/// or null when the script declares none.
String? processGoogleServicesPattern(String gradleSource) {
  final match = RegExp(
    r'Regex\("(\^process[^"]*GoogleServices\$)"\)',
  ).firstMatch(stripLineComments(gradleSource));
  return match?.group(1)!.replaceAll(r'\\', r'\');
}

/// Applies [pattern] (see [processGoogleServicesPattern]) to [taskName] the
/// way the Gradle script does, returning the partner id (first capture,
/// lowercased) or null when the task is not a partner's
/// `process<Id><BuildType>GoogleServices` task.
String? partnerOfProcessGoogleServicesTask(String pattern, String taskName) =>
    RegExp(pattern).firstMatch(taskName)?.group(1)?.toLowerCase();

/// Returns the bodies of the uncommented `tasks.configureEach { ... }`
/// blocks of [gradleSource], matching braces.
List<String> configureEachBlocks(String gradleSource) {
  final code = stripLineComments(gradleSource);
  const opener = 'tasks.configureEach {';
  final blocks = <String>[];
  var start = code.indexOf(opener);
  while (start >= 0) {
    var depth = 0;
    var end = start + opener.length - 1;
    for (; end < code.length; end++) {
      if (code[end] == '{') depth++;
      if (code[end] == '}' && --depth == 0) break;
    }
    blocks.add(code.substring(start + opener.length, end));
    start = code.indexOf(opener, end);
  }
  return blocks;
}

/// Returns the uncommented, non-blank lines of a `.gitignore`, trimmed.
List<String> gitignorePatterns(String gitignore) => [
  for (final line in gitignore.split('\n'))
    if (line.trim().isNotEmpty && !line.trim().startsWith('#')) line.trim(),
];

/// Splits the first `steps:` list of a GitHub workflow into one string per
/// step, without comment lines. Returns an empty list when there is none.
List<String> workflowSteps(String workflowYaml) {
  final lines = workflowYaml.split('\n');
  final stepsLine = lines.indexWhere((line) => line.trim() == 'steps:');
  if (stepsLine < 0) return const [];
  final steps = <StringBuffer>[];
  int? itemIndent;
  for (final line in lines.skip(stepsLine + 1)) {
    final trimmed = line.trimLeft();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final indent = line.length - trimmed.length;
    itemIndent ??= trimmed.startsWith('- ') ? indent : null;
    if (itemIndent == null || indent < itemIndent) break;
    if (indent == itemIndent && trimmed.startsWith('- ')) {
      steps.add(StringBuffer());
    }
    steps.last.writeln(line);
  }
  return [for (final step in steps) step.toString()];
}

/// Returns the entries of the `paths:` list of the `push` trigger, unquoted.
List<String> pushPaths(String workflowYaml) {
  final lines = workflowYaml.split('\n');
  final pathsLine = lines.indexWhere((line) => line.trim() == 'paths:');
  if (pathsLine < 0) return const [];
  final paths = <String>[];
  for (final line in lines.skip(pathsLine + 1)) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#')) continue;
    if (!trimmed.startsWith('- ')) break;
    paths.add(
      trimmed.substring(2).trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''),
    );
  }
  return paths;
}

/// Index of the first of [steps] that [test] accepts, or -1.
int stepIndex(List<String> steps, bool Function(String step) test) =>
    steps.indexWhere(test);

bool isConfigAuthStep(String step) =>
    RegExp(r'^\s*-?\s*id:\s*auth-config\s*$', multiLine: true).hasMatch(step);

bool isPlayAuthStep(String step) =>
    RegExp(r'^\s*-?\s*id:\s*auth\s*$', multiLine: true).hasMatch(step);

bool isBundleBuildStep(String step) => step.contains('flutter build appbundle');

/// Runs `git` with [args] in the repository and returns its stdout.
String git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode > 1) {
    fail('git ${args.join(' ')} failed: ${result.stderr}');
  }
  return result.stdout as String;
}

/// Files matching [pathspec] that git tracks and that still exist in the
/// working tree: what the next commit of the working tree would version.
/// A deletion that is not staged yet already counts as deleted, while a
/// checkout (as in CI) sees every tracked file.
List<String> trackedFiles(String pathspec) => [
  for (final path in const LineSplitter().convert(
    git(['ls-files', '--', pathspec]),
  ))
    if (File(path).existsSync()) path,
];

/// Whether git ignores [path] according to the working tree's `.gitignore`.
bool gitIgnores(String path) =>
    Process.runSync('git', [
      'check-ignore',
      '-q',
      '--no-index',
      path,
    ]).exitCode ==
    0;

const sampleWorkflow = '''
on:
  push:
    paths:
      - 'lib/**'
      # A comment between entries.
      - "tool/**"
      - pubspec.yaml
  workflow_dispatch:

jobs:
  deploy:
    steps:
      - uses: actions/checkout@v7

      # Comment mentioning id: auth
      - id: auth-config
        uses: google-github-actions/auth@v3
        with:
          service_account: config@example.com

      - run: flutter build appbundle --release

      - id: auth
        uses: google-github-actions/auth@v3
''';

void main() {
  group('specFetchTaskName - Unit Test Suite', () {
    test('Happy Path: uppercases the first letter of the id', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final name = specFetchTaskName(id);

      // 3. Assert
      expect(name, 'fetchFirebaseConfigAquariustur');
    });

    test('Edge Case: a single-letter id becomes one uppercase letter', () {
      // 1. Arrange
      const id = 'a';

      // 2. Act
      final name = specFetchTaskName(id);

      // 3. Assert
      expect(name, 'fetchFirebaseConfigA');
    });

    test('Sad Path: does not uppercase letters after the first', () {
      // 1. Arrange
      const id = 'acme2go';

      // 2. Act
      final name = specFetchTaskName(id);

      // 3. Assert
      expect(name, 'fetchFirebaseConfigAcme2go');
    });
  });

  group('processGoogleServicesPattern - Unit Test Suite', () {
    test('Happy Path: extracts and unescapes the Kotlin regex', () {
      // 1. Arrange
      const source =
          r'val re = Regex("^process([A-Z]\\w*)(Debug|Release)GoogleServices$")';

      // 2. Act
      final pattern = processGoogleServicesPattern(source);

      // 3. Assert
      expect(pattern, r'^process([A-Z]\w*)(Debug|Release)GoogleServices$');
    });

    test('Edge Case: ignores a commented-out declaration', () {
      // 1. Arrange
      const source = r'// val re = Regex("^process(\w+)GoogleServices$")';

      // 2. Act
      final pattern = processGoogleServicesPattern(source);

      // 3. Assert
      expect(pattern, isNull);
    });

    test('Sad Path: returns null for a regex about other tasks', () {
      // 1. Arrange
      const source = r'val re = Regex("^merge(\\w+)JniLibFolders$")';

      // 2. Act
      final pattern = processGoogleServicesPattern(source);

      // 3. Assert
      expect(pattern, isNull);
    });
  });

  group('configureEachBlocks - Unit Test Suite', () {
    test('Happy Path: returns the body of each block with nested braces', () {
      // 1. Arrange
      const source =
          'tasks.configureEach {\n  a { b }\n}\n'
          'tasks.configureEach {\n  c\n}\n';

      // 2. Act
      final blocks = configureEachBlocks(source);

      // 3. Assert
      expect(blocks, ['\n  a { b }\n', '\n  c\n']);
    });

    test('Edge Case: skips a commented-out block opener', () {
      // 1. Arrange
      const source = '// tasks.configureEach {\n';

      // 2. Act
      final blocks = configureEachBlocks(source);

      // 3. Assert
      expect(blocks, isEmpty);
    });

    test('Sad Path: returns nothing for a script without such blocks', () {
      // 1. Arrange
      const source = 'android { }';

      // 2. Act
      final blocks = configureEachBlocks(source);

      // 3. Assert
      expect(blocks, isEmpty);
    });
  });

  group('gitignorePatterns - Unit Test Suite', () {
    test('Happy Path: returns active patterns trimmed', () {
      // 1. Arrange
      const gitignore = 'build/\n  web/partner/  \n';

      // 2. Act
      final patterns = gitignorePatterns(gitignore);

      // 3. Assert
      expect(patterns, ['build/', 'web/partner/']);
    });

    test('Edge Case: an empty file has no patterns', () {
      // 1. Arrange
      const gitignore = '';

      // 2. Act
      final patterns = gitignorePatterns(gitignore);

      // 3. Assert
      expect(patterns, isEmpty);
    });

    test('Sad Path: a commented-out pattern does not count', () {
      // 1. Arrange
      const gitignore = '# android/app/src/*/google-services.json\n';

      // 2. Act
      final patterns = gitignorePatterns(gitignore);

      // 3. Assert
      expect(patterns, isEmpty);
    });
  });

  group('workflowSteps - Unit Test Suite', () {
    test('Happy Path: splits the steps in order', () {
      // 1. Arrange
      const workflow = sampleWorkflow;

      // 2. Act
      final steps = workflowSteps(workflow);

      // 3. Assert
      expect(steps.map((step) => step.trim().split('\n').first).toList(), [
        '- uses: actions/checkout@v7',
        '- id: auth-config',
        '- run: flutter build appbundle --release',
        '- id: auth',
      ]);
    });

    test('Edge Case: comment lines between steps are dropped', () {
      // 1. Arrange
      const workflow = sampleWorkflow;

      // 2. Act
      final steps = workflowSteps(workflow);

      // 3. Assert
      expect(steps.where(isPlayAuthStep).length, 1);
    });

    test('Sad Path: a workflow without steps yields no steps', () {
      // 1. Arrange
      const workflow = 'on:\n  workflow_dispatch:\n';

      // 2. Act
      final steps = workflowSteps(workflow);

      // 3. Assert
      expect(steps, isEmpty);
    });
  });

  group('pushPaths - Unit Test Suite', () {
    test('Happy Path: returns the unquoted entries', () {
      // 1. Arrange
      const workflow = sampleWorkflow;

      // 2. Act
      final paths = pushPaths(workflow);

      // 3. Assert
      expect(paths, ['lib/**', 'tool/**', 'pubspec.yaml']);
    });

    test('Edge Case: an empty paths list yields no entries', () {
      // 1. Arrange
      const workflow = 'on:\n  push:\n    paths:\n  workflow_dispatch:\n';

      // 2. Act
      final paths = pushPaths(workflow);

      // 3. Assert
      expect(paths, isEmpty);
    });

    test('Sad Path: a workflow without paths yields no entries', () {
      // 1. Arrange
      const workflow = 'on:\n  push:\n    branches: [main]\n';

      // 2. Act
      final paths = pushPaths(workflow);

      // 3. Assert
      expect(paths, isEmpty);
    });
  });

  group('partnerOfProcessGoogleServicesTask - Repo Contract Test Suite', () {
    late String pattern;

    setUp(() {
      pattern = processGoogleServicesPattern(
        File(gradlePath).readAsStringSync(),
      )!;
    });

    test('Happy Path: maps a release task to its partner', () {
      // 1. Arrange
      const taskName = 'processAquariusturReleaseGoogleServices';

      // 2. Act
      final id = partnerOfProcessGoogleServicesTask(pattern, taskName);

      // 3. Assert
      expect(id, 'aquariustur');
    });

    test('Happy Path: maps a debug task to its partner', () {
      // 1. Arrange
      const taskName = 'processAquariusturDebugGoogleServices';

      // 2. Act
      final id = partnerOfProcessGoogleServicesTask(pattern, taskName);

      // 3. Assert
      expect(id, 'aquariustur');
    });

    test('Happy Path: maps a profile task to its partner', () {
      // 1. Arrange
      const taskName = 'processAquariusturProfileGoogleServices';

      // 2. Act
      final id = partnerOfProcessGoogleServicesTask(pattern, taskName);

      // 3. Assert
      expect(id, 'aquariustur');
    });

    test('Edge Case: keeps digits of the partner id', () {
      // 1. Arrange
      const taskName = 'processAcme2goReleaseGoogleServices';

      // 2. Act
      final id = partnerOfProcessGoogleServicesTask(pattern, taskName);

      // 3. Assert
      expect(id, 'acme2go');
    });

    test('Sad Path: ignores an unflavored task', () {
      // 1. Arrange
      const taskName = 'processReleaseGoogleServices';

      // 2. Act
      final id = partnerOfProcessGoogleServicesTask(pattern, taskName);

      // 3. Assert
      expect(id, isNull);
    });

    test('Sad Path: ignores other process tasks of the variant', () {
      // 1. Arrange
      const taskName = 'processAquariusturReleaseResources';

      // 2. Act
      final id = partnerOfProcessGoogleServicesTask(pattern, taskName);

      // 3. Assert
      expect(id, isNull);
    });
  });

  group('Android Firebase config fetch - Gradle Repo Contract Test Suite', () {
    late String gradleCode;

    setUp(() {
      gradleCode = stripLineComments(File(gradlePath).readAsStringSync());
    });

    test('Happy Path: registers fetchFirebaseConfig<Id> per partner', () {
      // 1. Arrange
      final taskNameDeclaration = RegExp(
        r'"fetchFirebaseConfig\$\{partner\.id\.replaceFirstChar \{ '
        r'it\.uppercase\(\) \}\}"',
      );

      // 2. Act
      final declared = taskNameDeclaration.hasMatch(gradleCode);

      // 3. Assert
      expect(declared, isTrue, reason: 'task name per partner (spec #39)');
    });

    test('Happy Path: the task runs `dart run tool/partner.dart firebase '
        '<id>`', () {
      // 1. Arrange
      final command = RegExp(
        r'commandLine\([^)]*"run",\s*"tool/partner\.dart",\s*"firebase",\s*'
        r'partner\.id\s*\)',
      );

      // 2. Act
      final declared = command.hasMatch(gradleCode);

      // 3. Assert
      expect(declared, isTrue);
    });

    test('Happy Path: the task only runs when the file is missing or '
        'PARTNER_REFRESH_FIREBASE=1', () {
      // 1. Arrange
      final onlyIf = RegExp(r'onlyIf\s*\{([^}]*)\}').firstMatch(gradleCode);

      // 2. Act
      final condition = onlyIf?.group(1) ?? '';

      // 3. Assert
      expect(
        [
          gradleCode.contains(
            'environmentVariable("PARTNER_REFRESH_FIREBASE").orNull == "1"',
          ),
          condition.contains('||'),
          RegExp(r'!\s*\w+\.isFile').hasMatch(condition),
        ],
        [isTrue, isTrue, isTrue],
      );
    });

    test('Happy Path: every process<Id><BuildType>GoogleServices task '
        'depends on the fetch task', () {
      // 1. Arrange
      final regexVariable = RegExp(
        r'val\s+(\w+)\s*=\s*Regex\("\^process[^"]*GoogleServices\$"\)',
      ).firstMatch(gradleCode)?.group(1);

      // 2. Act
      final wiring = configureEachBlocks(gradleCode).where(
        (block) =>
            regexVariable != null &&
            block.contains('$regexVariable.') &&
            block.contains('dependsOn('),
      );

      // 3. Assert
      expect(wiring, hasLength(1));
    });

    test('Edge Case: the build type alternatives cover debug, profile and '
        'release', () {
      // 1. Arrange
      final source = File(gradlePath).readAsStringSync();

      // 2. Act
      final pattern = processGoogleServicesPattern(source);

      // 3. Assert
      expect(
        pattern,
        allOf(contains('Debug'), contains('Profile'), contains('Release')),
      );
    });

    test('Edge Case: Gradle checks the same file the tool writes', () {
      // 1. Arrange
      final toolPath = androidFirebaseConfigPath(
        r'${partner.id}',
      ).replaceAll(r'\', '/');

      // 2. Act
      final gradleRelativePath = RegExp(
        r'file\("(src/\$\{partner\.id\}/google-services\.json)"\)',
      ).firstMatch(gradleCode)?.group(1);

      // 3. Assert
      expect('android/app/$gradleRelativePath', toolPath);
    });

    test('Edge Case: the tool derives the same application id as '
        'Gradle', () {
      // 1. Arrange
      final toolApplicationId = androidApplicationId(r'${partner.id}');

      // 2. Act
      final declared = gradleCode.contains(
        'applicationId = "$toolApplicationId"',
      );

      // 3. Assert
      expect(declared, isTrue);
    });

    test('Sad Path: the script never copies a versioned '
        'android/app/google-services.json', () {
      // 1. Arrange
      final legacyReference = RegExp(r'file\("google-services\.json"\)');

      // 2. Act
      final referenced = legacyReference.hasMatch(gradleCode);

      // 3. Assert
      expect(referenced, isFalse);
    });
  });

  group('Android Firebase config fetch - Git Repo Contract Test Suite', () {
    test('Happy Path: .gitignore ignores android/app/src/*/'
        'google-services.json', () {
      // 1. Arrange
      final gitignore = File(gitignorePath).readAsStringSync();

      // 2. Act
      final patterns = gitignorePatterns(gitignore);

      // 3. Assert
      expect(patterns, contains(fetchedConfigIgnorePattern));
    });

    test('Happy Path: git ignores the fetched config of a partner', () {
      // 1. Arrange
      const path = 'android/app/src/aquariustur/google-services.json';

      // 2. Act
      final ignored = gitIgnores(path);

      // 3. Assert
      expect(ignored, isTrue);
    });

    test('Happy Path: git no longer tracks '
        'android/app/google-services.json', () {
      // 1. Arrange
      const path = legacyConfigPath;

      // 2. Act
      final tracked = trackedFiles(path);

      // 3. Assert
      expect(tracked, isEmpty);
    });

    test('Edge Case: git tracks no google-services.json anywhere', () {
      // 1. Arrange
      const pathspec = '*google-services.json';

      // 2. Act
      final tracked = trackedFiles(pathspec);

      // 3. Assert
      expect(tracked, isEmpty);
    });

    test('Edge Case: git ignores the config of a partner not yet '
        'onboarded', () {
      // 1. Arrange
      const path = 'android/app/src/newpartner/google-services.json';

      // 2. Act
      final ignored = gitIgnores(path);

      // 3. Assert
      expect(ignored, isTrue);
    });

    test('Sad Path: the pattern does not ignore other flavor sources', () {
      // 1. Arrange
      const path = 'android/app/src/main/AndroidManifest.xml';

      // 2. Act
      final ignored = gitIgnores(path);

      // 3. Assert
      expect(ignored, isFalse);
    });
  });

  group('Android Firebase config fetch - CI Repo Contract Test Suite', () {
    late String workflow;
    late List<String> steps;

    setUp(() {
      workflow = File(ciWorkflowPath).readAsStringSync();
      steps = workflowSteps(workflow);
    });

    test('Happy Path: the config auth step runs before the bundle build', () {
      // 1. Arrange
      final buildIndex = stepIndex(steps, isBundleBuildStep);

      // 2. Act
      final configAuthIndex = stepIndex(steps, isConfigAuthStep);

      // 3. Assert
      expect(
        [configAuthIndex >= 0, buildIndex >= 0, configAuthIndex < buildIndex],
        [isTrue, isTrue, isTrue],
      );
    });

    test('Happy Path: the config auth step impersonates the config service '
        'account', () {
      // 1. Arrange
      final index = stepIndex(steps, isConfigAuthStep);

      // 2. Act
      final step = index < 0 ? '' : steps[index];

      // 3. Assert
      expect(
        step,
        allOf(
          contains('google-github-actions/auth@'),
          contains('workload_identity_provider:'),
          contains('service_account: $configServiceAccount'),
        ),
      );
    });

    test('Happy Path: the Play auth step stays after the bundle build', () {
      // 1. Arrange
      final buildIndex = stepIndex(steps, isBundleBuildStep);

      // 2. Act
      final playAuthIndex = stepIndex(steps, isPlayAuthStep);

      // 3. Assert
      expect([buildIndex >= 0, playAuthIndex > buildIndex], [isTrue, isTrue]);
    });

    test('Happy Path: the Play auth step impersonates the Play service '
        'account', () {
      // 1. Arrange
      final index = stepIndex(steps, isPlayAuthStep);

      // 2. Act
      final step = index < 0 ? '' : steps[index];

      // 3. Assert
      expect(step, contains('service_account: $playServiceAccount'));
    });

    test('Happy Path: firebase-tools@$firebaseToolsVersion is installed '
        'before the bundle build', () {
      // 1. Arrange
      final buildIndex = stepIndex(steps, isBundleBuildStep);

      // 2. Act
      final installIndex = stepIndex(
        steps,
        (step) => step.contains('firebase-tools@$firebaseToolsVersion'),
      );

      // 3. Assert
      expect([installIndex >= 0, installIndex < buildIndex], [isTrue, isTrue]);
    });

    test('Happy Path: pushes that change tool/ trigger a deploy', () {
      // 1. Arrange
      final source = workflow;

      // 2. Act
      final paths = pushPaths(source);

      // 3. Assert
      expect(paths, contains('tool/**'));
    });

    test('Edge Case: the config auth step uses no long-lived key', () {
      // 1. Arrange
      final index = stepIndex(steps, isConfigAuthStep);

      // 2. Act
      final step = index < 0 ? '' : steps[index];

      // 3. Assert
      expect(step, isNot(contains('credentials_json')));
    });

    test('Sad Path: no step up to the bundle build holds the Play '
        'credential', () {
      // 1. Arrange
      final buildIndex = stepIndex(steps, isBundleBuildStep);

      // 2. Act
      final leaking = steps
          .take(buildIndex + 1)
          .where(
            (step) =>
                step.contains(playServiceAccount) ||
                step.contains('steps.auth.'),
          );

      // 3. Assert
      expect(leaking, isEmpty);
    });

    test('Sad Path: the Play service account is never used for the config '
        'auth step', () {
      // 1. Arrange
      final index = stepIndex(steps, isConfigAuthStep);

      // 2. Act
      final step = index < 0 ? '' : steps[index];

      // 3. Assert
      expect(step, isNot(contains(playServiceAccount)));
    });
  });
}
