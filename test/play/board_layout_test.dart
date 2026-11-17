import 'package:flaszki/src/play/board_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 320×568 screen minus Goal Queue strip (64) + bottom bar (60).
  const smallW = 320.0, smallH = 568.0 - 64 - 60;

  group('fitBoard', () {
    test('16 Flasks on 320×568: 6×3 grid, Layer ≥ 15 px (ADR 0006)', () {
      final m = fitBoard(16, smallW, smallH);
      expect((m.columns, m.rows), (6, 3));
      expect(m.layerHeight, greaterThanOrEqualTo(15));
    });

    test('17 Flasks (fallback) on 320×568: Layer ≥ 15 px', () {
      final m = fitBoard(17, smallW, smallH);
      expect(m.layerHeight, greaterThanOrEqualTo(15));
      expect(m.columns * m.rows, greaterThanOrEqualTo(17));
    });

    test('grid of cells fits the area', () {
      for (var n = 1; n <= 17; n++) {
        final m = fitBoard(n, smallW, smallH);
        expect(m.columns * m.cellWidth, lessThanOrEqualTo(smallW + 1e-6));
        expect(m.rows * m.cellHeight, lessThanOrEqualTo(smallH + 1e-6));
      }
    });

    test('few Flasks on a wide area use one row', () {
      final m = fitBoard(5, 800, 400);
      expect(m.rows, 1);
    });

    test('ties go to fewer rows', () {
      // Flasks capped at max Layer height: 1 row and 2 rows tie → 1 row.
      final m = fitBoard(4, 5000, 5000);
      expect(m.layerHeight, maxLayerHeight);
      expect(m.rows, 1);
    });
  });

  group('placeCells', () {
    test('rows fill top to bottom, short last row centred', () {
      const g = BoardMetrics(columns: 3, rows: 2, layerHeight: 10);
      final cells = placeCells(g, 5, 300, 1000);
      expect(cells, hasLength(5));
      expect(cells[0].top, cells[2].top);
      expect(cells[3].top, greaterThan(cells[0].top));
      // last row of 2 centred under 3 columns
      final rowMid = (cells[3].left + cells[4].left + g.cellWidth) / 2;
      expect(rowMid, closeTo(150, 1e-9));
    });

    test('reflow keeps Flask size and tightens the grid', () {
      final m = fitBoard(16, smallW, smallH);
      final cells = placeCells(m, 4, smallW, smallH);
      expect(cells, hasLength(4));
      for (final c in cells) {
        expect(c.width, m.cellWidth);
        expect(c.height, m.cellHeight);
      }
      expect(cells.map((c) => c.top).toSet(), hasLength(1));
    });
  });
}
