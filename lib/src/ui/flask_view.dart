import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/widgets.dart';

import '../play/board_layout.dart';
import '../play/goal_queue_view.dart';
import 'placeholder_style.dart';

/// Placeholder glass for Flask [index]: outlined box, one block per Layer;
/// a waiting Completed Flask gets a cork in its neck + a `#N` badge.
/// Style A (#26) replaces the drawing; keys are relied on by tests.
class FlaskView extends StatelessWidget {
  const FlaskView({
    super.key,
    required this.index,
    required this.flask,
    required this.metrics,
    this.waitingPosition,
  });

  final int index;
  final Flask flask;
  final BoardMetrics metrics;

  /// Goal Queue position (1-based) if this is a waiting Completed Flask.
  final int? waitingPosition;

  @override
  Widget build(BuildContext context) {
    final l = metrics.layerHeight;
    final w = metrics.glassWidth;
    final pos = waitingPosition;
    return SizedBox(
      key: ValueKey('glass-$index'),
      width: w,
      height: metrics.glassHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: PlaceholderStyle.glass, width: 1.5),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(l * 0.2),
                  bottom: Radius.circular(w / 2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(w / 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var j = flask.layers.length - 1; j >= 0; j--)
                      SizedBox(
                        key: ValueKey('layer-$index-$j'),
                        width: w,
                        height: l,
                        child: ColoredBox(
                          color: PlaceholderStyle.color(flask.layers[j]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (pos != null) ...[
            Positioned(
              key: ValueKey('cork-$index'),
              left: w * 0.2,
              right: w * 0.2,
              top: -l * 0.15,
              height: l * 0.6,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: PlaceholderStyle.cork,
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
            ),
            Positioned(
              key: ValueKey('badge-$index'),
              right: -l * 0.5,
              top: -l * 0.5,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: l * 0.15),
                decoration: BoxDecoration(
                  color: const Color(0xDD000000),
                  borderRadius: BorderRadius.circular(l),
                ),
                child: Text(
                  badgeLabel(pos),
                  style: TextStyle(
                    fontSize: l * 0.6 < 10 ? 10 : l * 0.6,
                    color: PlaceholderStyle.text,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
