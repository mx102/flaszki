// Test support: render a Color + pattern swatch and simulate color-vision
// deficiency (Machado et al. 2009, severity 1.0, linear RGB) in OKLab.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flaszki/src/ui/color_pattern.dart';
import 'package:flutter/widgets.dart';

/// PRD §5.1 palette (target hexes, independent of the app's style file).
const palette = [
  Color(0xFFE6194B),
  Color(0xFF3CB44B),
  Color(0xFFFFE119),
  Color(0xFF4363D8),
  Color(0xFFF58231),
  Color(0xFF911EB4),
  Color(0xFF42D4F4),
  Color(0xFFF032E6),
  Color(0xFF9AD61E),
  Color(0xFFFABED4),
  Color(0xFF9A6324),
  Color(0xFFF4F4F4),
];

/// Swatch edge in px: 4×4 pattern tiles, about one small Layer.
const int tileSize = 32;

enum Cvd { none, protan, deutan, tritan }

const _machado = {
  Cvd.protan: [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ],
  Cvd.deutan: [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.011820, 0.042940, 0.968881],
  ],
  Cvd.tritan: [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.303900],
  ],
};

double _toLin(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
double _toSrgb(double c) =>
    c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055;

/// sRGB (0–1) as seen with [cvd], linear RGB clamped.
List<double> simulateLinear(List<double> srgb, Cvd cvd) {
  final l = srgb.map(_toLin).toList();
  final m = _machado[cvd];
  final out = m == null
      ? l
      : [for (final r in m) r[0] * l[0] + r[1] * l[1] + r[2] * l[2]];
  return [for (final v in out) v.clamp(0.0, 1.0)];
}

/// sRGB bytes as seen with [cvd].
List<int> simulateSrgb8(List<int> rgb, Cvd cvd) => [
  for (final v in simulateLinear([for (final c in rgb) c / 255], cvd))
    (_toSrgb(v) * 255).round().clamp(0, 255),
];

List<double> oklab(List<double> lin) {
  final [r, g, b] = lin;
  double cbrt(double x) => math.pow(x, 1 / 3).toDouble();
  final l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  ];
}

/// OKLab distance ×100 between two sRGB byte triples seen with [cvd].
double deltaE(List<int> a, List<int> b, Cvd cvd) {
  final p = oklab(simulateLinear([for (final c in a) c / 255], cvd));
  final q = oklab(simulateLinear([for (final c in b) c / 255], cvd));
  return 100 *
      math.sqrt(
        math.pow(p[0] - q[0], 2) +
            math.pow(p[1] - q[1], 2) +
            math.pow(p[2] - q[2], 2),
      );
}

List<int> rgb8(Color c) => [
  (c.r * 255).round(),
  (c.g * 255).round(),
  (c.b * 255).round(),
];

/// A rendered swatch: base fill + [paintPattern].
class Tile {
  Tile(this.colorId, this.base, this.rgba);

  final int colorId;
  final Color base;
  final Uint8List rgba;

  List<int> pixel(int x, int y) {
    final i = (y * tileSize + x) * 4;
    return [rgba[i], rgba[i + 1], rgba[i + 2]];
  }

  /// Pixel differs visibly from the base fill when seen with [cvd].
  bool ink(int x, int y, [Cvd cvd = Cvd.none]) =>
      deltaE(pixel(x, y), rgb8(base), cvd) > visibleDeltaE;

  double get inkFraction => inkFractionFor(Cvd.none);

  double inkFractionFor(Cvd cvd) {
    var n = 0;
    for (var y = 0; y < tileSize; y++) {
      for (var x = 0; x < tileSize; x++) {
        if (ink(x, y, cvd)) n++;
      }
    }
    return n / (tileSize * tileSize);
  }

  /// Share of pixels whose ink/no-ink differs from [other]'s, under [cvd].
  double maskDifference(Tile other, Cvd cvd) {
    var n = 0;
    for (var y = 0; y < tileSize; y++) {
      for (var x = 0; x < tileSize; x++) {
        if (ink(x, y, cvd) != other.ink(x, y, cvd)) n++;
      }
    }
    return n / (tileSize * tileSize);
  }

  /// Swatch as seen with [cvd], as PNG-ready RGBA.
  Uint8List simulated(Cvd cvd) {
    final out = Uint8List.fromList(rgba);
    for (var i = 0; i < out.length; i += 4) {
      final s = simulateSrgb8([out[i], out[i + 1], out[i + 2]], cvd);
      out.setRange(i, i + 3, s);
    }
    return out;
  }
}

/// ΔE (OKLab ×100) at which ink counts as visible against the base.
const double visibleDeltaE = 8;

Future<Tile> renderTile(int colorId, Color base) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  const rect = Rect.fromLTWH(0, 0, tileSize + 0.0, tileSize + 0.0);
  canvas.drawRect(rect, Paint()..color = base);
  paintPattern(canvas, rect, colorId, base);
  final img = await rec.endRecording().toImage(tileSize, tileSize);
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  return Tile(colorId, base, data!.buffer.asUint8List());
}
