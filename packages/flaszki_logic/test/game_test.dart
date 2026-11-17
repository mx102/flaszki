import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

Level level(List<List<int>> flasks, List<int> queue) =>
    Level(flasks: flasks.map(Flask.new).toList(), goalQueue: queue);

/// Solved by 0→1 (seals Color 0) then 0→2 (seals Color 1).
final sample = level(
  [
    [1, 0, 0, 0], // 0
    [0], // 1
    [1, 1, 1], // 2
    [], // 3
  ],
  [0, 1],
);

void main() {
  test('new Game starts at the Level initial state with empty log', () {
    final g = Game(sample);
    expect(g.pours, isEmpty);
    expect(g.state.flasks, sample.flasks);
    expect(g.state.goalQueue, [0, 1]);
    expect(g.canUndo, isFalse);
  });

  test('pour appends to log; illegal pour is rejected and not logged', () {
    final g = Game(sample);
    expect(g.pour(1, 2), isNull);
    expect(g.pours, isEmpty);
    final r = g.pour(0, 1);
    expect(r!.sealed, [1]);
    expect(g.pours, [const Pour(0, 1)]);
    expect(g.state.goalQueue, [1]);
  });

  test('Undo across a seal returns the Flask and steps the queue back', () {
    final g = Game(sample)..pour(0, 1);
    expect(g.state.isOnBoard(1), isFalse);
    g.undo();
    expect(g.pours, isEmpty);
    expect(g.state.isOnBoard(1), isTrue);
    expect(g.state.flasks[0].layers, [1, 0, 0, 0]);
    expect(g.state.flasks[1].layers, [0]);
    expect(g.state.goalQueue, [0, 1]);
  });

  test('Undo with empty log is a no-op', () {
    final g = Game(sample)..undo();
    expect(g.state.goalQueue, [0, 1]);
  });

  test('play to Solved, then Restart clears log and board', () {
    final g = Game(sample)
      ..pour(0, 1) // seals 1 (Color 0)
      ..pour(0, 2); // completes Color 1 → seals 2
    expect(g.state.isSolved, isTrue);
    expect(g.pours, [const Pour(0, 1), const Pour(0, 2)]);
    g.restart();
    expect(g.pours, isEmpty);
    expect(g.canUndo, isFalse);
    expect(g.state.isSolved, isFalse);
    expect(g.state.flasks, sample.flasks);
  });
}
