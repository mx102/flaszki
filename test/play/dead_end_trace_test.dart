import 'dart:async';

import 'package:flaszki/src/play/dead_end_checker.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter_test/flutter_test.dart';

/// Oracle: the exact-mode solver with a generous cap finds a solution, and
/// that solution really reaches Solved when replayed.
bool provablySolvable(BoardState s) {
  final r = solve(s, visited: VisitedKey.exact, nodeCap: 1 << 22);
  if (r.result != Solvability.solvable) return false;
  var t = s;
  for (final p in r.solution!) {
    expect(t.canPour(p.from, p.to), isTrue);
    t = t.pour(p.from, p.to).state;
  }
  return t.isSolved;
}

List<(int, int)> legalPours(BoardState s) => [
  for (var f = 0; f < s.flasks.length; f++)
    for (var t = 0; t < s.flasks.length; t++)
      if (s.canPour(f, t)) (f, t),
];

void main() {
  test('over random play traces the banner is never shown on a solvable '
      'state (stale results arrive late and out of order)', () async {
    final rng = Prng.seed([25]);
    final pending = <(BoardState, Completer<bool>)>[];
    final checker = DeadEndChecker(
      run: (s) {
        final c = Completer<bool>();
        pending.add((s, c));
        return c.future;
      },
      wait: (_) => Future.value(),
    );

    var shownSteps = 0;
    var steps = 0;
    for (var trace = 0; trace < 40; trace++) {
      final game = Game(generate(1 + rng.nextInt(30)).level);
      checker.stateChanged(game.state);
      for (var step = 0; step < 60; step++) {
        // Player action.
        final roll = rng.nextInt(20);
        final pours = legalPours(game.state);
        if (roll == 0) {
          game.restart();
          checker.stateChanged(game.state);
        } else if (roll < 3 && game.canUndo) {
          game.undo();
          checker.stateChanged(game.state);
        } else if (roll == 3) {
          checker.input();
        } else if (pours.isNotEmpty && !game.state.isSolved) {
          final (f, t) = pours[rng.nextInt(pours.length)];
          game.pour(f, t);
          checker.stateChanged(game.state, afterPour: true);
        }
        // Some checks finish, in random order, possibly long after.
        await Future<void>.delayed(Duration.zero);
        for (var k = rng.nextInt(pending.length + 1); k > 0; k--) {
          final (s, c) = pending.removeAt(rng.nextInt(pending.length));
          c.complete(isDeadEnd(s));
        }
        await Future<void>.delayed(Duration.zero);

        steps++;
        if (checker.showing) {
          shownSteps++;
          expect(
            provablySolvable(game.state),
            isFalse,
            reason: 'banner on a solvable state (trace $trace, step $step)',
          );
        }
      }
    }
    // Not vacuous: random play does reach and flag Dead Ends.
    expect(shownSteps, greaterThan(steps ~/ 20));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
