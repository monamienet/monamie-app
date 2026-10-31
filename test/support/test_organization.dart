import 'package:monamie_app/app/config/organization/organization_config.dart';

/// Organization every test runs with (see `test/flutter_test_config.dart`). It is
/// inline, not read from `organizations/`, so tests never depend on a real
/// organization's identity. Without a theme it shows Grafite.
const testOrganization = OrganizationConfig(id: 'acme', name: 'Acme');
