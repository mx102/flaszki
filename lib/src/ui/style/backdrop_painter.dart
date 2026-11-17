import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'style_a.dart';

/// Night-blue vertical gradient + radial vignette (PRD §5). Fills the whole
/// window, so the sides of the portrait column match on desktop/web.
class BackdropPainter extends CustomPainter {
  const BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [StyleA.skyTop, StyleA.skyBottom],
        ).createShader(rect),
    );
    // Prototype: radial from 40 px to 0.7 H around (W/2, 0.45 H).
    final outer = size.height * 0.7;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: outer / size.shortestSide,
          colors: const [StyleA.vignetteCenter, StyleA.vignetteEdge],
          stops: [math.min(1, 40 / outer), 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(BackdropPainter old) => false;
}

/// Faint shelf line under each board row; [rowBottoms] are y positions in
/// the board's coordinates.
class ShelfPainter extends CustomPainter {
  const ShelfPainter(this.rowBottoms);

  final List<double> rowBottoms;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = math.min(12.0, size.width / 4);
    final p = Paint()
      ..color = StyleA.shelf
      ..strokeWidth = 2;
    for (final y in rowBottoms) {
      canvas.drawLine(Offset(inset, y), Offset(size.width - inset, y), p);
    }
  }

  @override
  bool shouldRepaint(ShelfPainter old) =>
      old.rowBottoms.length != rowBottoms.length ||
      [
        for (var i = 0; i < rowBottoms.length; i++)
          old.rowBottoms[i] != rowBottoms[i],
      ].any((d) => d);
}
