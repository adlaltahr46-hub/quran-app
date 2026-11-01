import 'dart:math' as math;
import 'package:flutter/material.dart';

class PatternScroll extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;
  const PatternScroll({super.key, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: IslamicPatternPainter())),
        SingleChildScrollView(padding: padding, child: child),
      ],
    );
  }
}

class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF5F5EC),
    );
    final line = Paint()
      ..color = const Color(0xFF14513E).withOpacity(0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const s = 76.0;
    for (double y = 0; y < size.height + s; y += s) {
      for (double x = 0; x < size.width + s; x += s) {
        _star(canvas, Offset(x, y), s / 2, line);
        _diamond(canvas, Offset(x + s / 2, y + s / 2), s * 0.17, line);
      }
    }
  }

  void _star(Canvas canvas, Offset o, double r, Paint p) {
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (int i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2;
        final pt = Offset(o.dx + r * math.cos(a), o.dy + r * math.sin(a));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, p);
    }
    canvas.drawCircle(o, r * 0.32, p);
  }

  void _diamond(Canvas canvas, Offset o, double r, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy - r)
      ..lineTo(o.dx + r, o.dy)
      ..lineTo(o.dx, o.dy + r)
      ..lineTo(o.dx - r, o.dy)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
