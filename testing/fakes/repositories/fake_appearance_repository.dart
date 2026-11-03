import 'dart:typed_data';

import 'package:monamie_app/data/repositories/appearance/appearance_repository.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/utils/result.dart';

import 'fake_outcomes.dart';

/// [AppearanceRepository] over [themes] and in-memory logos and brandings,
/// by organization id.
class FakeAppearanceRepository
    with FakeOutcomes
    implements AppearanceRepository {
  FakeAppearanceRepository({List<OrganizationTheme>? themes})
    : themes = [...?themes];

  /// The themes an administrator may pick, in picker order.
  final List<OrganizationTheme> themes;

  /// The uploaded logo of each organization.
  final Map<String, Uint8List> logos = {};

  /// The fields last saved for each organization (`name`, `themeId`,
  /// `logo`), merged save after save.
  final Map<String, Map<String, String>> brandings = {};

  @override
  Future<Result<List<OrganizationTheme>>> pickableThemes() =>
      answer('pickableThemes', const [], () => [...themes]);

  @override
  Future<Result<void>> uploadLogo(String organizationId, Uint8List png) =>
      answer('uploadLogo', [organizationId, png], () {
        logos[organizationId] = png;
      });

  @override
  Future<Result<void>> deleteLogo(String organizationId) =>
      answer('deleteLogo', [organizationId], () {
        logos.remove(organizationId);
      });

  @override
  Future<Result<void>> saveBranding(
    String organizationId, {
    String? name,
    String? themeId,
    String? logo,
  }) => answer('saveBranding', [organizationId, name, themeId, logo], () {
    brandings[organizationId] = {
      ...?brandings[organizationId],
      'name': ?name,
      'themeId': ?themeId,
      'logo': ?logo,
    };
  });
}
