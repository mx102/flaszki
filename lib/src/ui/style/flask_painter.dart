import 'dart:math' as math;

import 'package:flaszki_logic/flaszki_logic.dart' show flaskCapacity;
import 'package:flutter/widgets.dart';

import '../../play/board_layout.dart' show neckRatio;
import '../color_fill.dart';
import '../color_pattern.dart';
import 'style_a.dart';

/// One fluid band: [layers] (may be fractional, for pour animation #27)
/// of Color [color]. Bottom → top in a Flask.
@immutable
class FluidBand {
  const FluidBand(this.color, this.layers);

  final int color;
  final double layers;

  @override
  bool operator ==(Object other) =>
      other is FluidBand && other.color == color && other.layers == layers;

  @override
  int get hashCode => Object.hash(color, layers);

  @override
  String toString() => 'FluidBand($color × $layers)';
}

/// Layers bottom → top as bands; same-Color neighbours merge (PRD §5).
List<FluidBand> fluidBands(List<int> layers) {
  final out = <FluidBand>[];
  for (final c in layers) {
    if (out.isNotEmpty && out.last.color == c) {
      out.last = FluidBand(c, out.last.layers + 1);
    } else {
      out.add(FluidBand(c, 1));
    }
  }
  return out;
}

/// Tube geometry inside a glass box of [size] (BoardMetrics.glassWidth ×
/// glassHeight). The tube is ~3:1, narrower than the box; the flared lip
/// spans 1.2 × [tubeWidth].
class FlaskGeometry {
  FlaskGeometry(this.size, {double tubeAspect = 3})
    : layer = size.height / (flaskCapacity + neckRatio),
      tubeWidth = math.min(size.height / tubeAspect, size.width / 1.2);

  final Size size;

  /// One Layer's height (= BoardMetrics.layerHeight).
  final double layer;
  final double tubeWidth;

  double get centerX => size.width / 2;
  double get lipWidth => tubeWidth * 1.2;

  /// Bottom of the fluid column (Layer 0's bottom edge).
  double get fluidBottom => size.height * 0.98;

  /// Top edge of Layer slot [j] (0 = bottom).
  double layerTop(double j) => fluidBottom - (j + 1) * layer;

  Path get path {
    final w = tubeWidth, h = size.height, r = w / 2;
    final l = centerX - w / 2, rt = centerX + w / 2;
    return Path()
      ..moveTo(l - w * 0.1, 0)
      ..lineTo(rt + w * 0.1, 0)
      ..lineTo(rt, h * 0.05)
      ..lineTo(rt, h - r)
      ..arcToPoint(Offset(l, h - r), radius: Radius.circular(r))
      ..lineTo(l, h * 0.05)
      ..close();
  }
}

/// Paints one apothecary-glass Flask: faint glass fill, fluid bands with
/// a horizontal gradient (darker edges) and a meniscus on the top band,
/// outline, two specular streaks. Pure function of its inputs, so #27 can
/// feed fractional [bands] during a Pour and #28 can add patterns.
class FlaskPainter extends CustomPainter implements PatternedPainter {
  const FlaskPainter(
    this.bands, {
    this.tilt = 0,
    this.tubeAspect = 3,
    this.outlineWidth,
    this.patterned = false,
  });

  final List<FluidBand> bands;

  /// Rotation (radians, clockwise) about the box centre; the fluid surface
  /// stays level (PRD §5). Used by the icon now and by pour juice (#27).
  final double tilt;

  /// Tube height : width (the icon uses a stubbier tube).
  final double tubeAspect;

  /// Outline stroke; default scales with the tube, 1–2.5 px.
  final double? outlineWidth;

  /// Colorblind patterns over each band (PRD §5.1, Settings #28).
  @override
  final bool patterned;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final g = FlaskGeometry(size, tubeAspect: tubeAspect);
    final path = g.path;
    final w = g.tubeWidth, cx = g.centerX, h = size.height;
    final c = Offset(cx, h / 2);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(tilt);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawPath(path, Paint()..color = StyleA.glassFill);

    // Fluid in a level (un-rotated) frame centred on the box.
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-tilt);
    final ct = math.cos(tilt), st = math.sin(tilt).abs();
    final low = w / 2 * st + (g.fluidBottom - h / 2) * ct;
    final thick = g.layer * math.max(ct, 0.4);
    var y = low + h; // first band overdraws into the round bottom
    var surface = low;
    final shown = [
      for (final b in bands)
        if (b.layers > 0) b,
    ];
    for (final (i, b) in shown.indexed) {
      final top = surface - thick * b.layers;
      final col = StyleA.color(b.color);
      final rect = Rect.fromLTRB(-h, top, h, y + 1);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              StyleA.shade(col, -0.35),
              StyleA.shade(col, 0.12),
              StyleA.shade(col, -0.45),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromLTRB(-w / 2, top, w / 2, y)),
      );
      if (patterned) {
        paintPattern(
          canvas,
          Rect.fromLTRB(-w / 2, top, w / 2, y + 1),
          b.color,
          col,
          tile: (g.layer * 0.3).clamp(5.0, 10.0),
        );
      }
      if (i == shown.length - 1) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, top),
            width: w * 0.96,
            height: g.layer * 0.18,
          ),
          Paint()..color = const Color(0x47FFFFFF),
        );
      }
      y = surface = top;
    }
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth ?? (w * 0.045).clamp(1.0, 2.5)
        ..strokeJoin = StrokeJoin.round
        ..color = StyleA.glassOutline,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.36, h * 0.1, w * 0.12, h * 0.72),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = const Color(0x38FFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.22, h * 0.15, w * 0.06, h * 0.4),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = const Color(0x1AFFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(FlaskPainter old) =>
      old.tilt != tilt ||
      old.tubeAspect != tubeAspect ||
      old.outlineWidth != outlineWidth ||
      old.patterned != patterned ||
      !_sameBands(old.bands, bands);

  static bool _sameBands(List<FluidBand> a, List<FluidBand> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Tapered cork with pores, filling its box (wide top, narrower bottom).
class CorkPainter extends CustomPainter {
  const CorkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height, inset = w * 0.083;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w - inset, h)
        ..lineTo(inset, h)
        ..close(),
      Paint()..color = StyleA.cork,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.18),
      Paint()..color = const Color(0x22FFFFFF),
    );
    final pore = Paint()..color = StyleA.corkPores;
    final r = math.max(0.6, w * 0.035);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(w * (0.22 + i * 0.14), h * (i.isEven ? 0.4 : 0.66)),
        r,
        pore,
      );
    }
  }

  @override
  bool shouldRepaint(CorkPainter old) => false;
}
