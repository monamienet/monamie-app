import 'dart:ui' show Color;

/// AGP rejects flavor names starting with `test` and these reserved names.
/// Kept in sync with `android/app/build.gradle.kts` and `tool/src/partners.dart`.
const _reservedPartnerIds = {'lint', 'main', 'debug', 'release', 'profile'};

final _partnerIdPattern = RegExp(r'^[a-z][a-z0-9]*$');
final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// Returns why [id] is not a valid partner id, or `null` when it is valid.
///
/// The id becomes the Android flavor and the Play application id, so it
/// follows the same rules as the Gradle build.
String? partnerIdProblem(String id) {
  if (!_partnerIdPattern.hasMatch(id) ||
      id.startsWith('test') ||
      _reservedPartnerIds.contains(id)) {
    return "invalid partner id '$id': it must match "
        "${_partnerIdPattern.pattern}, not start with 'test' and not be one of "
        '${_reservedPartnerIds.join(', ')}';
  }
  return null;
}

/// The partner this build serves: the folder name under `partners/` plus what
/// the partner chose in its `partner.json`.
class PartnerConfig {
  const PartnerConfig({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
  });

  /// Reads the decoded `partners/<id>/partner.json` of partner [id].
  ///
  /// Throws a [FormatException] naming the first invalid field.
  factory PartnerConfig.fromJson(String id, Object? json) {
    final idProblem = partnerIdProblem(id);
    if (idProblem != null) throw FormatException('"id": $idProblem', id);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('partner.json must contain a JSON object');
    }
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw FormatException('"name" must be a non-empty string', name);
    }
    final colors = json['colors'];
    if (colors is! Map<String, dynamic>) {
      throw FormatException('"colors" must be a JSON object', colors);
    }
    return PartnerConfig(
      id: id,
      name: name,
      primaryColor: _parseColor(colors, 'primary'),
      secondaryColor: _parseColor(colors, 'secondary'),
    );
  }

  /// Permanent partner id: the folder name, the Android flavor and the last
  /// segment of the application id (`org.monamienet.<id>`).
  final String id;

  /// The partner's own name, without the `MonAmie ` prefix.
  final String name;

  /// `colors.primary`: the brand color.
  final Color primaryColor;

  /// `colors.secondary`: the brand background (also the Android splash).
  final Color secondaryColor;

  /// The name users see. Kept in sync with `appLabel` in
  /// `android/app/build.gradle.kts`.
  String get displayName => 'MonAmie $name';
}

Color _parseColor(Map<String, dynamic> colors, String key) {
  final value = colors[key];
  if (value is! String || !_hexColorPattern.hasMatch(value)) {
    throw FormatException(
      '"colors.$key" must be a color like "#RRGGBB"',
      value,
    );
  }
  return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
}
