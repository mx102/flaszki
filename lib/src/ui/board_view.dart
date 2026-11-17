import 'dart:math' as math;

import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/widgets.dart';

import '../play/board_layout.dart';
import '../play/goal_queue_view.dart';
import 'anim/juice.dart';
import 'anim/pour_fx_painter.dart';
import 'flask_view.dart';
import 'shake.dart';
import 'style/backdrop_painter.dart';
import 'style/flask_painter.dart' show FlaskGeometry, FluidBand;

/// Reflow / lift durations; short so input is never blocked (PRD §4.2).
const reflowDuration = Duration(milliseconds: 250);
const liftDuration = Duration(milliseconds: 120);

/// Undo across a seal: quick reverse reflow (PRD §4.3).
const reverseReflowDuration = Duration(milliseconds: 140);

/// The board: on-board Flasks in an auto grid of fixed-size cells; the whole
/// cell is the tap target; taps elsewhere call [onTapEmpty]. Seals reflow
/// the remaining Flasks into a tighter grid at the same size.
///
/// Pour / seal juice (#27) is drawn from [juice] at time [now]: the source
/// glass moves beside the target and tilts while its cell (the tap target)
/// stays put; sealed Flasks stay in the grid as ghosts (cork drop, fly to
/// the NEXT orb at [orbCenter]) until their seal ends, then the grid reflows.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.state,
    required this.metrics,
    required this.selected,
    required this.shakes,
    required this.onTapFlask,
    required this.onTapEmpty,
    this.juice,
    this.now = 0,
    this.reflow = reflowDuration,
    this.orbCenter,
  });

  final BoardState state;
  final BoardMetrics metrics;
  final int? selected;

  /// Flask index → shake counter; a change plays one shake.
  final Map<int, int> shakes;
  final ValueChanged<int> onTapFlask;
  final VoidCallback onTapEmpty;

  final Juice? juice;
  final double now;
  final Duration reflow;

  /// NEXT orb centre in this board's coordinates, if known.
  final Offset? Function()? orbCenter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final j = juice;
      final ghosts = j?.ghosts(now) ?? const <int>{};
      final shown = [
        for (var i = 0; i < state.flasks.length; i++)
          if (state.isOnBoard(i) || ghosts.contains(i)) i,
      ];
      final cells = placeCells(
        metrics,
        shown.length,
        box.maxWidth,
        box.maxHeight,
      );
      final waiting = waitingPositions(state);
      final l = metrics.layerHeight;
      final gw = metrics.glassWidth, gh = metrics.glassHeight;
      final geo = FlaskGeometry(Size(gw, gh));
      // Shelf line just under each row's glass bottoms (PRD §5).
      final shelves = {
        for (final c in cells) c.top + c.height - l * gapYRatio / 2 + l * 0.15,
      }.toList();
      Offset glassCenter(int k) => Offset(
        cells[k].left + cells[k].width / 2,
        cells[k].top + cells[k].height - l * gapYRatio / 2 - gh / 2,
      );
      final slot = {for (var k = 0; k < shown.length; k++) shown[k]: k};

      final fx = <PourFx>[];
      final views = <int, Widget>{};
      final front = <int>{};
      for (var k = 0; k < shown.length; k++) {
        final i = shown[k];
        final home = glassCenter(k);
        var offset = Offset.zero;
        var tilt = 0.0, wobble = 0.0, phase = 0.0, scale = 1.0, alpha = 1.0;
        double? cork;
        List<FluidBand>? bands;
        final p = j?.pourOf(i);
        final ts = p == null ? null : slot[p.to];
        final ss = p == null ? null : slot[p.from];
        if (p != null && ts != null && ss != null) {
          final f = p.frameAt(now);
          final target = glassCenter(ts);
          final side = target.dx >= glassCenter(ss).dx ? 1.0 : -1.0;
          if (i == p.from) {
            bands = f.source;
            tilt = side * f.tilt;
            final mouth = Offset(
              target.dx - side * gw * 0.15,
              target.dy - gh / 2 - gh * 0.2,
            );
            final park = Offset(
              mouth.dx - gh / 2 * math.sin(side * f.fullTilt),
              mouth.dy + gh / 2 * math.cos(f.fullTilt),
            );
            offset = (park - home) * f.approach;
            front.add(i);
            final c = home + offset;
            final m = Offset(
              c.dx + gh / 2 * math.sin(tilt),
              c.dy - gh / 2 * math.cos(tilt),
            );
            final level = f.target.fold(0.0, (a, b) => a + b.layers);
            final topLeft = target - Offset(gw / 2, gh / 2);
            fx.add(
              PourFx(
                mouth: m,
                surface: topLeft + Offset(gw / 2, geo.layerTop(level - 1)),
                side: side,
                color: p.color,
                stream: f.stream,
                tube: Rect.fromLTRB(
                  topLeft.dx + geo.centerX - geo.tubeWidth / 2,
                  topLeft.dy,
                  topLeft.dx + geo.centerX + geo.tubeWidth / 2,
                  topLeft.dy + geo.fluidBottom,
                ),
                layer: l,
                pourStart: p.timing.move,
                pourLength: p.timing.pour,
                t: now - p.start,
                seed: p.start.hashCode ^ p.from,
              ),
            );
          } else {
            bands = f.target;
            wobble = f.wobble;
            phase = f.wobblePhase;
          }
        }
        final s = j?.sealOf(i);
        if (s != null && ghosts.contains(i)) {
          final f = s.frameAt(now);
          cork = f.cork;
          if (f.fly > 0) {
            final orb = orbCenter?.call() ?? Offset(box.maxWidth / 2, -l * 2);
            offset =
                (orb - home) * f.fly +
                Offset(0, -math.sin(f.fly * math.pi) * l * 1.6);
            scale = f.scale;
            alpha = f.opacity;
            front.add(i);
          }
        }
        Widget glass = FlaskView(
          index: i,
          flask: state.flasks[i],
          metrics: metrics,
          waitingPosition: ghosts.contains(i) ? null : waiting[i],
          bands: bands,
          tilt: tilt,
          wobble: wobble,
          wobblePhase: phase,
          corkDrop: cork,
        );
        if (offset != Offset.zero || scale != 1 || alpha != 1) {
          glass = Transform.translate(
            offset: offset,
            child: Transform.scale(
              scale: scale,
              child: Opacity(opacity: alpha, child: glass),
            ),
          );
        }
        views[i] = glass;
      }

      Widget cell(int k) {
        final i = shown[k];
        final ghost = ghosts.contains(i);
        return AnimatedPositioned(
          key: ValueKey(i),
          duration: reflow,
          curve: Curves.easeOut,
          left: cells[k].left,
          top: cells[k].top,
          width: cells[k].width,
          height: cells[k].height,
          child: IgnorePointer(
            ignoring: ghost,
            child: GestureDetector(
              key: ValueKey('flask-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onTapFlask(i),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: l * gapYRatio / 2),
                  child: AnimatedSlide(
                    duration: liftDuration,
                    curve: Curves.easeOut,
                    offset: Offset(
                      0,
                      selected == i ? -metrics.lift / metrics.glassHeight : 0,
                    ),
                    child: Shake(
                      trigger: shakes[i] ?? 0,
                      amplitude: l * 0.3,
                      child: views[i]!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapEmpty,
              child: CustomPaint(painter: ShelfPainter(shelves)),
            ),
          ),
          // Moving glasses (pouring sources, flying seals) draw on top.
          for (var k = 0; k < shown.length; k++)
            if (!front.contains(shown[k])) cell(k),
          for (var k = 0; k < shown.length; k++)
            if (front.contains(shown[k])) cell(k),
          if (fx.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: PourFxPainter(fx)),
              ),
            ),
        ],
      );
    },
  );
}
