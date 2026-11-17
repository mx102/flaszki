import 'dart:async';

import 'package:flaszki/src/play/level_sequencer.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int> requested;
  late Map<int, Completer<GeneratedLevel>> pending;

  Future<GeneratedLevel> fakeGen(int n) {
    requested.add(n);
    return (pending[n] = Completer()).future;
  }

  setUp(() {
    requested = [];
    pending = {};
  });

  test('start loads Level N, then pre-generates N+1', () async {
    final s = LevelSequencer(fakeGen, startLevel: 3);
    final f = s.start();
    expect(requested, [3]);
    pending[3]!.complete(generate(3));
    final g = await f;
    expect(g.levelNumber, 3);
    expect(s.levelNumber, 3);
    expect(requested, [3, 4]);
    expect(s.nextReady, isFalse);
    pending[4]!.complete(generate(4));
    await Future<void>.delayed(Duration.zero);
    expect(s.nextReady, isTrue);
  });

  test(
    'advance uses the pre-generated Level and pre-generates the next',
    () async {
      final s = LevelSequencer(fakeGen);
      final f = s.start();
      pending[1]!.complete(generate(1));
      await f;
      pending[2]!.complete(generate(2));
      final g = await s.advance();
      expect(g.levelNumber, 2);
      expect(s.levelNumber, 2);
      expect(requested, [1, 2, 3]);
    },
  );

  test(
    'advance before N+1 is ready waits for it (no second request)',
    () async {
      final s = LevelSequencer(fakeGen);
      final f = s.start();
      pending[1]!.complete(generate(1));
      await f;
      final a = s.advance();
      pending[2]!.complete(generate(2));
      expect((await a).levelNumber, 2);
      expect(requested, [1, 2, 3]);
    },
  );

  test('default generator produces real Levels', () async {
    final s = LevelSequencer(generateLevelOffThread);
    final g = await s.start();
    expect(g.levelNumber, 1);
    expect((await s.advance()).levelNumber, 2);
  });
}
