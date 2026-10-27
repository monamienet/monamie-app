import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Side of the square logo PNG the app uploads.
const logoSide = 512;

/// Largest file the owner may pick (the canvas promises 10 MB).
const maxLogoInputBytes = 10 * 1024 * 1024;

/// Why a picked file cannot become the logo, in words for the owner.
class LogoException implements Exception {
  const LogoException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Whether [bytes] look like an SVG document rather than a bitmap.
bool looksLikeSvg(Uint8List bytes) {
  final head = String.fromCharCodes(bytes.take(512)).toLowerCase();
  return head.contains('<svg') ||
      (head.trimLeft().startsWith('<?xml') && head.contains('svg'));
}

/// The rectangle where an image of [size] fits inside a [side]-sized square,
/// centered and keeping its proportions (letterboxed, never cropped).
Rect containRect(Size size, double side) {
  if (size.width <= 0 || size.height <= 0) return Rect.zero;
  final scale = side / (size.width > size.height ? size.width : size.height);
  final width = size.width * scale;
  final height = size.height * scale;
  return Rect.fromLTWH((side - width) / 2, (side - height) / 2, width, height);
}

/// Converts any picked file (SVG, PNG, JPEG, WebP, or HEIC where the
/// platform decodes it) into a square [logoSide] px PNG with a transparent
/// background. Only this PNG is uploaded, so an SVG is never stored.
Future<Uint8List> toSquareLogoPng(Uint8List bytes) async {
  if (bytes.length > maxLogoInputBytes) {
    final mb = (bytes.length / (1024 * 1024)).ceil();
    throw LogoException('O arquivo tem $mb MB. Envie um de até 10 MB.');
  }
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = logoSide.toDouble();
  try {
    if (looksLikeSvg(bytes)) {
      final info = await vg.loadPicture(SvgBytesLoader(bytes), null);
      final target = containRect(info.size, side);
      canvas
        ..translate(target.left, target.top)
        ..scale(target.width / info.size.width, target.height / info.size.height)
        ..drawPicture(info.picture);
      info.picture.dispose();
    } else {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final source = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      canvas.drawImageRect(
        image,
        source,
        containRect(source.size, side),
        Paint()..filterQuality = FilterQuality.high,
      );
      image.dispose();
    }
  } catch (_) {
    throw const LogoException(
      'Não deu para abrir este arquivo. Envie em PNG, JPEG, WebP ou SVG.',
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(logoSide, logoSide);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  if (data == null) {
    throw const LogoException('Não deu para gerar o PNG do logo.');
  }
  return data.buffer.asUint8List();
}
