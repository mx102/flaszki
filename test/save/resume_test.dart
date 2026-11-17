import 'dart:convert';

import 'package:flaszki/app.dart';
import 'package:flaszki/src/play/level_sequencer.dart';
import 'package:flaszki/src/save/key_value_store.dart';
import 'package:flaszki/src/save/save_store.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _flask(int i) => find.byKey(ValueKey('flask-$i'));

void main() {
  late MemoryStore disk;
  late List<int> requested;

  /// Generator in use; a different one simulates a `generatorVersion` bump.
  LevelSource tracking(GeneratedLevel Function(int) gen) => (n) {
    requested.add(n);
    return SynchronousFuture(gen(n));
  };

  /// Launches the app over [disk]; a new call = kill + relaunch.
  Future<void> launch(WidgetTester tester, LevelSource source) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    requested = [];
    await tester.pumpWidget(const SizedBox()); // kill
    await tester.pumpWidget(
      FlaszkiApp(levelSource: source, save: SaveStore(disk)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pour(WidgetTester tester, Pour p) async {
    await tester.tap(_flask(p.from));
    await tester.pump();
    await tester.tap(_flask(p.to));
    await tester.pump();
  }

  setUp(() => disk = MemoryStore());

  testWidgets('kill mid-Level → relaunch restores exact state + Undo', (
    tester,
  ) async {
    await launch(tester, tracking(generate));
    final g = generate(1);
    final sol = g.report.solution!;
    for (final p in sol.take(3)) {
      await pour(tester, p);
    }
    final before = jsonDecode(disk.data['level']!);

    await launch(tester, tracking(generate));
    expect(find.text('Level 1'), findsOneWidget);
    expect(requested, [2], reason: 'Level 1 restored, not regenerated');
    expect(jsonDecode(disk.data['level']!), before);

    // Undo history survived: undo all 3, then Undo is disabled.
    final expected = Game(g.level);
    for (final p in sol.take(2)) {
      expected.pour(p.from, p.to);
    }
    await tester.tap(find.byKey(const ValueKey('undo')));
    await tester.pumpAndSettle();
    final saved = Game.fromJson(jsonDecode(disk.data['level']!));
    expect(saved.toJson(), expected.toJson());

    // And the restored Level plays on to Solved → Level 2 saved.
    for (final p in sol.skip(2)) {
      await pour(tester, p);
    }
    await tester.pumpAndSettle();
    expect(find.text('Solved'), findsOneWidget);
    await launch(tester, tracking(generate));
    expect(find.text('Level 2'), findsOneWidget);
  });

  testWidgets('generatorVersion bump: in-progress Level finishes from its '
      'snapshot; next Level comes from the new generator', (tester) async {
    await launch(tester, tracking(generate));
    final old = generate(1);
    await pour(tester, old.report.solution!.first);

    // "New generator": Level N is generate(N + 10) under the hood.
    GeneratedLevel newGen(int n) {
      final g = generate(n + 10);
      return GeneratedLevel(
        levelNumber: n,
        level: g.level,
        params: g.params,
        attempts: g.attempts,
        usedFallback: g.usedFallback,
        report: g.report,
      );
    }

    await launch(tester, tracking(newGen));
    expect(find.text('Level 1'), findsOneWidget);
    expect(requested, isNot(contains(1)));
    for (var i = 0; i < old.level.flasks.length; i++) {
      expect(_flask(i), findsOneWidget);
    }
    for (final p in old.report.solution!.skip(1)) {
      await pour(tester, p);
    }
    await tester.pumpAndSettle();
    expect(find.text('Solved'), findsOneWidget);
    await tester.tapAt(const Offset(10, 300));
    await tester.pumpAndSettle();
    expect(find.text('Level 2'), findsOneWidget);
    final saved = Game.fromJson(jsonDecode(disk.data['level']!));
    expect(saved.level.toJson(), newGen(2).level.toJson());
  });
}
