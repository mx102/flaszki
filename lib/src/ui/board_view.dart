import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/widgets.dart';

import '../play/board_layout.dart';
import '../play/goal_queue_view.dart';
import 'flask_view.dart';
import 'shake.dart';

/// Reflow / lift durations; short so input is never blocked (PRD §4.2).
const reflowDuration = Duration(milliseconds: 250);
const liftDuration = Duration(milliseconds: 120);

/// The board: on-board Flasks in an auto grid of fixed-size cells; the whole
/// cell is the tap target; taps elsewhere call [onTapEmpty]. Seals reflow
/// the remaining Flasks into a tighter grid at the same size.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.state,
    required this.metrics,
    required this.selected,
    required this.shakes,
    required this.onTapFlask,
    required this.onTapEmpty,
  });

  final BoardState state;
  final BoardMetrics metrics;
  final int? selected;

  /// Flask index → shake counter; a change plays one shake.
  final Map<int, int> shakes;
  final ValueChanged<int> onTapFlask;
  final VoidCallback onTapEmpty;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final onBoard = [
        for (var i = 0; i < state.flasks.length; i++)
          if (state.isOnBoard(i)) i,
      ];
      final cells = placeCells(
        metrics,
        onBoard.length,
        box.maxWidth,
        box.maxHeight,
      );
      final waiting = waitingPositions(state);
      final l = metrics.layerHeight;
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapEmpty,
            ),
          ),
          for (var k = 0; k < onBoard.length; k++)
            AnimatedPositioned(
              key: ValueKey(onBoard[k]),
              duration: reflowDuration,
              curve: Curves.easeOut,
              left: cells[k].left,
              top: cells[k].top,
              width: cells[k].width,
              height: cells[k].height,
              child: GestureDetector(
                key: ValueKey('flask-${onBoard[k]}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onTapFlask(onBoard[k]),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: l * gapYRatio / 2),
                    child: AnimatedSlide(
                      duration: liftDuration,
                      curve: Curves.easeOut,
                      offset: Offset(
                        0,
                        selected == onBoard[k]
                            ? -metrics.lift / metrics.glassHeight
                            : 0,
                      ),
                      child: Shake(
                        trigger: shakes[onBoard[k]] ?? 0,
                        amplitude: l * 0.3,
                        child: FlaskView(
                          index: onBoard[k],
                          flask: state.flasks[onBoard[k]],
                          metrics: metrics,
                          waitingPosition: waiting[onBoard[k]],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
