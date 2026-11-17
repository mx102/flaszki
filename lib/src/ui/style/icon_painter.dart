import 'package:flutter/widgets.dart';

import 'flask_painter.dart';

/// App icon (PRD §5): one tilted glass tube with 4 Layers on the
/// night-blue gradient. The icon is all rights reserved (ADR 0003).
///
/// [rounded] clips to a rounded square (web/desktop); store icons are
/// square and the platform masks them. [foregroundOnly] draws just the tube
/// at Android-adaptive safe-zone scale on transparency; [backgroundOnly]
/// just the gradient (adaptive background layer).
class IconPainter extends CustomPainter {
  const IconPainter({
    this.rounded = false,
    this.foregroundOnly = false,
    this.backgroundOnly = false,
  });

  final bool rounded;
  final bool foregroundOnly;
  final bool backgroundOnly;

  /// Layers bottom → top: blue, yellow, red, lime.
  static const layers = [3, 2, 0, 8];
  static const tilt = 0.22;
  static const top = Color(0xFF24406A);
  static const bottom = Color(0xFF0B1424);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = size.shortestSide;
    final rect = Offset.zero & Size.square(s);
    canvas.save();
    if (rounded) {
      canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(s * .22)));
    }
    if (!foregroundOnly) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(rect),
      );
    }
    if (backgroundOnly) {
      canvas.restore();
      return;
    }
    // Adaptive foreground: content must sit in the inner 66 %.
    final fh = s * (foregroundOnly ? 0.5 : 0.72);
    final box = Size(fh / 2.6 * 1.25, fh);
    canvas.translate(s / 2 - box.width / 2, s * 0.53 - fh / 2);
    FlaskPainter(
      fluidBands(layers),
      tilt: tilt,
      tubeAspect: 2.6,
      outlineWidth: s * 0.012,
    ).paint(canvas, box);
    canvas.restore();
  }

  @override
  bool shouldRepaint(IconPainter old) =>
      old.rounded != rounded ||
      old.foregroundOnly != foregroundOnly ||
      old.backgroundOnly != backgroundOnly;
}
