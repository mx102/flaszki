import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../style/style_a.dart';

/// One Pour's stream / splash / bubbles in board coordinates (PRD §5).
@immutable
class PourFx {
  const PourFx({
    required this.mouth,
    required this.surface,
    required this.side,
    required this.color,
    required this.stream,
    required this.tube,
    required this.layer,
    required this.pourStart,
    required this.pourLength,
    required this.t,
    required this.seed,
  });

  /// Source mouth and target fluid surface (stream end).
  final Offset mouth, surface;

  /// +1 = target right of source.
  final double side;
  final int color;

  /// Stream thickness factor 0..1.
  final double stream;

  /// Target tube interior (bubbles rise in it).
  final Rect tube;
  final double layer;

  /// Seconds since the Pour began; pour phase start / length.
  final double pourStart, pourLength, t;

  /// Per-Pour seed so droplets differ between Pours, deterministically.
  final int seed;
}

/// Hash-based pseudo-random 0..1, deterministic per (seed, k, salt).
double _rand(int seed, int k, int salt) {
  var h = (seed * 73856093) ^ (k * 19349663) ^ (salt * 83492791);
  h = (h ^ (h >> 13)) * 1274126177;
  h ^= h >> 16;
  return (h & 0xFFFF) / 0xFFFF;
}

const int _drops = 16, _bubbles = 8;
const double _dropLife = 0.5, _gravity = 700;

/// Curved stream with a light core, splash droplets at the target surface,
/// bubbles rising in the target. Pure function of [fx] (no particle state),
/// so any frame can be drawn at any time.
class PourFxPainter extends CustomPainter {
  const PourFxPainter(this.fx);

  final List<PourFx> fx;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in fx) {
      _paintOne(canvas, f);
    }
  }

  void _paintOne(Canvas canvas, PourFx f) {
    final col = StyleA.color(f.color);
    final w = f.tube.width;
    final scale = f.layer / 30;
    if (f.stream > 0) {
      final m = f.mouth, e = f.surface;
      final ctrl = Offset((m.dx + e.dx) / 2 + f.side * w * 0.3, m.dy - 6);
      final path = Path()
        ..moveTo(m.dx, m.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, e.dx, e.dy);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w * 0.28 * f.stream
          ..color = StyleA.shade(col, -0.1),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w * 0.07 * f.stream
          ..color = const Color(0x59FFFFFF),
      );
    }
    // Splash droplets: emitted across the pour phase from the surface.
    for (var k = 0; k < _drops; k++) {
      final te = f.pourStart + f.pourLength * k / _drops;
      final dt = f.t - te;
      if (dt < 0 || dt >= _dropLife) continue;
      final vx = (_rand(f.seed, k, 1) - .5) * 90 * scale;
      final vy = (-60 - _rand(f.seed, k, 2) * 120) * scale;
      final p = Offset(
        f.surface.dx + (_rand(f.seed, k, 3) - .5) * w * 0.6 + vx * dt,
        f.surface.dy + vy * dt + 0.5 * _gravity * scale * dt * dt,
      );
      final a = 1 - dt / _dropLife;
      canvas.drawCircle(
        p,
        (1.5 + _rand(f.seed, k, 4) * 2.5) * scale.clamp(0.6, 1.4),
        Paint()..color = col.withValues(alpha: a),
      );
    }
    // Bubbles rising inside the target from the start of the stream.
    canvas.save();
    canvas.clipRect(f.tube);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var k = 0; k < _bubbles; k++) {
      final te = f.pourStart + f.pourLength * 0.3 * k / _bubbles;
      final life = 0.5 + _rand(f.seed, k, 5) * 0.4;
      final dt = f.t - te;
      if (dt < 0 || dt >= life) continue;
      final x = f.tube.left + f.tube.width * (0.2 + _rand(f.seed, k, 6) * 0.6);
      final y = f.tube.bottom - f.layer * 0.4 - dt * f.layer * 2.4;
      if (y < f.surface.dy) continue;
      ring.color = Color.fromRGBO(255, 255, 255, 0.6 * (1 - dt / life));
      canvas.drawCircle(
        Offset(x, y),
        math.max(1, (1 + _rand(f.seed, k, 7) * 2.2) * scale),
        ring,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PourFxPainter old) => true;
}
