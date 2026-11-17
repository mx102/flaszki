import 'package:flaszki/app.dart';
import 'package:flaszki/src/play/level_sequencer.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<GeneratedLevel> _sync(int n) => SynchronousFuture(generate(n));

LevelSource _fixed(Level level) =>
    (n) => SynchronousFuture(
      GeneratedLevel(
        levelNumber: n,
        level: level,
        params: curve(n),
        attempts: 1,
        usedFallback: false,
        report: const SolveReport(Solvability.unknown, 0, 0, null),
      ),
    );

Finder _flask(int i) => find.byKey(ValueKey('flask-$i'));
Finder _glass(int i) => find.byKey(ValueKey('glass-$i'));

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  LevelSource source = _sync,
  int startLevel = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    FlaszkiApp(levelSource: source, startLevel: startLevel),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapFlask(WidgetTester tester, int i) async {
  await tester.tap(_flask(i));
  await tester.pump();
}

/// Glass rows for 16 and 17 Flasks.
Level _bigLevel(int flasks) => Level(
  flasks: [
    for (var i = 0; i < flasks - 3; i++) Flask(List.filled(4, i % 12)),
    Flask([]),
    Flask([]),
    Flask([]),
  ],
  goalQueue: [for (var i = 0; i < flasks - 3; i++) i % 12],
);

void main() {
  testWidgets('opens straight into Level 1 with Goal Queue and bar', (
    tester,
  ) async {
    await _pumpApp(tester);
    final g = generate(1);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    for (var i = 0; i < g.level.flasks.length; i++) {
      expect(_flask(i), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('undo')), findsOneWidget);
    expect(find.byKey(const ValueKey('restart')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings')), findsOneWidget);
  });

  for (final n in [16, 17]) {
    testWidgets('$n Flasks fit 320×568 with Layers ≥ 15 px', (tester) async {
      await _pumpApp(
        tester,
        size: const Size(320, 568),
        source: _fixed(_bigLevel(n)),
      );
      final screen = tester.getRect(find.byType(FlaszkiApp));
      for (var i = 0; i < n; i++) {
        final cell = tester.getRect(_flask(i));
        expect(screen.contains(cell.topLeft), isTrue, reason: 'cell $i');
        expect(
          screen.contains(cell.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: 'cell $i',
        );
      }
      final layer = tester.getSize(find.byKey(const ValueKey('layer-0-0')));
      expect(layer.height, greaterThanOrEqualTo(15));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tap lifts, tap again lowers', (tester) async {
    await _pumpApp(tester);
    final y0 = tester.getRect(_glass(0)).top;
    await _tapFlask(tester, 0);
    await tester.pumpAndSettle();
    expect(tester.getRect(_glass(0)).top, lessThan(y0));
    await _tapFlask(tester, 0);
    await tester.pumpAndSettle();
    expect(tester.getRect(_glass(0)).top, y0);
  });

  testWidgets('Esc deselects', (tester) async {
    await _pumpApp(tester);
    final y0 = tester.getRect(_glass(0)).top;
    await _tapFlask(tester, 0);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.getRect(_glass(0)).top, y0);
  });

  testWidgets('Android Back deselects instead of leaving', (tester) async {
    await _pumpApp(tester);
    final y0 = tester.getRect(_glass(0)).top;
    await _tapFlask(tester, 0);
    await tester.pumpAndSettle();
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(tester.getRect(_glass(0)).top, y0);
    expect(_flask(0), findsOneWidget);
  });

  testWidgets('invalid target shakes and takes the selection', (tester) async {
    // 0:[a b] 1:[c] full-ish differing tops; 2: empty.
    final level = Level(
      flasks: [
        Flask([0, 0, 0, 1]),
        Flask([1, 1, 1, 0]),
        Flask([]),
        Flask([]),
      ],
      goalQueue: [0, 1],
    );
    await _pumpApp(tester, source: _fixed(level));
    final y1 = tester.getRect(_glass(1)).top;
    await _tapFlask(tester, 0);
    await _tapFlask(tester, 1);
    await tester.pumpAndSettle();
    expect(tester.getRect(_glass(1)).top, lessThan(y1));
  });

  testWidgets('Pour, Undo, two-tap Restart', (tester) async {
    final level = Level(
      flasks: [
        Flask([0, 0, 0, 1]),
        Flask([1, 1, 1, 0]),
        Flask([]),
        Flask([]),
      ],
      goalQueue: [0, 1],
    );
    await _pumpApp(tester, source: _fixed(level));
    Finder layers(int f) =>
        find.byWidgetPredicate((w) => '${w.key}'.contains("'layer-$f-"));
    expect(layers(2), findsNothing);
    await _tapFlask(tester, 0);
    await _tapFlask(tester, 2);
    await tester.pumpAndSettle();
    expect(layers(2), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('undo')));
    await tester.pumpAndSettle();
    expect(layers(2), findsNothing);

    await _tapFlask(tester, 0);
    await _tapFlask(tester, 2);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('restart')));
    await tester.pump();
    expect(layers(2), findsOneWidget, reason: 'first tap only arms');
    await tester.tap(find.byKey(const ValueKey('restart')));
    await tester.pumpAndSettle();
    expect(layers(2), findsNothing);

    // Arm expires after ~2 s.
    await _tapFlask(tester, 0);
    await _tapFlask(tester, 2);
    await tester.tap(find.byKey(const ValueKey('restart')));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.tap(find.byKey(const ValueKey('restart')));
    await tester.pumpAndSettle();
    expect(layers(2), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('waiting Completed Flask shows cork + #N badge', (tester) async {
    final level = Level(
      flasks: [
        Flask([1, 1, 1, 0]),
        Flask([0, 0, 0, 1]),
        Flask([]),
        Flask([2, 2, 2, 2]),
        Flask([2, 2, 2, 2]),
      ],
      goalQueue: [0, 2, 1, 2],
    );
    await _pumpApp(tester, source: _fixed(level));
    expect(find.byKey(const ValueKey('cork-3')), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#4'), findsOneWidget);
  });

  testWidgets('Seal removes the Flask; Solved → tap → Level 2; auto → 3', (
    tester,
  ) async {
    await _pumpApp(tester);
    final g = generate(1);
    for (final p in g.report.solution!) {
      await _tapFlask(tester, p.from);
      await _tapFlask(tester, p.to);
    }
    await tester.pumpAndSettle();
    expect(find.text('Solved'), findsOneWidget);
    expect(_flask(0), findsNothing);
    await tester.tapAt(const Offset(10, 300));
    await tester.pumpAndSettle();
    expect(find.text('Solved'), findsNothing);
    expect(find.text('Level 2'), findsOneWidget);

    final g2 = generate(2);
    for (final p in g2.report.solution!) {
      await _tapFlask(tester, p.from);
      await _tapFlask(tester, p.to);
    }
    // Solved shows once the last seal has flown (juice #27).
    await tester.pumpAndSettle();
    expect(find.text('Solved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Level 3'), findsOneWidget);
  });
}
