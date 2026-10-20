import 'dart:async';

import 'package:monamie_app/app/config/partner/partner.dart';

import 'support/test_partner.dart';

/// Runs before every test file under `test/`: `main()` is not run in tests,
/// so the partner it would load is set here.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Partner.init(testPartner);
  await testMain();
}
