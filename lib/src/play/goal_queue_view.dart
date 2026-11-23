import 'package:flaszki_logic/flaszki_logic.dart';

/// Goal Queue entries shown as orbs: the NEXT orb plus 3 small ones
/// (PRD §4.3). Badges `#2`..`#visibleQueueEntries` match them.
const int visibleQueueEntries = 4;

/// Goal Queue strip content (PRD §4.3): NEXT orb, next 3 small orbs, `+N`.
class GoalQueueView {
  const GoalQueueView(this.head, this.next, this.more);

  factory GoalQueueView.of(List<int> queue) => GoalQueueView(
    queue.isEmpty ? null : queue.first,
    queue.skip(1).take(visibleQueueEntries - 1).toList(growable: false),
    queue.length > visibleQueueEntries ? queue.length - visibleQueueEntries : 0,
  );

  final int? head;
  final List<int> next;
  final int more;
}

/// Waiting Completed Flasks → 1-based Goal Queue position of the entry each
/// one will fill. Flasks of a repeated Color take successive entries in
/// index order (the order [BoardState.pour] seals them).
Map<int, int> waitingPositions(BoardState s) {
  final used = <int>{};
  final out = <int, int>{};
  for (var i = 0; i < s.flasks.length; i++) {
    final f = s.flasks[i];
    if (!s.isOnBoard(i) || !f.isCompleted) continue;
    for (var q = 0; q < s.goalQueue.length; q++) {
      if (s.goalQueue[q] == f.topColor && used.add(q)) {
        out[i] = q + 1;
        break;
      }
    }
  }
  return out;
}

/// Badge text for a waiting Flask's queue position: `#2`..`#4`, else `…`.
String badgeLabel(int position) =>
    position <= visibleQueueEntries ? '#$position' : '…';
