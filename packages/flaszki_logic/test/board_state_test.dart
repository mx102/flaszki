import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

/// Builds a board; each flask is bottom → top Color ids.
BoardState board(List<List<int>> flasks, List<int> queue) => BoardState.initial(
  Level(flasks: flasks.map(Flask.new).toList(), goalQueue: queue),
);

void main() {
  group('Pour legality', () {
    test('pour onto matching top with space is legal and moves the Layer', () {
      final b = board(
        [
          [0, 1],
          [2, 1],
        ],
        [0, 1, 2],
      );
      expect(b.canPour(0, 1), isTrue);
      final r = b.pour(0, 1);
      expect(r.layersMoved, 1);
      expect(r.state.flasks[0].layers, [0]);
      expect(r.state.flasks[1].layers, [2, 1, 1]);
    });

    test('illegal Pours are rejected', () {
      final b = board(
        [
          [0, 1], // 0
          [1, 2], // 1: top mismatch
          [], // 2: empty
          [2, 2, 3, 1], // 3: full
        ],
        [0, 1, 2, 3],
      );
      expect(b.canPour(0, 1), isFalse, reason: 'Color mismatch');
      expect(b.canPour(0, 3), isFalse, reason: 'target full');
      expect(b.canPour(2, 0), isFalse, reason: 'source empty');
      expect(b.canPour(0, 0), isFalse, reason: 'same Flask');
      expect(b.canPour(0, 9), isFalse, reason: 'out of range');
      expect(() => b.pour(0, 1), throwsStateError);
    });

    test('pour into empty Flask is legal', () {
      final b = board(
        [
          [0, 1],
          [],
        ],
        [0, 1],
      );
      expect(b.canPour(0, 1), isTrue);
      expect(b.pour(0, 1).state.flasks[1].layers, [1]);
    });

    test('moves all contiguous same-Color top Layers', () {
      final b = board(
        [
          [0, 1, 1, 1],
          [],
        ],
        [0, 1],
      );
      final r = b.pour(0, 1);
      expect(r.layersMoved, 3);
      expect(r.state.flasks[0].layers, [0]);
      expect(r.state.flasks[1].layers, [1, 1, 1]);
    });

    test('partial Pour moves only what fits', () {
      final b = board(
        [
          [0, 1, 1, 1],
          [2, 2, 1],
        ],
        [0, 1, 2],
      );
      final r = b.pour(0, 1);
      expect(r.layersMoved, 1);
      expect(r.state.flasks[0].layers, [0, 1, 1]);
      expect(r.state.flasks[1].layers, [2, 2, 1, 1]);
    });
  });

  group('Completed Flask', () {
    test('of head Color is sealed and removed; queue advances', () {
      final b = board(
        [
          [1, 0, 0, 0],
          [0],
          [1, 1, 1],
        ],
        [0, 1],
      );
      final r = b.pour(0, 1);
      expect(r.sealed, [1]);
      expect(r.state.isOnBoard(1), isFalse);
      expect(r.state.goalQueue, [1]);
      expect(r.state.isSolved, isFalse);
    });

    test('of non-head Color waits on board and can be poured out of', () {
      final b = board(
        [
          [1, 1, 1],
          [0, 1],
          [],
          [0, 0, 0],
        ],
        [0, 1],
      );
      final r = b.pour(1, 0);
      expect(r.sealed, isEmpty);
      expect(r.state.flasks[0].isCompleted, isTrue);
      expect(r.state.isOnBoard(0), isTrue);
      expect(r.state.goalQueue, [0, 1]);
      expect(r.state.canPour(0, 2), isTrue);
      expect(r.state.pour(0, 2).layersMoved, 4);
    });

    test('cascade: waiting Flask seals once its Color reaches head', () {
      // Flask 0 is a waiting Completed Flask of Color 1.
      final b = board(
        [
          [1, 1, 1, 1],
          [0, 0, 0],
          [0],
        ],
        [0, 1],
      );
      final r = b.pour(2, 1);
      expect(r.sealed, [1, 0]);
      expect(r.state.goalQueue, isEmpty);
      expect(r.state.isSolved, isTrue);
    });

    test('repeated Color in queue: seals one Flask per entry', () {
      final b = board(
        [
          [0, 0, 0, 0],
          [0, 0, 0],
          [0],
          [],
        ],
        [0, 0],
      );
      // Flask 0 is a Completed Flask of head Color but no Pour yet.
      final r = b.pour(2, 1);
      expect(r.sealed, [0, 1]);
      expect(r.state.isSolved, isTrue);
    });
  });
}
