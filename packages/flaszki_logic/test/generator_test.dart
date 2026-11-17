import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

/// Plays [solution] from the Level start; true iff it reaches Solved.
bool replaySolves(Level level, List<Pour> solution) {
  final game = Game(level);
  for (final p in solution) {
    if (game.pour(p.from, p.to) == null) return false;
  }
  return game.state.isSolved;
}

void main() {
  test('Level 1 is 3 Colors × 1 with 2 empty Flasks', () {
    final g = generate(1);
    final flasks = g.level.flasks;
    expect(flasks, hasLength(5));
    expect(flasks.where((f) => f.isEmpty), hasLength(2));
    expect(flasks.where((f) => f.isFull), hasLength(3));
    expect(g.level.goalQueue.toList()..sort(), [0, 1, 2]);
  });

  test('deal matches curve(N): every Color has 4 Layers per Flask', () {
    for (final n in [1, 20, 36, 43, 46]) {
      final g = generate(n);
      final p = g.params;
      expect(p.colorCount, curve(n).colorCount);
      final counts = List.filled(maxColors, 0);
      for (final f in g.level.flasks) {
        for (final c in f.layers) {
          counts[c]++;
        }
      }
      for (var c = 0; c < maxColors; c++) {
        expect(
          counts[c],
          c < p.colorCount ? p.flasksPerColor * flaskCapacity : 0,
          reason: 'Level $n Color $c',
        );
      }
      final queue = g.level.goalQueue.toList()..sort();
      expect(queue, [
        for (var c = 0; c < p.colorCount; c++)
          for (var k = 0; k < p.flasksPerColor; k++) c,
      ]);
      expect(g.level.flasks.where((f) => f.isEmpty).length, p.emptyFlasks);
    }
  });

  test('is deterministic', () {
    for (final n in [1, 43, 100]) {
      expect(generate(n).level, generate(n).level);
    }
  });

  test('no Level starts with a Completed Flask', () {
    for (var n = 1; n <= 60; n++) {
      expect(generate(n).level.flasks.any((f) => f.isCompleted), isFalse);
    }
  });

  test('metrics carry a solution that Solves the Level in queue order', () {
    for (final n in [1, 12, 41, 43]) {
      final g = generate(n);
      expect(g.report.result, Solvability.solvable);
      expect(g.report.nodes, inInclusiveRange(1, defaultNodeCap));
      expect(replaySolves(g.level, g.report.solution!), isTrue);
      expect(g.attempts, inInclusiveRange(1, maxAttempts));
    }
  });

  test('different Levels with the same params differ', () {
    expect(generate(1).level, isNot(generate(2).level));
  });

  test('fallback adds one empty Flask when every attempt fails', () {
    // A solver that rejects everything except boards with 3 empty Flasks.
    final g = generate(
      43,
      verify: (s) => solve(
        s,
        nodeCap: s.flasks.where((f) => f.isEmpty).length == 3 ? 50000 : 0,
      ),
    );
    expect(g.usedFallback, isTrue);
    expect(g.params.emptyFlasks, 3);
    expect(g.level.flasks, hasLength(17)); // 7×2 + 3 empty
    expect(replaySolves(g.level, g.report.solution!), isTrue);
  });

  test('throws when the fallback also fails (never for real Levels)', () {
    expect(
      () => generate(1, verify: (s) => solve(s, nodeCap: 0)),
      throwsStateError,
    );
  });
}
