import 'dart:typed_data';

import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/utils/result.dart';

/// What the *Aparência* screen needs from the server, behind a contract so
/// the screen and its view model are tested with a fake. Every method
/// returns an [Err] with a [Failure] instead of
/// throwing.
abstract interface class AppearanceRepository {
  /// The catalog's themes an administrator may pick, in picker order.
  Future<Result<List<OrganizationTheme>>> pickableThemes();

  /// Uploads the square logo PNG of [organizationId].
  Future<Result<void>> uploadLogo(String organizationId, Uint8List png);

  /// Deletes the logo of [organizationId] (done when there is none).
  Future<Result<void>> deleteLogo(String organizationId);

  /// Saves the changed fields (`setBranding`); `logo` is `set` after an
  /// upload and `removed` after a delete.
  Future<Result<void>> saveBranding(
    String organizationId, {
    String? name,
    String? themeId,
    String? logo,
  });
}
