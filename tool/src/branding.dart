import 'dart:io';

import 'partners.dart';

/// Largest SVG accepted in the branding document. Firestore documents are
/// limited to 1 MiB, and every app launch may download the document.
const maxSvgBytes = 200 * 1024;

/// Path of the branding document in every partner project.
const brandingDocumentPath = 'config/branding';

/// Builds the `config/branding` document of a partner.
///
/// [name] is mandatory. Colors and SVG files are optional, but when given
/// they must be valid; otherwise a [PartnerToolException] says which value
/// to fix. Optional values left out make the app use its fallbacks.
Map<String, Object?> buildBrandingDocument({
  required String name,
  String? primary,
  String? secondary,
  File? logo,
  File? icon,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    throw PartnerToolException('The partner name must not be blank.');
  }
  if (trimmedName.toLowerCase().startsWith('monamie ')) {
    throw PartnerToolException(
      "Pass the name without the 'MonAmie ' prefix: the app adds it.",
    );
  }
  return {
    'name': trimmedName,
    'colors': {
      'primary': ?_color('--primary', primary),
      'secondary': ?_color('--secondary', secondary),
    },
    'logoSvg': ?_svg('--logo', logo),
    'iconSvg': ?_svg('--icon', icon),
  };
}

String? _color(String option, String? value) {
  if (value == null) return null;
  if (!isHexColor(value)) {
    throw PartnerToolException("$option must be a color like '#0ABAB5'.");
  }
  return value.toUpperCase();
}

String? _svg(String option, File? file) {
  if (file == null) return null;
  if (!file.existsSync()) {
    throw PartnerToolException('$option: ${file.path} does not exist.');
  }
  if (file.lengthSync() > maxSvgBytes) {
    throw PartnerToolException(
      '$option: ${file.path} is larger than ${maxSvgBytes ~/ 1024} KiB.',
    );
  }
  final String source;
  try {
    source = file.readAsStringSync();
  } on FileSystemException {
    throw PartnerToolException('$option: ${file.path} is not UTF-8 text.');
  }
  if (!RegExp(r'<svg[\s>]').hasMatch(source) || !source.contains('</svg>')) {
    throw PartnerToolException('$option: ${file.path} is not an SVG file.');
  }
  if (RegExp(r'<script[\s>]', caseSensitive: false).hasMatch(source)) {
    throw PartnerToolException('$option: ${file.path} contains a <script>.');
  }
  return source;
}

/// Warnings about an SVG that is valid but may render differently on the
/// devices: live `<text>` depends on fonts the phone may not have.
List<String> svgWarnings(String option, String svg) => [
  if (RegExp(r'<text[\s>]').hasMatch(svg))
    '$option has live <text>; phones may render it in another font. Ask the '
        'partner for a version with the text converted to outlines.',
];
