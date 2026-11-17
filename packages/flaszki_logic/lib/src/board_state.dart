import 'level.dart';

/// Result of applying a legal Pour.
class PourOutcome {
  const PourOutcome(this.state, this.layersMoved, this.sealed);

  final BoardState state;
  final int layersMoved;

  /// Flask indices sealed by this Pour, in seal order (cascade included).
  final List<int> sealed;
}

/// Board at one moment. Flask indices are positions in the Level's initial
/// Flask list and stay stable; sealed Flasks are off the board.
class BoardState {
  BoardState._(this.flasks, this.goalQueue, this.sealed);

  factory BoardState.initial(Level level) =>
      BoardState._(level.flasks, level.goalQueue, const {});

  /// All Flasks by stable index (sealed ones keep their last content).
  final List<Flask> flasks;

  /// Remaining Goal Queue, head first.
  final List<int> goalQueue;

  /// Indices of sealed (removed) Flasks.
  final Set<int> sealed;

  /// Whether Flask [index] is on the board (in range and not sealed).
  bool isOnBoard(int index) =>
      index >= 0 && index < flasks.length && !sealed.contains(index);

  /// Pour legality (PRD §2): distinct on-board Flasks, non-empty source,
  /// target empty or same top Color with free space.
  bool canPour(int from, int to) {
    if (from == to || !isOnBoard(from) || !isOnBoard(to)) return false;
    final src = flasks[from];
    final dst = flasks[to];
    if (src.isEmpty) return false;
    return dst.isEmpty || (dst.topColor == src.topColor && !dst.isFull);
  }

  /// Applies a legal Pour; throws [StateError] if illegal.
  PourOutcome pour(int from, int to) {
    if (!canPour(from, to)) throw StateError('Illegal Pour $from → $to');
    final src = flasks[from];
    final dst = flasks[to];
    final n = src.topRun < dst.freeSpace ? src.topRun : dst.freeSpace;
    final color = src.topColor!;
    final next = List.of(flasks);
    next[from] = Flask(src.layers.sublist(0, src.layers.length - n));
    next[to] = Flask([...dst.layers, for (var i = 0; i < n; i++) color]);

    // Seal + cascade: while a Completed Flask of the head Color is on board,
    // seal it (lowest index first) and advance the queue.
    final queue = List.of(goalQueue);
    final nowSealed = {...sealed};
    final sealedNow = <int>[];
    while (queue.isNotEmpty) {
      final head = queue.first;
      var hit = -1;
      for (var i = 0; i < next.length; i++) {
        if (!nowSealed.contains(i) &&
            next[i].isCompleted &&
            next[i].topColor == head) {
          hit = i;
          break;
        }
      }
      if (hit < 0) break;
      nowSealed.add(hit);
      sealedNow.add(hit);
      queue.removeAt(0);
    }

    return PourOutcome(
      BoardState._(
        List.unmodifiable(next),
        List.unmodifiable(queue),
        Set.unmodifiable(nowSealed),
      ),
      n,
      List.unmodifiable(sealedNow),
    );
  }

  /// Solved: Goal Queue empty.
  bool get isSolved => goalQueue.isEmpty;
}
