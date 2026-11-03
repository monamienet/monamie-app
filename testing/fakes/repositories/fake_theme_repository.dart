import 'package:monamie_app/data/repositories/theme/theme_repository.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';

import 'fake_outcomes.dart';

/// [ThemeRepository] over [catalog]. A failure asked for with `fail`
/// throws, as the real catalog read does.
class FakeThemeRepository with FakeOutcomes implements ThemeRepository {
  /// Starts with [themes] (the default theme alone when omitted).
  FakeThemeRepository({List<OrganizationTheme>? themes})
    : catalog = {
        for (final t in themes ?? const [defaultOrganizationTheme]) t.id: t,
      };

  /// Every theme, by id.
  final Map<String, OrganizationTheme> catalog;

  @override
  Future<Map<String, OrganizationTheme>> themes() =>
      run('themes', const [], () => {...catalog});
}
