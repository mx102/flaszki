import 'package:flaszki/src/play/play_controller.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter_test/flutter_test.dart';

/// 0:[a a a b] 1:[b b b a] 2:[] 3:[] ; queue a, b.
Level _level() => Level(
  flasks: [
    Flask([0, 0, 0, 1]),
    Flask([1, 1, 1, 0]),
    Flask([]),
    Flask([]),
  ],
  goalQueue: [0, 1],
);

void main() {
  late PlayController c;
  setUp(() => c = PlayController(Game(_level())));

  test('tap a Flask selects it; tap it again deselects', () {
    expect(c.tapFlask(0), isA<Selected>());
    expect(c.selected, 0);
    expect(c.tapFlask(0), isA<Deselected>());
    expect(c.selected, isNull);
  });

  test('tap an empty Flask with nothing selected does nothing', () {
    // PRD §4.2 only shakes invalid Pour targets; with no selection there is
    // no Pour, so no shake / invalid sound.
    final e = c.tapFlask(2);
    expect(e, isA<Ignored>());
    expect(c.selected, isNull);
  });

  test('tap a valid target Pours and clears the selection', () {
    c.tapFlask(0);
    final e = c.tapFlask(2);
    expect(e, isA<Poured>().having((p) => p.outcome.layersMoved, 'n', 1));
    expect(c.selected, isNull);
    expect(c.game.pours, [const Pour(0, 2)]);
  });

  test('invalid target shakes and takes the selection', () {
    c.tapFlask(0); // top b
    final e = c.tapFlask(1); // full
    expect(e, isA<Rejected>().having((r) => r.target, 'target', 1));
    expect(c.selected, 1);
    expect(c.game.pours, isEmpty);
  });

  test('tap empty board deselects', () {
    c.tapFlask(0);
    expect(c.tapEmpty(), isTrue);
    expect(c.selected, isNull);
    expect(c.tapEmpty(), isFalse);
  });

  test('Back deselects; unhandled when nothing is selected', () {
    expect(c.back(), isFalse);
    c.tapFlask(0);
    expect(c.back(), isTrue);
    expect(c.selected, isNull);
  });

  test('Undo and Restart clear the selection', () {
    c.tapFlask(0);
    c.tapFlask(2);
    c.tapFlask(1);
    expect(c.undo(), isTrue);
    expect(c.selected, isNull);
    expect(c.game.pours, isEmpty);
    expect(c.undo(), isFalse);
    c.tapFlask(0);
    c.tapFlask(2);
    c.tapFlask(1);
    c.restart();
    expect(c.selected, isNull);
    expect(c.game.pours, isEmpty);
  });

  test('Pour completing the head Color reports the seal; Solved ignores '
      'further taps', () {
    // 0→2 (b), 1→3 (a), 1→0? no: 0 top a; pour 3→0 completes a.
    for (final (f, t) in [(0, 2), (1, 3), (3, 0)]) {
      c.tapFlask(f);
      c.tapFlask(t);
    }
    expect(c.game.state.sealed, {0});
    c.tapFlask(2);
    final e = c.tapFlask(1);
    expect(e, isA<Poured>().having((p) => p.outcome.sealed, 'sealed', [1]));
    expect(c.isSolved, isTrue);
    expect(c.tapFlask(2), isA<Ignored>());
    expect(c.selected, isNull);
  });

  test('Levels 1–40 play to Solved by tap-tap', () {
    for (var n = 1; n <= 40; n++) {
      final g = generate(n);
      final pc = PlayController(Game(g.level));
      for (final p in g.report.solution!) {
        expect(pc.tapFlask(p.from), isA<Selected>(), reason: 'L$n $p');
        expect(pc.tapFlask(p.to), isA<Poured>(), reason: 'L$n $p');
      }
      expect(pc.isSolved, isTrue, reason: 'L$n');
    }
  });
}
