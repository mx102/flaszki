/// Auto-grid board layout (PRD §4.1, ADR 0006). Plain Dart, no Flutter.
///
/// All sizes are in Layer heights (`L`), as in the board-layout prototype.
library;

import 'dart:math' as math;

import 'package:flaszki_logic/flaszki_logic.dart' show flaskCapacity;

/// Glass width ≈ 2.2 × Layer height.
const double glassWidthRatio = 2.2;

/// Neck above the top Layer (glass height = L × (capacity + neck)).
const double neckRatio = 0.7;

/// Room above the glass for the selected Flask to lift.
const double liftRatio = 0.9;

/// Horizontal / vertical gap per cell.
const double gapXRatio = 0.5, gapYRatio = 0.5;

/// Largest Layer height; few Flasks on a big screen don't grow without end.
const double maxLayerHeight = 36;

/// Grid for one Level; Flask size stays fixed for the whole Level.
class BoardMetrics {
  const BoardMetrics({
    required this.columns,
    required this.rows,
    required this.layerHeight,
  });

  final int columns;
  final int rows;
  final double layerHeight;

  /// Tap target = whole cell.
  double get cellWidth => layerHeight * (glassWidthRatio + gapXRatio);
  double get cellHeight =>
      layerHeight * (flaskCapacity + neckRatio + liftRatio + gapYRatio);

  double get glassWidth => layerHeight * glassWidthRatio;
  double get glassHeight => layerHeight * (flaskCapacity + neckRatio);

  /// Lift of the selected Flask.
  double get lift => layerHeight * liftRatio * 0.8;

  @override
  String toString() => 'BoardMetrics(${columns}x$rows, L=$layerHeight)';
}

/// Cell rectangle relative to the board area's top-left.
class CellRect {
  const CellRect(this.left, this.top, this.width, this.height);

  final double left, top, width, height;

  @override
  String toString() => 'CellRect($left, $top, $width × $height)';
}

double _layerFor(int c, int r, double w, double h) => math.min(
  w / (c * (glassWidthRatio + gapXRatio)),
  h / (r * (flaskCapacity + neckRatio + liftRatio + gapYRatio)),
);

/// Picks the column count giving the largest Layer height for [flaskCount]
/// Flasks in a [width] × [height] area; ties → fewer rows.
BoardMetrics fitBoard(int flaskCount, double width, double height) {
  final n = math.max(1, flaskCount);
  BoardMetrics? best;
  for (var c = 1; c <= n; c++) {
    final r = (n + c - 1) ~/ c;
    final l = math.min(_layerFor(c, r, width, height), maxLayerHeight);
    if (best == null ||
        l > best.layerHeight + 1e-9 ||
        ((l - best.layerHeight).abs() <= 1e-9 && r < best.rows)) {
      best = BoardMetrics(columns: c, rows: r, layerHeight: l);
    }
  }
  return best!;
}

/// Cells for [count] on-board Flasks with fixed [m] size: rows fill top to
/// bottom, short last row centred, grid centred in the area. With fewer
/// Flasks than the Level started with, the grid tightens (fewer rows).
List<CellRect> placeCells(
  BoardMetrics m,
  int count,
  double width,
  double height,
) {
  if (count <= 0) return const [];
  final cols = math.min(m.columns, count);
  final rows = (count + cols - 1) ~/ cols;
  final cw = m.cellWidth, ch = m.cellHeight;
  final top0 = (height - rows * ch) / 2;
  return [
    for (var i = 0; i < count; i++)
      () {
        final row = i ~/ cols;
        final inRow = row < rows - 1 ? cols : count - row * cols;
        final left0 = (width - inRow * cw) / 2;
        return CellRect(left0 + (i - row * cols) * cw, top0 + row * ch, cw, ch);
      }(),
  ];
}
