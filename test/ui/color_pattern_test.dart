import 'package:flaszki/src/ui/color_pattern.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cvd.dart';

void main() {
  test('each Color id has its own pattern, PRD §5.1 order', () {
    expect([for (var i = 0; i < 12; i++) patternOf(i)], ColorPattern.values);
    expect(patternOf(0), ColorPattern.none);
    expect(patternOf(2), ColorPattern.vStripes);
    expect(patternOf(11), ColorPattern.bigDot);
  });

  test('ink is black on light Colors, white on dark ones', () {
    expect(patternInk(const Color(0xFFFFE119)).b, 0); // yellow → black
    expect(patternInk(const Color(0xFFF4F4F4)).b, 0); // white → black
    expect(patternInk(const Color(0xFF4363D8)).b, 1); // blue → white
    expect(patternInk(const Color(0xFF911EB4)).b, 1); // purple → white
  });

  testWidgets('red (none) paints nothing; others paint ink', (tester) async {
    await tester.runAsync(() async {
      final red = await renderTile(0, palette[0]);
      expect(red.inkFraction, 0);
      for (var id = 1; id < 12; id++) {
        final t = await renderTile(id, palette[id]);
        expect(t.inkFraction, greaterThan(0.05), reason: 'Color $id');
      }
    });
  });

  testWidgets('h-stripes vary by row only, v-stripes by column only', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final h = await renderTile(1, palette[1]);
      final v = await renderTile(2, palette[2]);
      for (var y = 0; y < tileSize; y++) {
        for (var x = 0; x < tileSize; x++) {
          expect(h.ink(x, y), h.ink(0, y));
          expect(v.ink(x, y), v.ink(x, 0));
        }
      }
    });
  });
}
