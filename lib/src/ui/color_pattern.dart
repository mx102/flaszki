import 'package:flutter/widgets.dart';

/// Colorblind pattern per Color id (PRD §5.1); index = Color id.
enum ColorPattern {
  none,
  hStripes,
  vStripes,
  diagonal,
  dots,
  checks,
  zigzag,
  grid,
  crosshatch,
  rings,
  backDiagonal,
  bigDot,
}

ColorPattern patternOf(int colorId) =>
    ColorPattern.values[colorId % ColorPattern.values.length];

/// Black or white, whichever contrasts with [base] (PRD §5.1).
Color patternInk(Color base) => base.computeLuminance() > 0.35
    ? const Color(0x8C000000) // black @ 0.55
    : const Color(0xB3FFFFFF); // white @ 0.7

/// Default pattern tile edge, logical px.
const double patternTile = 8;

/// Paints Color [colorId]'s pattern over [rect] (already filled with
/// [baseColor]) in contrasting ink. Self-contained: Layer and Goal Queue orb
/// painters call it when colorblind patterns are on. Clips to [rect]; tiles
/// are anchored at its top-left. Callers clip to non-rect shapes (orbs).
void paintPattern(
  Canvas canvas,
  Rect rect,
  int colorId,
  Color baseColor, {
  double tile = patternTile,
}) {
  final pattern = patternOf(colorId);
  if (pattern == ColorPattern.none || rect.isEmpty) return;
  final k = tile / 8;
  final (path, fill) = _unitTile(pattern);
  final scaled = path.transform(Matrix4.diagonal3Values(k, k, 1).storage);
  final paint = Paint()
    ..color = patternInk(baseColor)
    ..isAntiAlias = true
    ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
    ..strokeWidth = 1.6 * k;
  canvas
    ..save()
    ..clipRect(rect);
  for (var y = rect.top; y < rect.bottom; y += tile) {
    for (var x = rect.left; x < rect.right; x += tile) {
      canvas.drawPath(scaled.shift(Offset(x, y)), paint);
    }
  }
  canvas.restore();
}

/// One 8×8 tile (prototype/palette): path + whether it is filled.
(Path, bool) _unitTile(ColorPattern p) {
  Path lines(List<(double, double, double, double)> segs) {
    final path = Path();
    for (final (x0, y0, x1, y1) in segs) {
      path
        ..moveTo(x0, y0)
        ..lineTo(x1, y1);
    }
    return path;
  }

  Path circle(double r) =>
      Path()..addOval(Rect.fromCircle(center: const Offset(4, 4), radius: r));

  return switch (p) {
    ColorPattern.none => (Path(), false),
    ColorPattern.hStripes => (lines([(0, 3, 8, 3)]), false),
    ColorPattern.vStripes => (lines([(3, 0, 3, 8)]), false),
    ColorPattern.diagonal => (
      lines([(-2, 2, 2, -2), (0, 8, 8, 0), (6, 10, 10, 6)]),
      false,
    ),
    ColorPattern.dots => (circle(1.7), true),
    ColorPattern.checks => (
      Path()
        ..addRect(const Rect.fromLTWH(0, 0, 4, 4))
        ..addRect(const Rect.fromLTWH(4, 4, 4, 4)),
      true,
    ),
    ColorPattern.zigzag => (
      Path()
        ..moveTo(0, 5)
        ..lineTo(2, 2)
        ..lineTo(4, 5)
        ..lineTo(6, 2)
        ..lineTo(8, 5),
      false,
    ),
    ColorPattern.grid => (lines([(0, 0.8, 8, 0.8), (0.8, 0, 0.8, 8)]), false),
    ColorPattern.crosshatch => (lines([(0, 0, 8, 8), (8, 0, 0, 8)]), false),
    ColorPattern.rings => (circle(2.4), false),
    ColorPattern.backDiagonal => (
      lines([(-2, 6, 2, 10), (0, 0, 8, 8), (6, -2, 10, 2)]),
      false,
    ),
    ColorPattern.bigDot => (circle(2.6), true),
  };
}
