import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/monamie_wordmark.dart';

// Values are powers of two so the sums are exact in binary floating point.
const narrow = GlyphMetrics(1.0, 0.125, 0.875);
const wide = GlyphMetrics(1.5, 0.5, 1.0);

void main() {
  group('glyphOrigins - Unit Test Suite', () {
    test('Happy Path: two glyphs with different bearings sit inkGap apart', () {
      // 1. Arrange
      const glyphs = [
        GlyphMetrics(1.0, 0.25, 0.75),
        GlyphMetrics(1.0, 0.5, 0.875),
      ];

      // 2. Act
      final origins = glyphOrigins(glyphs, 0.125);

      // 3. Assert
      // Ink of the first ends at 0.75; the second must start at 0.875, so its
      // cell starts at 0.875 - 0.5.
      expect(origins, [0.0, 0.375]);
    });

    test('Happy Path: a wide-bearing glyph between two narrow ones', () {
      // 1. Arrange
      const glyphs = [narrow, wide, narrow];

      // 2. Act
      final origins = glyphOrigins(glyphs, 0.25);

      // 3. Assert
      // 0.875 + 0.25 - 0.5 = 0.625; 0.625 + 1.0 + 0.25 - 0.125 = 1.75.
      expect(origins, [0.0, 0.625, 1.75]);
    });

    test('Edge Case: a zero gap makes the ink touch', () {
      // 1. Arrange
      const glyphs = [narrow, wide, narrow];

      // 2. Act
      final origins = glyphOrigins(glyphs, 0);

      // 3. Assert
      expect(origins, [0.0, 0.375, 1.25]);
    });

    test('Edge Case: a negative gap makes the ink overlap', () {
      // 1. Arrange
      const glyphs = [narrow, wide, narrow];

      // 2. Act
      final origins = glyphOrigins(glyphs, -0.125);

      // 3. Assert
      expect(origins, [0.0, 0.25, 1.0]);
    });

    test('Edge Case: the first origin is 0 whatever its left bearing', () {
      // 1. Arrange
      const glyphs = [GlyphMetrics(2.0, 0.75, 1.5), narrow];

      // 2. Act
      final origins = glyphOrigins(glyphs, 0.25);

      // 3. Assert
      expect(origins.first, 0.0);
    });

    test('Edge Case: one glyph gives [0]', () {
      // 1. Arrange / 2. Act
      final origins = glyphOrigins(const [wide], 0.25);

      // 3. Assert
      expect(origins, [0.0]);
    });

    test('Sad Path: an empty list gives an empty list', () {
      // 1. Arrange / 2. Act
      final origins = glyphOrigins(const [], 0.25);

      // 3. Assert
      expect(origins, isEmpty);
    });
  });
}
