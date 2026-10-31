import 'dart:async';

import 'package:monamie_app/app/config/organization/organization.dart';

import 'support/test_organization.dart';

/// Runs before every test file under `test/`: `main()` is not run in tests,
/// so the organization it would load is set here.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Organization.bind(testOrganization);
  await testMain();
}
