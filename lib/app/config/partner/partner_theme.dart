import 'dart:ui' show Color;

final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// One theme of the catalog in the central project (`themes/{id}`).
///
/// Partners pick a theme, never free colors. Every theme passes WCAG AA for
/// [onPrimary] on [primary] and [onDark] on [dark], and for [dark] text on
/// [light].
class PartnerTheme {
  const PartnerTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.dark,
    required this.light,
    required this.onPrimary,
    required this.onDark,
    this.order = 0,
    this.active = true,
  });

  /// Reads a catalog document (or the local copy written by [toJson]).
  /// Returns `null` when a color is missing or malformed: a broken theme is
  /// treated as unknown, which falls back to [defaultPartnerTheme].
  static PartnerTheme? fromJson(String id, Object? data) {
    if (data is! Map) return null;
    final primary = parseHexColor(data['primary']);
    final dark = parseHexColor(data['dark']);
    final light = parseHexColor(data['light']);
    if (primary == null || dark == null || light == null) return null;
    final name = data['name'];
    final order = data['order'];
    return PartnerTheme(
      id: id,
      name: name is String && name.trim().isNotEmpty ? name.trim() : id,
      primary: primary,
      dark: dark,
      light: light,
      onPrimary: parseHexColor(data['onPrimary']) ?? _white,
      onDark: parseHexColor(data['onDark']) ?? _white,
      order: order is int ? order : 0,
      active: data['active'] != false,
    );
  }

  final String id;
  final String name;

  /// Buttons, selected states, the logo tile.
  final Color primary;

  /// App bars and headers.
  final Color dark;

  /// Pale containers, with [dark] text on them.
  final Color light;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Text and icons on [dark].
  final Color onDark;

  /// Position in the picker.
  final int order;

  /// Inactive themes are hidden from the picker but still resolve, so a
  /// partner that uses one keeps it.
  final bool active;

  Map<String, Object?> toJson() => {
    'name': name,
    'primary': formatHexColor(primary),
    'dark': formatHexColor(dark),
    'light': formatHexColor(light),
    'onPrimary': formatHexColor(onPrimary),
    'onDark': formatHexColor(onDark),
    'order': order,
    'active': active,
  };
}

const _white = Color(0xFFFFFFFF);

/// Grafite: the theme of a partner whose `themeId` is missing or unknown.
const defaultPartnerTheme = PartnerTheme(
  id: 'grafite',
  name: 'Grafite',
  primary: Color(0xFF3F4754),
  dark: Color(0xFF1F2128),
  light: Color(0xFFDCDEE2),
  onPrimary: _white,
  onDark: _white,
  order: 8,
);

/// The theme [themeId] names in [catalog], or [defaultPartnerTheme] when the
/// id is missing or not in the catalog. Inactive themes still resolve.
PartnerTheme resolvePartnerTheme(
  String? themeId,
  Map<String, PartnerTheme> catalog,
) => (themeId == null ? null : catalog[themeId]) ?? defaultPartnerTheme;

/// The active themes of [catalog], in picker order.
List<PartnerTheme> pickableThemes(Iterable<PartnerTheme> catalog) =>
    catalog.where((theme) => theme.active).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

/// `#RRGGBB` (either case) as an opaque color, or `null` when malformed.
Color? parseHexColor(Object? value) {
  if (value is! String || !_hexColorPattern.hasMatch(value)) return null;
  return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
}

/// [color] as `#RRGGBB`, upper case.
String formatHexColor(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
