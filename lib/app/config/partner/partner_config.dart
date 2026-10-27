import 'dart:ui' show Color;

import 'partner_theme.dart';

/// Domain of every MonAmie group.
const groupDomain = 'monamienet.org';

/// The central MonAmie Firebase project is `monamienet-app`, so `app` can
/// never be a partner id.
const _reservedPartnerIds = {'app'};

final _partnerIdPattern = RegExp(r'^[a-z][a-z0-9]*$');
final _groupSuffixPattern = RegExp(r'^[0-9]{2}$');

/// Returns why [id] is not a valid partner id, or `null` when it is valid.
String? partnerIdProblem(String id) {
  if (!_partnerIdPattern.hasMatch(id) || _reservedPartnerIds.contains(id)) {
    return "invalid partner id '$id': it must match "
        "${_partnerIdPattern.pattern} and not be one of "
        '${_reservedPartnerIds.join(', ')}';
  }
  return null;
}

/// The partner's Firebase project: `monamienet-<id>`.
String firebaseProjectIdFor(String partnerId) => 'monamienet-$partnerId';

/// The partner's root group: `<id>00@monamienet.org`.
String rootGroupEmailFor(String partnerId) => '${partnerId}00@$groupDomain';

/// The partner a MonAmie group belongs to, or `null` when [email] does not
/// follow the convention.
///
/// Every group of a partner is named `<id>NN@monamienet.org`, where `NN` is
/// always two digits (`00` is the root group), so the id is the part before
/// the `@` without its last two characters: `aquariustur01@monamienet.org`
/// belongs to `aquariustur`.
String? partnerIdFromGroupEmail(String email) {
  final normalized = email.trim().toLowerCase();
  final at = normalized.lastIndexOf('@');
  if (at < 0 || normalized.substring(at + 1) != groupDomain) return null;
  final local = normalized.substring(0, at);
  if (local.length < 3) return null;
  if (!_groupSuffixPattern.hasMatch(local.substring(local.length - 2))) {
    return null;
  }
  final id = local.substring(0, local.length - 2);
  return partnerIdProblem(id) == null ? id : null;
}

/// The name shown when a partner's branding has no usable name: the id with
/// its first letter in upper case (`aquariustur` → `Aquariustur`).
String fallbackPartnerName(String id) =>
    id.isEmpty ? id : id[0].toUpperCase() + id.substring(1);

/// A partner and the branding it chose.
///
/// Only [id] and [name] are always present. Colors, logo and icon are
/// optional: when one is missing or malformed it is `null`, and the app shows
/// the fallback described where it is used (MonAmie colors, white background,
/// the name as text, the name's initial).
class PartnerConfig {
  const PartnerConfig({
    required this.id,
    required this.name,
    this.primaryColor,
    this.secondaryColor,
    this.logoSvg,
    this.iconSvg,
    this.themeId,
    this.theme,
  });

  /// Reads the partner's `config/branding` document.
  ///
  /// A bad brand never breaks the app: missing or malformed fields become
  /// `null`, and a missing name becomes [fallbackPartnerName]. Only an
  /// invalid [id], which comes from MonAmie's own rules, throws an
  /// [ArgumentError].
  ///
  /// [theme] is the catalog theme that `themeId` resolved to, when known.
  factory PartnerConfig.fromBranding(
    String id,
    Object? data, {
    PartnerTheme? theme,
  }) {
    final idProblem = partnerIdProblem(id);
    if (idProblem != null) throw ArgumentError.value(id, 'id', idProblem);
    final map = data is Map ? data : const {};
    final colors = map['colors'] is Map ? map['colors'] as Map : const {};
    final name = _nonBlank(map['name']);
    return PartnerConfig(
      id: id,
      name: name ?? fallbackPartnerName(id),
      primaryColor: _parseColor(colors['primary']),
      secondaryColor: _parseColor(colors['secondary']),
      logoSvg: _nonBlank(map['logoSvg']),
      iconSvg: _nonBlank(map['iconSvg']),
      themeId: _nonBlank(map['themeId']),
      theme: theme,
    );
  }

  /// Permanent partner id: `<id>` in `monamienet-<id>` and `<id>NN@...`.
  final String id;

  /// The partner's own name. Users see it alone: the MonAmie name and a
  /// partner's name are never shown side by side.
  final String name;

  /// `colors.primary`: the brand color, or `null` for MonAmie's colors.
  final Color? primaryColor;

  /// `colors.secondary`: the brand background, or `null` for white.
  final Color? secondaryColor;

  /// `logoSvg`: the logo with the name, or `null` to show [name] as text.
  final String? logoSvg;

  /// `iconSvg`: the logo without text, or `null` to show [name]'s initial.
  final String? iconSvg;

  /// `themeId`: the catalog theme the partner picked, or `null`.
  final String? themeId;

  /// The catalog theme [themeId] resolved to, kept with the binding so the
  /// first screen is branded without network. `null` while unresolved.
  final PartnerTheme? theme;

  /// The partner's root group: `<id>00@monamienet.org`.
  String get rootGroupEmail => rootGroupEmailFor(id);

  /// The partner's Firebase project: `monamienet-<id>`.
  String get firebaseProjectId => firebaseProjectIdFor(id);

  /// The branding document this config was read from, for the local copy.
  Map<String, Object?> toBranding() => {
    'name': name,
    'colors': {
      if (primaryColor != null) 'primary': _formatColor(primaryColor!),
      if (secondaryColor != null) 'secondary': _formatColor(secondaryColor!),
    },
    if (logoSvg != null) 'logoSvg': logoSvg,
    if (iconSvg != null) 'iconSvg': iconSvg,
    if (themeId != null) 'themeId': themeId,
  };
}

String? _nonBlank(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

Color? _parseColor(Object? value) => parseHexColor(value);

String _formatColor(Color color) => formatHexColor(color);
