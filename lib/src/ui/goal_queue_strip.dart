import 'package:flutter/widgets.dart';

import '../l10n.dart';
import '../play/goal_queue_view.dart';
import 'color_fill.dart';
import 'style/orb_painter.dart';
import 'style/style_a.dart';

/// Height of the Goal Queue strip (PRD §4.1).
const double goalQueueStripHeight = 64;

/// Goal Queue strip (PRD §4.3, §5): big NEXT glass orb with a small-caps
/// serif "NEXT" under it, 3 small orbs, `+N`.
class GoalQueueStrip extends StatelessWidget {
  const GoalQueueStrip({super.key, required this.queue});

  final GoalQueueView queue;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: goalQueueStripHeight,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Orb(key: const ValueKey('orb-next'), color: queue.head, size: 42),
            const SizedBox(height: 1),
            Text(context.l10n.goalQueueNext, style: StyleA.smallCaps),
          ],
        ),
        const SizedBox(width: 14),
        for (final (i, c) in queue.next.indexed) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _Orb(key: ValueKey('orb-$i'), color: c, size: 26),
          ),
          const SizedBox(width: 12),
        ],
        if (queue.more > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              '+${queue.more}',
              style: const TextStyle(
                fontFamily: StyleA.serif,
                fontSize: 15,
                color: Color(0x99FFFFFF),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Orb extends StatelessWidget {
  const _Orb({super.key, required this.color, required this.size});

  final int? color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: OrbPainter(
        color,
        next: size > 30,
        patterned: ColorblindPatterns.of(context),
      ),
    ),
  );
}
