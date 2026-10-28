import 'package:monamie_app/app/config/partner/partner_theme.dart';

/// The theme catalog of the central project (`themes/{id}`).
abstract interface class ThemeCatalog {
  /// Every theme, active or not, by id. Throws when the catalog cannot be
  /// read.
  Future<Map<String, PartnerTheme>> themes();
}
