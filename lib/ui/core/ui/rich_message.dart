import 'package:flutter/painting.dart';

/// [message] (an `AppLocalizations` method with one placeholder) as text
/// spans, [value] drawn in [valueStyle] wherever the translation puts it,
/// so a sentence keeps one ARB key even when part of it is bold.
List<TextSpan> spansAround(
  String Function(String placeholder) message,
  String value, {
  required TextStyle valueStyle,
}) {
  // A character no translation contains marks where the value goes.
  const mark = '\u0000';
  final parts = message(mark).split(mark);
  return [
    for (final (i, part) in parts.indexed) ...[
      if (i > 0) TextSpan(text: value, style: valueStyle),
      if (part.isNotEmpty) TextSpan(text: part),
    ],
  ];
}
