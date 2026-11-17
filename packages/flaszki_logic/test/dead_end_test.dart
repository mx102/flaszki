import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

BoardState board(List<List<int>> flasks, List<int> queue) =>
    BoardState.initial(Level(flasks: flasks.map(Flask.new), goalQueue: queue));

void main() {
  test('no legal Pour with a non-empty queue is a Dead End', () {
    final s = board(
      [
        [0, 0, 0, 1],
        [1, 1, 1, 0],
      ],
      [0, 1],
    );
    expect(isDeadEnd(s), isTrue);
  });

  test('a freshly generated Level is not a Dead End', () {
    for (final n in [1, 10, 40]) {
      expect(isDeadEnd(BoardState.initial(generate(n).level)), isFalse);
    }
  });

  test('node cap hit (unknown) is not a Dead End', () {
    final s = BoardState.initial(generate(60).level);
    expect(isDeadEnd(s, nodeCap: 1), isFalse);
  });

  test('a Solved state is not a Dead End', () {
    final s = board(
      [
        [0, 0, 0],
        [0],
      ],
      [0],
    ).pour(1, 0).state;
    expect(s.isSolved, isTrue);
    expect(isDeadEnd(s), isFalse);
  });
}
