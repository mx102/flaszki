import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

/// `colors×perColor` for Level [n], e.g. `'3x1'`.
String cfg(int n) {
  final p = curve(n);
  return '${p.colorCount}x${p.flasksPerColor}';
}

void main() {
  test('ramp: 3 Colors L1–3, +1 every 4 Levels, 12 Colors L36–40', () {
    expect([for (var n = 1; n <= 4; n++) cfg(n)], ['3x1', '3x1', '3x1', '4x1']);
    expect(cfg(7), '4x1');
    expect(cfg(8), '5x1');
    expect(cfg(11), '5x1');
    expect(cfg(32), '11x1');
    expect(cfg(34), '11x1');
    expect(cfg(36), '12x1');
    expect(cfg(39), '12x1');
  });

  test('Breather every 5th Level up to L40 uses ramp(max(1, N − 8))', () {
    expect(cfg(5), '3x1'); // ramp(1)
    expect(cfg(10), '3x1'); // ramp(2)
    expect(cfg(15), '4x1'); // ramp(7)
    expect(cfg(20), '6x1'); // ramp(12)
    expect(cfg(35), '9x1'); // ramp(27)
    expect(cfg(40), '11x1'); // ramp(32)
  });

  test('endless cycle from L41, Breathers (8×1) take priority', () {
    expect(
      [for (var n = 41; n <= 47; n++) cfg(n)],
      [
        '12x1', // 41
        '10x1', // 42
        '7x2', // 43
        '11x1', // 44
        '8x1', // 45: Breather
        '6x2', // 46
        '12x1', // 47: cycle restarts
      ],
    );
    expect(cfg(50), '8x1');
    expect(cfg(1000), '8x1');
    expect(cfg(1001), '12x1'); // (1001 − 41) mod 6 = 0
  });

  test('always 2 empty Flasks, capacity 4, board ≤ 16 Flasks', () {
    for (var n = 1; n <= 600; n++) {
      final p = curve(n);
      expect(p.emptyFlasks, 2);
      expect(p.capacity, 4);
      expect(p.colorCount, inInclusiveRange(3, 12));
      expect(p.colorCount * p.flasksPerColor + p.emptyFlasks, lessThan(17));
    }
  });

  test('rejects Level numbers below 1', () {
    expect(() => curve(0), throwsArgumentError);
  });
}
