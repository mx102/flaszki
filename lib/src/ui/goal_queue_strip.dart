import 'package:flutter/widgets.dart';

import '../play/goal_queue_view.dart';
import 'placeholder_style.dart';

/// Height of the Goal Queue strip (PRD §4.1).
const double goalQueueStripHeight = 64;

/// Goal Queue strip: NEXT orb, 3 small orbs, `+N` (PRD §4.3). Placeholder
/// circles; glass orbs + small-caps serif come with #26.
class GoalQueueStrip extends StatelessWidget {
  const GoalQueueStrip({super.key, required this.queue});

  final GoalQueueView queue;

  @override
  Widget build(BuildContext context) {
    final head = queue.head;
    return SizedBox(
      height: goalQueueStripHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: PlaceholderStyle.text,
                ),
              ),
              const SizedBox(height: 2),
              _Orb(key: const ValueKey('orb-next'), color: head, size: 40),
            ],
          ),
          const SizedBox(width: 12),
          for (final (i, c) in queue.next.indexed) ...[
            _Orb(key: ValueKey('orb-$i'), color: c, size: 22),
            const SizedBox(width: 8),
          ],
          if (queue.more > 0)
            Text(
              '+${queue.more}',
              style: const TextStyle(
                fontSize: 14,
                color: PlaceholderStyle.text,
              ),
            ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({super.key, required this.color, required this.size});

  final int? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c == null ? null : PlaceholderStyle.color(c),
        border: Border.all(color: PlaceholderStyle.glass, width: 1.5),
      ),
    );
  }
}
