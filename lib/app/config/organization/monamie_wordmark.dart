import 'package:flutter/widgets.dart';

import 'monamie_brand.dart';

/// Where a glyph's ink sits in its cell, in em: the [advance] of the cell and
/// where the drawing starts ([inkStart]) and ends ([inkEnd]) inside it.
class GlyphMetrics {
  const GlyphMetrics(this.advance, this.inkStart, this.inkEnd);

  final double advance;
  final double inkStart;
  final double inkEnd;
}

/// The x of each glyph's cell, in em, so the ink of every neighbouring pair
/// is [inkGap] apart. Unlike letter-spacing, this evens out the side
/// bearings: an "m" next to an "o" and an "a" next to an "m" look equally
/// apart.
List<double> glyphOrigins(List<GlyphMetrics> glyphs, double inkGap) {
  final origins = <double>[];
  for (var i = 0; i < glyphs.length; i++) {
    origins.add(
      i == 0
          ? 0
          : origins[i - 1] + glyphs[i - 1].inkEnd + inkGap - glyphs[i].inkStart,
    );
  }
  return origins;
}

/// The "monamie" wordmark of the design canvas, drawn glyph by glyph.
///
/// Manrope ExtraBold with a dotless ı and a coral dot over it (`Main.dc.html`:
/// the dot is 0.15 em wide, 0.13 em from the top of the line and 0.073 em from
/// the left of the ı), with the same gap between the ink of every pair of
/// letters.
class MonAmieWordmark extends StatelessWidget {
  const MonAmieWordmark({super.key, this.fontSize = 48, required this.color});

  final double fontSize;

  /// The letters' color (the dot is always coral).
  final Color color;

  // Measured in assets/fonts/Manrope-800.ttf (2000 units per em).
  static const _m = GlyphMetrics(0.916, 0.069, 0.856);
  static const _o = GlyphMetrics(0.627, 0.040, 0.587);
  static const _n = GlyphMetrics(0.636, 0.069, 0.576);
  static const _a = GlyphMetrics(0.583, 0.040, 0.523);
  static const _i = GlyphMetrics(0.296, 0.080, 0.216);
  static const _e = GlyphMetrics(0.608, 0.040, 0.5675);

  static const _letters = ['m', 'o', 'n', 'a', 'm', 'ı', 'e'];
  static const _metrics = [_m, _o, _n, _a, _m, _i, _e];

  /// The canvas' mean gap between neighbouring letters (its natural spacing
  /// less 0.045 em of letter-spacing), applied to every pair.
  static const inkGap = 0.0714;

  /// Distance from the top of a line one em tall to its baseline, in em:
  /// (1 - (ascent + descent)) / 2 + ascent with Manrope's 1.066 and 0.3.
  static const _baseline = 0.883;

  /// Index of the ı in [_letters], where the dot goes.
  static const _dotted = 5;

  @override
  Widget build(BuildContext context) {
    final origins = glyphOrigins(_metrics, inkGap);
    final width = (origins.last + _metrics.last.advance) * fontSize;
    return Semantics(
      label: MonAmieBrand.name.toLowerCase(),
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(width, fontSize),
        painter: _WordmarkPainter(
          fontSize: fontSize,
          color: color,
          origins: origins,
        ),
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  const _WordmarkPainter({
    required this.fontSize,
    required this.color,
    required this.origins,
  });

  final double fontSize;
  final Color color;
  final List<double> origins;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < MonAmieWordmark._letters.length; i++) {
      final glyph = TextPainter(
        text: TextSpan(
          text: MonAmieWordmark._letters[i],
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // The baseline of a one-em line, as CSS places it (Manrope: ascent
      // 1.066 em, descent 0.3 em, so 0.883 em from the top).
      final top =
          MonAmieWordmark._baseline * fontSize -
          glyph.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      glyph.paint(canvas, Offset(origins[i] * fontSize, top));
    }
    // 0.15 em wide, 0.13 em from the top, 0.073 em from the left of the ı.
    final dotLeft = (origins[MonAmieWordmark._dotted] + 0.073) * fontSize;
    canvas.drawCircle(
      Offset(dotLeft + 0.075 * fontSize, 0.205 * fontSize),
      0.075 * fontSize,
      Paint()..color = MonAmieBrand.coral,
    );
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) =>
      old.fontSize != fontSize || old.color != color;
}
