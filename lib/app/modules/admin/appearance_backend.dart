import 'dart:typed_data';

import 'package:monamie_app/app/config/organization/organization_theme.dart';

/// What the *Aparência* screen needs from the server, kept apart so the
/// screen and its controller are tested with a fake.
abstract interface class AppearanceBackend {
  /// The catalog's themes an administrator may pick, in picker order.
  Future<List<OrganizationTheme>> pickableThemes();

  /// Uploads the square logo PNG of [organizationId].
  Future<void> uploadLogo(String organizationId, Uint8List png);

  /// Deletes the logo of [organizationId].
  Future<void> deleteLogo(String organizationId);

  /// Saves the changed fields (`setBranding`); `logo` is `set` after an
  /// upload and `removed` after a delete. Throws [AppearanceException]
  /// with a message for an administrator.
  Future<void> saveBranding(
    String organizationId, {
    String? name,
    String? themeId,
    String? logo,
  });
}

/// A save that failed, in words for an administrator.
class AppearanceException implements Exception {
  const AppearanceException(this.message);

  final String message;

  @override
  String toString() => message;
}
