// #28 acceptance: all 12 Colors distinguishable with patterns on under
// protan/deutan/tritan simulation (Machado 2009, severity 1.0).
//
// Set FLASZKI_PATTERN_OUT=<dir> to also write sample PNGs (one sheet per
// vision type, 12 swatches in a 4×3 grid at 2×).
@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'cvd.dart';

/// Pattern masks of two Colors must differ on at least this share of
/// pixels, as seen with the deficiency (hue alone is not trusted).
const double minMaskDifference = 0.15;

void main() {
  late List<Tile> tiles;

  setUpAll(() async {
    tiles = [for (var id = 0; id < 12; id++) await renderTile(id, palette[id])];
  });

  for (final cvd in Cvd.values) {
    test('every Color pair is told apart by its pattern (${cvd.name})', () {
      final failures = <String>[];
      for (var i = 0; i < 12; i++) {
        for (var j = i + 1; j < 12; j++) {
          final d = tiles[i].maskDifference(tiles[j], cvd);
          if (d < minMaskDifference) {
            failures.add('$i vs $j: ${(d * 100).toStringAsFixed(1)}%');
          }
        }
      }
      expect(failures, isEmpty);
    });

    test(
      'pattern ink stays visible on every patterned Color (${cvd.name})',
      () {
        for (var id = 1; id < 12; id++) {
          expect(
            tiles[id].inkFractionFor(cvd),
            greaterThan(0.1),
            reason: 'Color $id',
          );
        }
      },
    );
  }

  test('writes sample sheets when FLASZKI_PATTERN_OUT is set', () async {
    final out = Platform.environment['FLASZKI_PATTERN_OUT'];
    if (out == null) return;
    Directory(out).createSync(recursive: true);
    for (final cvd in Cvd.values) {
      final png = await _sheet(tiles, cvd);
      File('$out/patterns_${cvd.name}.png').writeAsBytesSync(png);
    }
  });
}

Future<Uint8List> _sheet(List<Tile> tiles, Cvd cvd) async {
  const scale = 2, gap = 4, cols = 4, rows = 3;
  const cell = tileSize * scale + gap;
  const w = cols * cell + gap, h = rows * cell + gap;
  final px = Uint8List(w * h * 4);
  for (var i = 0; i < px.length; i += 4) {
    px.setRange(i, i + 4, [0x1B, 0x24, 0x40, 0xFF]);
  }
  for (final t in tiles) {
    final sim = t.simulated(cvd);
    final ox = gap + (t.colorId % cols) * cell;
    final oy = gap + (t.colorId ~/ cols) * cell;
    for (var y = 0; y < tileSize * scale; y++) {
      for (var x = 0; x < tileSize * scale; x++) {
        final s = ((y ~/ scale) * tileSize + x ~/ scale) * 4;
        final d = ((oy + y) * w + ox + x) * 4;
        px.setRange(d, d + 4, sim, s);
      }
    }
  }
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(px, w, h, ui.PixelFormat.rgba8888, c.complete);
  final img = await c.future;
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}
