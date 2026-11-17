import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

/// ADR 0002: PRNG output is pinned and must be identical on VM, wasm and
/// dart2js. Expected values come from an independent Python reference
/// (unbounded ints masked to 32 bits) and the xoshiro128** reference vector.
/// Run on every platform: `dart test -p vm,chrome` + `-c dart2wasm`.
void main() {
  List<int> take(Prng rng, int n) => [
    for (var i = 0; i < n; i++) rng.nextUint32(),
  ];

  test('xoshiro128** matches the reference from state {1, 2, 3, 4}', () {
    expect(take(Prng.fromState(1, 2, 3, 4), 6), [
      11520,
      0,
      5927040,
      70819200,
      2031721883,
      1637235492,
    ]);
  });

  test('SplitMix seeding from (version, Level Number, attempt) is pinned', () {
    expect(take(Prng.seed([1, 7, 0]), 6), [
      1542864358,
      3084404761,
      3576871518,
      1730314840,
      2759956115,
      1827360049,
    ]);
    expect(take(Prng.seed([1, 7, 1]), 3), [1088253059, 3832624955, 202958874]);
  });

  test('seed words up to 2^32 − 1 stay exact', () {
    expect(take(Prng.seed([0xFFFFFFFF, 123456789, 4000000000]), 3), [
      1367572021,
      3317448383,
      3744976322,
    ]);
  });

  test('nextInt (Lemire) is pinned and in range', () {
    final rng = Prng.seed([42]);
    expect(
      [
        for (final n in [1, 2, 3, 10, 100, 48, 1000000, 2097152])
          rng.nextInt(n),
      ],
      [0, 1, 2, 5, 39, 4, 358023, 1693840],
    );
    final r2 = Prng.seed([9]);
    for (var i = 0; i < 1000; i++) {
      expect(r2.nextInt(7), inInclusiveRange(0, 6));
    }
  });

  test('nextInt rejects bounds outside 1..2^21', () {
    expect(() => Prng.seed([1]).nextInt(0), throwsArgumentError);
    expect(() => Prng.seed([1]).nextInt((1 << 21) + 1), throwsArgumentError);
  });

  test('shuffle is Fisher–Yates over nextInt, pinned', () {
    final list = List.generate(10, (i) => i);
    Prng.seed([42]).shuffle(list);
    expect(list, [7, 4, 9, 1, 0, 2, 3, 8, 6, 5]);
  });

  test('outputs are unsigned 32-bit', () {
    final rng = Prng.seed([3, 5]);
    for (var i = 0; i < 2000; i++) {
      expect(rng.nextUint32(), inInclusiveRange(0, 0xFFFFFFFF));
    }
  });
}
