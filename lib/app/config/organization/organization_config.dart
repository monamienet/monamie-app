import 'dart:typed_data';

import 'group_address.dart';
import 'organization_theme.dart';

export 'group_address.dart';

/// The organization's Firebase project: `monamienet-<id>`.
String firebaseProjectIdFor(String organizationId) =>
    'monamienet-$organizationId';

/// The organization's root group: `<id>00@monamienet.org`.
String rootGroupEmailFor(String organizationId) =>
    '${organizationId}00@$groupDomain';

/// The name shown when an organization's branding has no usable name: the id with
/// its first letter in upper case (`aquariustur` → `Aquariustur`).
String fallbackOrganizationName(String id) =>
    id.isEmpty ? id : id[0].toUpperCase() + id.substring(1);

/// An organization and the branding it chose: a name, a catalog theme and,
/// optionally, a logo.
///
/// Only [id] and [name] are always present. A missing or unknown theme uses
/// Grafite; a missing logo (or one that does not decode) shows the name's
/// initial in a tile of the theme's primary color.
class OrganizationConfig {
  const OrganizationConfig({
    required this.id,
    required this.name,
    this.themeId,
    this.theme,
    this.logoVersion,
    this.logoPng,
  });

  /// Reads the organization's `config/branding` document.
  ///
  /// A bad brand never breaks the app: missing or malformed fields become
  /// `null`, and a missing name becomes [fallbackOrganizationName]. Only an
  /// invalid [id], which comes from MonAmie's own rules, throws an
  /// [ArgumentError].
  ///
  /// [theme] is the catalog theme that `themeId` resolved to, and [logoPng]
  /// the logo file already downloaded for this `logoVersion`, when known.
  factory OrganizationConfig.fromBranding(
    String id,
    Object? data, {
    OrganizationTheme? theme,
    Uint8List? logoPng,
  }) {
    final idProblem = organizationIdProblem(id);
    if (idProblem != null) throw ArgumentError.value(id, 'id', idProblem);
    final map = data is Map ? data : const {};
    final logoVersion = map['logoVersion'];
    return OrganizationConfig(
      id: id,
      name: _nonBlank(map['name']) ?? fallbackOrganizationName(id),
      themeId: _nonBlank(map['themeId']),
      theme: theme,
      logoVersion: logoVersion is int ? logoVersion : null,
      logoPng: logoVersion is int ? logoPng : null,
    );
  }

  /// Permanent organization id: `<id>` in `monamienet-<id>` and `<id>NN@...`.
  final String id;

  /// The organization's own name. Users see it alone: the MonAmie name and a
  /// organization's name are never shown side by side.
  final String name;

  /// `themeId`: the catalog theme the organization picked, or `null`.
  final String? themeId;

  /// The catalog theme [themeId] resolved to, kept with the binding so the
  /// first screen is branded without network. `null` while unresolved, which
  /// shows the default theme.
  final OrganizationTheme? theme;

  /// `logoVersion`: set when an administrator uploads a logo, so devices know to
  /// fetch it again. `null` when the organization has no logo.
  final int? logoVersion;

  /// The logo file (a square 512 px PNG) for [logoVersion], kept with the
  /// binding. `null` when there is no logo or it was not downloaded yet.
  final Uint8List? logoPng;

  /// The theme the app uses: [theme], or the default (Grafite).
  OrganizationTheme get effectiveTheme => theme ?? defaultOrganizationTheme;

  /// The organization's root group: `<id>00@monamienet.org`.
  String get rootGroupEmail => rootGroupEmailFor(id);

  /// The organization's Firebase project when it is on the Standard plan:
  /// `monamienet-<id>`.
  String get firebaseProjectId => firebaseProjectIdFor(id);

  /// The branding document this config was read from, for the local copy.
  Map<String, Object?> toBranding() => {
    'name': name,
    'themeId': ?themeId,
    'logoVersion': ?logoVersion,
  };
}

String? _nonBlank(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
