import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/admin/logo_converter.dart';

/// A valid 2x1 RGBA PNG (two red pixels).
final tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAABCAYAAAD0In+KAAAADklEQVR4nGP4z8DwH4QBEfcD/'
  'ePF9e8AAAAASUVORK5CYII=',
);

Uint8List ascii(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  group('looksLikeSvg - Unit Test Suite', () {
    final cases = <({String label, Uint8List bytes, bool expected})>[
      (
        label: 'Happy Path: bytes starting with <svg are an SVG',
        bytes: ascii('<svg xmlns="http://www.w3.org/2000/svg"><rect/></svg>'),
        expected: true,
      ),
      (
        label: 'Edge Case: an XML prolog before the svg element is an SVG',
        bytes: ascii(
          '<?xml version="1.0" encoding="UTF-8"?>\n'
          '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "x">\n<svg/>',
        ),
        expected: true,
      ),
      (
        label: 'Edge Case: an upper case <SVG is an SVG',
        bytes: ascii('<SVG></SVG>'),
        expected: true,
      ),
      (
        label: 'Sad Path: PNG magic bytes are not an SVG',
        bytes: tinyPng,
        expected: false,
      ),
      (
        label: 'Sad Path: JPEG magic bytes are not an SVG',
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, 0x4A]),
        expected: false,
      ),
      (
        label: 'Sad Path: an XML document that is not an SVG is not an SVG',
        bytes: ascii('<?xml version="1.0"?><note>hi</note>'),
        expected: false,
      ),
      (
        label: 'Sad Path: no bytes are not an SVG',
        bytes: Uint8List(0),
        expected: false,
      ),
    ];
    for (final c in cases) {
      test(c.label, () {
        // 1. Arrange
        final bytes = c.bytes;

        // 2. Act
        final svg = looksLikeSvg(bytes);

        // 3. Assert
        expect(svg, c.expected);
      });
    }
  });

  group('containRect - Unit Test Suite', () {
    final cases = <({String label, Size size, double side, Rect expected})>[
      (
        label: 'Happy Path: a wide image is letterboxed top and bottom',
        size: const Size(200, 100),
        side: 512,
        expected: const Rect.fromLTWH(0, 128, 512, 256),
      ),
      (
        label: 'Happy Path: a tall image is letterboxed left and right',
        size: const Size(100, 200),
        side: 512,
        expected: const Rect.fromLTWH(128, 0, 256, 512),
      ),
      (
        label: 'Edge Case: a square image fills the square',
        size: const Size(30, 30),
        side: 512,
        expected: const Rect.fromLTWH(0, 0, 512, 512),
      ),
      (
        label: 'Edge Case: a bigger image is scaled down, not cropped',
        size: const Size(2048, 1024),
        side: 512,
        expected: const Rect.fromLTWH(0, 128, 512, 256),
      ),
      (
        label: 'Sad Path: a zero size gives Rect.zero',
        size: Size.zero,
        side: 512,
        expected: Rect.zero,
      ),
      (
        label: 'Sad Path: a zero width gives Rect.zero',
        size: const Size(0, 100),
        side: 512,
        expected: Rect.zero,
      ),
    ];
    for (final c in cases) {
      test('${c.label} (${c.size})', () {
        // 1. Arrange
        final size = c.size;

        // 2. Act
        final rect = containRect(size, c.side);

        // 3. Assert
        expect(rect, c.expected);
      });
    }
  });

  group('toSquareLogoPng - Unit Test Suite', () {
    testWidgets('Happy Path: a tiny PNG becomes a 512x512 PNG', (tester) async {
      // 1. Arrange
      final bytes = tinyPng;

      // 2. Act
      final png = (await tester.runAsync(() => toSquareLogoPng(bytes)))!;

      // 3. Assert
      final size = (await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(png);
        final image = (await codec.getNextFrame()).image;
        return [image.width, image.height];
      }))!;
      expect(
        [png.sublist(0, 4), size],
        [
          [0x89, 0x50, 0x4E, 0x47],
          [512, 512],
        ],
      );
    });

    test('Edge Case: a file of exactly 10 MiB passes the size check', () async {
      // 1. Arrange
      final bytes = Uint8List(10 * 1024 * 1024);

      // 2. Act
      final result = toSquareLogoPng(bytes);

      // 3. Assert
      await expectLater(
        result,
        throwsA(
          isA<LogoException>().having(
            (e) => e.message,
            'message',
            isNot(startsWith('O arquivo tem')),
          ),
        ),
      );
    });

    test('Sad Path: a file over 10 MiB is rejected for its size', () async {
      // 1. Arrange
      final bytes = Uint8List(10 * 1024 * 1024 + 1);

      // 2. Act
      final result = toSquareLogoPng(bytes);

      // 3. Assert
      await expectLater(
        result,
        throwsA(
          isA<LogoException>().having(
            (e) => e.message,
            'message',
            startsWith('O arquivo tem'),
          ),
        ),
      );
    });

    test('Sad Path: garbage bytes throw a LogoException', () async {
      // 1. Arrange
      final bytes = ascii('this is not an image');

      // 2. Act
      final result = toSquareLogoPng(bytes);

      // 3. Assert
      await expectLater(result, throwsA(isA<LogoException>()));
    });
  });
}
