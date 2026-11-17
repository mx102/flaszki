import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'style_a.dart';

/// Goal Queue glass orb (PRD §5): radial gradient lit from the top-left,
/// pale outline, glossy highlight. [color] null = empty glass orb.
class OrbPainter extends CustomPainter {
  const OrbPainter(this.color, {this.next = false});

  final int? color;

  /// The big NEXT orb gets a thicker rim.
  final bool next;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    if (r <= 0) return;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    final id = color;
    if (id == null) {
      canvas.drawCircle(c, r, Paint()..color = StyleA.glassFill);
    } else {
      final col = StyleA.color(id);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            focal: const Alignment(-0.35, -0.4),
            focalRadius: 0.05,
            colors: [StyleA.shade(col, 0.5), col, StyleA.shade(col, -0.5)],
            stops: const [0, 0.5, 1],
          ).createShader(rect),
      );
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(r * 0.2, next ? 2.5 : 1.5)
        ..color = StyleA.orbOutline,
    );
    canvas.save();
    canvas.translate(c.dx - r * 0.3, c.dy - r * 0.45);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.6, height: r * 0.3),
      Paint()..color = Color(id == null ? 0x40FFFFFF : 0x8CFFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(OrbPainter old) => old.color != color || old.next != next;
}
