import 'package:flaszki/src/ui/board_view.dart' show reflowDuration;
import 'package:flaszki/src/ui/level_screen.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Solvable; pouring Flask 2 onto Flask 0 is a Dead End.
final _level = Level(
  flasks: [
    Flask([1, 0, 1]),
    Flask([0, 0, 1]),
    Flask([0, 1]),
  ],
  goalQueue: [0, 1],
);

Future<GeneratedLevel> _source(int n) => SynchronousFuture(
  GeneratedLevel(
    levelNumber: n,
    level: _level,
    params: curve(n),
    attempts: 1,
    usedFallback: false,
    report: const SolveReport(Solvability.solvable, 0, 0, null),
  ),
);

Finder _flask(int i) => find.byKey(ValueKey('flask-$i'));
final _banner = find.byKey(const ValueKey('dead-end'));

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: LevelScreen(
        levelSource: _source,
        // Real exact-mode check, synchronously (no isolate in fake time).
        deadEndRunner: (s) => SynchronousFuture(isDeadEnd(s)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pour(WidgetTester tester, int from, int to) async {
  await tester.tap(_flask(from));
  await tester.pump();
  await tester.tap(_flask(to));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Dead End shows banner; banner Undo clears it', (tester) async {
    await _pump(tester);
    expect(_banner, findsNothing);
    await _pour(tester, 2, 0);
    expect(find.text('No way to finish from here'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dead-end-undo')));
    await tester.pumpAndSettle();
    expect(_banner, findsNothing);
  });

  testWidgets('banner appears only after the Pour animation', (tester) async {
    await _pump(tester);
    await tester.tap(_flask(2));
    await tester.pump();
    await tester.tap(_flask(0));
    await tester.pump();
    expect(_banner, findsNothing);
    await tester.pump(reflowDuration);
    expect(_banner, findsOneWidget);
  });

  testWidgets('banner Restart restarts at once (no confirm)', (tester) async {
    await _pump(tester);
    await _pour(tester, 2, 0);
    await tester.tap(find.byKey(const ValueKey('dead-end-restart')));
    await tester.pumpAndSettle();
    expect(_banner, findsNothing);
    expect(find.byKey(const ValueKey('layer-2-1')), findsOneWidget);
  });

  testWidgets('board stays playable while the banner shows', (tester) async {
    await _pump(tester);
    await _pour(tester, 2, 0);
    await _pour(tester, 0, 1);
    expect(_banner, findsOneWidget);
    expect(find.byKey(const ValueKey('layer-1-3')), findsOneWidget);
  });
}
