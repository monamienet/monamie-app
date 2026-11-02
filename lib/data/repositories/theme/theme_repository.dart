import 'package:monamie_app/domain/models/organization/organization_theme.dart';

/// The theme catalog of the central project (`themes/{id}`).
///
/// It throws instead of returning `Result`: its callers turn a failure into
/// their own message or fallback.
abstract interface class ThemeRepository {
  /// Every theme, active or not, by id. Throws when the catalog cannot be
  /// read.
  Future<Map<String, OrganizationTheme>> themes();
}
