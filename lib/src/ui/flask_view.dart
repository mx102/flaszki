import 'dart:math' as math;

import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/widgets.dart';

import '../play/board_layout.dart';
import '../play/goal_queue_view.dart';
import 'color_fill.dart';
import 'style/flask_painter.dart';
import 'style/style_a.dart';

/// Apothecary-glass Flask [index] (Style A, PRD §5) drawn by
/// [FlaskPainter]; a waiting Completed Flask gets a cork over its lip and a
/// `#N` badge. Invisible keyed boxes mark each Layer slot (`layer-i-j`)
/// for tests / hit geometry.
class FlaskView extends StatelessWidget {
  const FlaskView({
    super.key,
    required this.index,
    required this.flask,
    required this.metrics,
    this.waitingPosition,
    this.bands,
    this.tilt = 0,
    this.wobble = 0,
    this.wobblePhase = 0,
    this.corkDrop,
  });

  final int index;
  final Flask flask;
  final BoardMetrics metrics;

  /// Goal Queue position (1-based) if this is a waiting Completed Flask.
  final int? waitingPosition;

  /// Pour juice (#27): fractional bands override [flask]'s Layers; tilt
  /// (radians) and target surface wobble go to [FlaskPainter].
  final List<FluidBand>? bands;
  final double tilt, wobble, wobblePhase;

  /// Sealing: cork drop 0..1 (no badge).
  final double? corkDrop;

  @override
  Widget build(BuildContext context) {
    final size = Size(metrics.glassWidth, metrics.glassHeight);
    final g = FlaskGeometry(size);
    final tw = g.tubeWidth;
    final pos = waitingPosition;
    final drop = corkDrop;
    final cork = drop ?? (pos != null ? 1.0 : null);
    final badgeR = (g.layer * 0.45).clamp(8.0, 11.0);
    return SizedBox(
      key: ValueKey('glass-$index'),
      width: size.width,
      height: size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: FlaskPainter(
                bands ?? fluidBands(flask.layers),
                tilt: tilt,
                wobble: wobble,
                wobblePhase: wobblePhase,
                patterned: ColorblindPatterns.of(context),
              ),
            ),
          ),
          for (var j = 0; j < flask.layers.length; j++)
            Positioned(
              key: ValueKey('layer-$index-$j'),
              left: g.centerX - tw / 2,
              width: tw,
              top: g.layerTop(j.toDouble()),
              height: g.layer,
              child: const SizedBox.shrink(),
            ),
          if (cork != null)
            Positioned(
              key: ValueKey('cork-$index'),
              left: g.centerX - tw * 0.36,
              width: tw * 0.72,
              top: -tw * 0.2 - g.layer * 0.12 - (1 - cork) * g.layer * 1.6,
              height: tw * 0.45,
              child: Opacity(
                opacity: 0.9 * cork,
                child: const CustomPaint(painter: CorkPainter()),
              ),
            ),
          if (pos != null && drop == null) ...[
            Positioned(
              key: ValueKey('badge-$index'),
              left: g.centerX + tw * 0.55 - badgeR,
              top: -tw * 0.2 - g.layer * 0.12 - badgeR * 1.2,
              width: badgeR * 2,
              height: badgeR * 2,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: StyleA.badge,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badgeLabel(pos),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: StyleA.serif,
                      fontSize: math.max(9, badgeR),
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation('wght', 700)],
                      height: 1,
                      color: StyleA.badgeText,
                    ),
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
