import 'dart:typed_data';

import 'package:monamie_app/data/repositories/functions_result.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/theme/theme_repository.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/data/services/storage/organization_storage_service.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart'
    as theme;
import 'package:monamie_app/utils/result.dart';

import 'appearance_repository.dart';

const _saveFailed =
    'Não foi possível salvar agora. Verifique a conexão e tente de novo.';

/// [AppearanceRepository] over the organization's Storage and its
/// `setBranding` function, with themes from the central catalog.
class AppearanceRepositoryRemote implements AppearanceRepository {
  const AppearanceRepositoryRemote({
    required this._themes,
    required this._functions,
    required this._storage,
  });

  final ThemeRepository _themes;
  final OrganizationFunctionsService _functions;
  final OrganizationStorageService _storage;

  Future<Result<T>> _run<T>(
    Future<Result<T>> Function() operation, {
    String unexpected = _saveFailed,
  }) => functionsResult(
    operation,
    refusal: (failure) => functionsFailureMessage(
      failure,
      explained: const {'invalid-argument', 'permission-denied'},
      fallback: 'Não foi possível salvar.',
      otherwise: _saveFailed,
    ),
    unexpected: unexpected,
    logTag: 'Appearance',
  );

  @override
  Future<Result<List<theme.OrganizationTheme>>> pickableThemes() => _run(
    () async => Ok(theme.pickableThemes((await _themes.themes()).values)),
    unexpected: 'Não foi possível carregar os temas.',
  );

  @override
  Future<Result<void>> uploadLogo(String organizationId, Uint8List png) =>
      _run(() async {
        await _storage.upload(
          organizationLogoPath(organizationId),
          png,
          contentType: 'image/png',
        );
        return const Ok(null);
      });

  @override
  Future<Result<void>> deleteLogo(String organizationId) => _run(() async {
    await _storage.delete(organizationLogoPath(organizationId));
    return const Ok(null);
  });

  @override
  Future<Result<void>> saveBranding(
    String organizationId, {
    String? name,
    String? themeId,
    String? logo,
  }) => _run(() async {
    await _functions.call('setBranding', {
      'organizationId': organizationId,
      'name': ?name,
      'themeId': ?themeId,
      'logo': ?logo,
    });
    return const Ok(null);
  });
}
