import 'package:monamie_app/app/config/partner/partner_config.dart';

/// Partner every test runs with (see `test/flutter_test_config.dart`). It is
/// inline, not read from `partners/`, so tests never depend on a real
/// partner's identity. Without a theme it shows Grafite.
const testPartner = PartnerConfig(id: 'acme', name: 'Acme');
