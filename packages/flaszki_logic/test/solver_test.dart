import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

BoardState board(List<List<int>> flasks, List<int> queue) =>
    BoardState.initial(Level(flasks: flasks.map(Flask.new), goalQueue: queue));

/// Reference: exhaustive search over every legal Pour with no pruning or
/// symmetry, keyed by the exact ordered board.
bool bruteForceSolvable(BoardState start) {
  String key(BoardState s) =>
      '${[for (var i = 0; i < s.flasks.length; i++) s.isOnBoard(i) ? s.flasks[i].layers : 'x']}'
      '${s.goalQueue.length}';
  final seen = <String>{key(start)};
  final stack = [start];
  while (stack.isNotEmpty) {
    final s = stack.removeLast();
    if (s.isSolved) return true;
    for (var f = 0; f < s.flasks.length; f++) {
      for (var t = 0; t < s.flasks.length; t++) {
        if (!s.canPour(f, t)) continue;
        final next = s.pour(f, t).state;
        if (seen.add(key(next))) stack.add(next);
      }
    }
  }
  return false;
}

/// Random full deal (all Layers shuffled into full Flasks) + empties, plus
/// a random queue; then [pours] random legal Pours to reach mid-game states.
BoardState randomState(
  Prng rng,
  int colors,
  int perColor,
  int empties,
  int pours,
) {
  final layers = [
    for (var c = 0; c < colors; c++)
      for (var k = 0; k < perColor * flaskCapacity; k++) c,
  ];
  rng.shuffle(layers);
  final queue = [
    for (var c = 0; c < colors; c++)
      for (var k = 0; k < perColor; k++) c,
  ];
  rng.shuffle(queue);
  final flasks = [
    for (var i = 0; i < colors * perColor; i++)
      layers.sublist(i * flaskCapacity, (i + 1) * flaskCapacity),
    for (var i = 0; i < empties; i++) <int>[],
  ];
  var s = board(flasks, queue);
  for (var p = 0; p < pours; p++) {
    final legal = [
      for (var f = 0; f < s.flasks.length; f++)
        for (var t = 0; t < s.flasks.length; t++)
          if (s.canPour(f, t)) (f, t),
    ];
    if (legal.isEmpty || s.isSolved) break;
    final (f, t) = legal[rng.nextInt(legal.length)];
    s = s.pour(f, t).state;
  }
  return s;
}

void main() {
  test('a board with no legal Pour and a non-empty queue is unsolvable', () {
    final s = board(
      [
        [0, 0, 0, 1],
        [1, 1, 1, 0],
      ],
      [0, 1],
    );
    for (final key in VisitedKey.values) {
      expect(solve(s, visited: key).result, Solvability.unsolvable);
    }
  });

  test('a solvable board returns a solution that replays to Solved', () {
    final s = board(
      [
        [0, 1, 0, 1],
        [1, 0, 1, 0],
        [],
        [],
      ],
      [1, 0],
    );
    final r = solve(s);
    expect(r.result, Solvability.solvable);
    var state = s;
    for (final p in r.solution!) {
      state = state.pour(p.from, p.to).state;
    }
    expect(state.isSolved, isTrue);
    expect(r.solutionLength, r.solution!.length);
    expect(r.nodes, greaterThan(0));
  });

  test('B − C counts same-Color runs on board minus remaining queue', () {
    // Blocks: 4 + 4 + 0 + 0 = 8; queue of 2 → 6.
    final s = board(
      [
        [0, 1, 0, 1],
        [1, 0, 1, 0],
        [],
        [],
      ],
      [0, 1],
    );
    expect(solve(s).mergeLowerBound, 6);
    // Blocks: [0,0] 1, [1,1,1,1] 1, [0,0] 1, [] 0 = 3; queue 2 → 1.
    expect(
      solve(
        board(
          [
            [0, 0],
            [1, 1, 1, 1],
            [0, 0],
            [],
          ],
          [0, 1],
        ),
      ).mergeLowerBound,
      1,
    );
  });

  test(
    'queue order matters: Completed Flask of a later Color blocks space',
    () {
      // Color-sortable, but 1 must seal first and needs both empties' worth
      // of room while the waiting Completed 0 Flask occupies a slot.
      final s = board(
        [
          [0, 0, 0, 0],
          [1, 2, 1, 2],
          [2, 1, 2, 1],
          [],
        ],
        [1, 2, 0],
      );
      expect(
        solve(s, visited: VisitedKey.exact).result,
        bruteForceSolvable(s) ? Solvability.solvable : Solvability.unsolvable,
      );
    },
  );

  test('hitting the node cap returns unknown', () {
    final s = randomState(Prng.seed([5]), 6, 1, 2, 0);
    final r = solve(s, nodeCap: 1);
    expect(r.result, isNot(Solvability.unsolvable));
    final big = randomState(Prng.seed([11]), 12, 1, 1, 0);
    final capped = solve(big, nodeCap: 20);
    expect(capped.result, Solvability.unknown);
    expect(capped.nodes, 20);
  });

  test('mid-game state with sealed Flasks is solved from where it is', () {
    var s = board(
      [
        [0, 0, 0, 1],
        [1, 1, 1, 0],
        [],
      ],
      [0, 1],
    );
    s = s.pour(0, 2).state; // 1 → empty
    s = s.pour(1, 0).state; // 0 onto 0s: completes 0, sealed
    expect(s.sealed, {0});
    final r = solve(s, visited: VisitedKey.exact);
    expect(r.result, Solvability.solvable);
  });

  group('agrees with brute force on small boards', () {
    const configs = [
      (2, 1, 1),
      (3, 1, 1),
      (3, 1, 2),
      (2, 2, 1),
      (4, 1, 1),
      (2, 2, 2),
    ];
    for (final (colors, perColor, empties) in configs) {
      test('$colors Colors × $perColor, $empties empty', () {
        final rng = Prng.seed([colors, perColor, empties]);
        var solvable = 0, unsolvable = 0;
        for (var i = 0; i < 40; i++) {
          final s = randomState(
            rng,
            colors,
            perColor,
            empties,
            rng.nextInt(12),
          );
          final expected = bruteForceSolvable(s);
          final exact = solve(s, visited: VisitedKey.exact, nodeCap: 1 << 30);
          // Exact mode: never unsolvable for a solvable state, and agrees.
          expect(
            exact.result,
            expected ? Solvability.solvable : Solvability.unsolvable,
            reason: '${s.flasks} ${s.sealed} ${s.goalQueue}',
          );
          final hashed = solve(s, nodeCap: 1 << 30);
          expect(hashed.result, exact.result);
          expected ? solvable++ : unsolvable++;
        }
        // Configs with 1 empty Flask must exercise both outcomes overall.
        if (empties == 1 && colors >= 3) expect(unsolvable, greaterThan(0));
        expect(solvable, greaterThan(0));
      });
    }
  });
}
