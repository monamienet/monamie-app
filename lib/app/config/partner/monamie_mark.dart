import 'package:flutter/widgets.dart';

import 'monamie_brand.dart';

/// The MonAmie "Encontro" mark: two chevrons meeting at a coral point.
///
/// Drawn in code from the brand's 100×60 grid, so it scales without an
/// asset. [color] is the chevrons' color (cream on navy, navy on cream).
class MonAmieMark extends StatelessWidget {
  const MonAmieMark({super.key, this.width = 40, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: MonAmieBrand.name,
    image: true,
    child: CustomPaint(
      size: Size(width, width * 0.6),
      painter: _MarkPainter(color),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The brand grid is 100 wide and 60 tall (viewBox "0 20 100 60").
    canvas.scale(size.width / 100, size.height / 60);
    canvas.translate(0, -20);
    final ink = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(2, 20)
        ..lineTo(18, 20)
        ..lineTo(35, 50)
        ..lineTo(18, 80)
        ..lineTo(2, 80)
        ..lineTo(19, 50)
        ..close(),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(98, 20)
        ..lineTo(82, 20)
        ..lineTo(65, 50)
        ..lineTo(82, 80)
        ..lineTo(98, 80)
        ..lineTo(81, 50)
        ..close(),
      ink,
    );
    canvas.drawCircle(
      const Offset(50, 50),
      10,
      Paint()..color = MonAmieBrand.coral,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}
