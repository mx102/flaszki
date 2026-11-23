import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

import 'golden_levels.dart';

void main() {
  test('golden table is for the current generatorVersion', () {
    expect(generatorVersion, goldenGeneratorVersion);
    expect(goldenHashes, hasLength(100));
  });

  test('Level 1 is pinned literally', () {
    expect(generate(1).level.toJson(), {
      'flasks': [
        [0, 2, 0, 2],
        [2, 1, 0, 1],
        [2, 1, 1, 0],
        <int>[],
        <int>[],
      ],
      'goalQueue': [0, 2, 1],
    });
  });

  test('Levels 1–100 match golden fingerprints', () {
    final got = [for (var n = 1; n <= 100; n++) levelHash(generate(n).level)];
    expect(got, goldenHashes);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
