import 'package:flaszki/src/l10n.dart';
import 'package:flaszki/src/play/level_sequencer.dart';
import 'package:flaszki/src/ui/anim/juice.dart';
import 'package:flaszki/src/ui/level_screen.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

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

// 0:[0 0 1 1] 1:[1 1 0 0] 2:[] 3:[] 4:[2 2 2] 5:[2]; queue 2 first.
final _level = Level(
  flasks: [
    Flask([0, 0, 1, 1]),
    Flask([1, 1, 0, 0]),
    Flask([]),
    Flask([]),
    Flask([2, 2, 2]),
    Flask([2]),
  ],
  goalQueue: [2, 1, 0],
);

void main() {
  late Game game;
  late List<JuiceCue> cues;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    cues = [];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        home: LevelScreen(
          levelSource: _fixed(_level),
          deadEndRunner: (_) async => false,
          onLevelStarted: (_, g) => game = g,
          onJuice: cues.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// One tap, one 16 ms frame: well inside any animation.
  Future<void> tap(WidgetTester tester, int i) async {
    await tester.tap(_flask(i), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('rapid taps mid-animation never drop or delay a Pour', (
    tester,
  ) async {
    await pumpScreen(tester);
    final expected = <List<int>>[];
    Future<void> pour(int from, int to) async {
      await tap(tester, from);
      await tap(tester, to);
      expected.add([from, to]);
      expect(
        [
          for (final p in game.pours) [p.from, p.to],
        ],
        expected,
        reason: 'Pour $from→$to applied at once',
      );
    }

    await pour(0, 2); // 1 1 → 2
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'animating');
    await pour(2, 3); // target of the running Pour pours on at once
    await pour(1, 2); // 0 0 → 2
    await pour(5, 4); // seals 4 (color 2) while others still animate
    expect(game.state.isOnBoard(4), isFalse);
    await pour(3, 1); // 1 1 → [1 1]: seals 1 (queue head now 1)
    expect(game.state.isOnBoard(1), isFalse);
    expect(game.state.isSolved, isFalse);

    await tester.pumpAndSettle();
    expect([
      for (final p in game.pours) [p.from, p.to],
    ], expected);
    final kinds = cues.map((c) => c.kind).toList();
    expect(
      kinds.where((k) => k == JuiceCueKind.pourStart).length,
      expected.length,
    );
    expect(
      kinds.where((k) => k == JuiceCueKind.pourEnd).length,
      expected.length,
    );
    expect(kinds.where((k) => k == JuiceCueKind.orbPop).length, 2);
    expect(_flask(4), findsNothing, reason: 'sealed Flask gone after fly');
  });

  testWidgets('source moves beside the target mid-pour, then returns', (
    tester,
  ) async {
    await pumpScreen(tester);
    final home = tester.getCenter(_glass(0));
    final target = tester.getCenter(_glass(3));
    await tap(tester, 0);
    await tap(tester, 3);
    await tester.pump(const Duration(milliseconds: 300));
    final mid = tester.getCenter(_glass(0));
    expect(
      (mid - target).distance,
      lessThan((home - target).distance),
      reason: 'moved toward target',
    );
    await tester.pumpAndSettle();
    expect(tester.getCenter(_glass(0)), home);
  });
}
