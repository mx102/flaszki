import 'dart:ui' show PictureRecorder;

import 'package:flaszki/src/ui/style/backdrop_painter.dart';
import 'package:flaszki/src/ui/style/flask_painter.dart';
import 'package:flaszki/src/ui/style/icon_painter.dart';
import 'package:flaszki/src/ui/style/orb_painter.dart';
import 'package:flaszki/src/ui/style/style_a.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('palette L1: Color ids 0–11 map to the PRD §5.1 hexes', () {
    const prd = [
      0xFFE6194B, // 0 red
      0xFF3CB44B, // 1 green
      0xFFFFE119, // 2 yellow
      0xFF4363D8, // 3 blue
      0xFFF58231, // 4 orange
      0xFF911EB4, // 5 purple
      0xFF42D4F4, // 6 cyan
      0xFFF032E6, // 7 magenta
      0xFF9AD61E, // 8 lime (L1)
      0xFFFABED4, // 9 pink
      0xFF9A6324, // 10 brown
      0xFFF4F4F4, // 11 white
    ];
    for (var id = 0; id < prd.length; id++) {
      expect(StyleA.color(id), Color(prd[id]), reason: 'id $id');
    }
    expect(StyleA.palette, hasLength(12));
  });

  test('same-Color neighbour Layers merge into one band', () {
    expect(fluidBands([0, 0, 3, 3, 3, 0]), const [
      FluidBand(0, 2),
      FluidBand(3, 3),
      FluidBand(0, 1),
    ]);
    expect(fluidBands([]), isEmpty);
  });

  group('painters do not throw at extreme sizes', () {
    const sizes = [
      Size.zero,
      Size(0.5, 0.5),
      Size(1, 400),
      Size(400, 1),
      Size(33, 70),
      Size(4000, 9000),
    ];
    final painters = <String, CustomPainter>{
      'flask empty': const FlaskPainter([]),
      'flask full': FlaskPainter(fluidBands([0, 11, 11, 8])),
      'flask fractional': const FlaskPainter([FluidBand(2, 2.5)]),
      'cork': const CorkPainter(),
      'orb': const OrbPainter(5, next: true),
      'orb empty': const OrbPainter(null),
      'backdrop': const BackdropPainter(),
      'shelves': const ShelfPainter([10, 200]),
      'icon': const IconPainter(),
    };
    for (final MapEntry(key: name, value: p) in painters.entries) {
      test(name, () {
        for (final s in sizes) {
          final rec = PictureRecorder();
          p.paint(Canvas(rec), s);
          rec.endRecording().dispose();
        }
      });
    }
  });
}
