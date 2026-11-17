import 'package:flaszki/src/play/goal_queue_view.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalQueueView', () {
    test('head, next 3, +N for the rest', () {
      final v = GoalQueueView.of([5, 1, 2, 3, 4, 6]);
      expect(v.head, 5);
      expect(v.next, [1, 2, 3]);
      expect(v.more, 2);
    });

    test('short queue', () {
      final v = GoalQueueView.of([7, 8]);
      expect(v.head, 7);
      expect(v.next, [8]);
      expect(v.more, 0);
    });

    test('empty queue', () {
      final v = GoalQueueView.of([]);
      expect(v.head, isNull);
      expect(v.next, isEmpty);
    });
  });

  group('waitingPositions', () {
    test('waiting Completed Flasks get their 1-based queue position; '
        'repeated Colors take successive entries', () {
      final s = BoardState.initial(
        Level(
          flasks: [
            Flask([2, 2, 2, 2]),
            Flask([0, 1]),
            Flask([2, 2, 2, 2]),
            Flask([3, 3, 3, 3]),
            Flask([]),
          ],
          goalQueue: [0, 2, 1, 1, 1, 2, 3],
        ),
      );
      expect(waitingPositions(s), {0: 2, 2: 6, 3: 7});
    });

    test('sealed Flasks are not listed', () {
      final l = Level(
        flasks: [
          Flask([0, 0, 0]),
          Flask([0]),
          Flask([1, 1, 1, 1]),
        ],
        goalQueue: [0, 1],
      );
      final s = BoardState.initial(l).pour(1, 0).state; // seals 0, cascade 2
      expect(s.sealed, {0, 2});
      expect(waitingPositions(s), isEmpty);
    });
  });

  test('badgeLabel: #2..#4, … beyond', () {
    expect(badgeLabel(2), '#2');
    expect(badgeLabel(4), '#4');
    expect(badgeLabel(5), '…');
  });
}
