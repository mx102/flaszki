import 'package:flaszki/src/audio/game_audio.dart';
import 'package:flaszki/src/l10n.dart';
import 'package:flaszki/src/ui/level_screen.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_audio_out.dart';

/// Solvable; pouring Flask 2 onto Flask 0 is a Dead End.
final _level = Level(
  flasks: [
    Flask([1, 0, 1]),
    Flask([0, 0, 1]),
    Flask([0, 1]),
  ],
  goalQueue: [0, 1],
);

Future<GeneratedLevel> _source(int n) => _sourceOf(_level, n);

Future<GeneratedLevel> _sourceOf(Level level, int n) => SynchronousFuture(
  GeneratedLevel(
    levelNumber: n,
    level: level,
    params: curve(n),
    attempts: 1,
    usedFallback: false,
    report: const SolveReport(Solvability.solvable, 0, 0, null),
  ),
);

Finder _key(String k) => find.byKey(ValueKey(k));

Future<FakeAudioOut> _pump(WidgetTester tester, {Level? level}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final out = FakeAudioOut();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LevelScreen(
        levelSource: level == null ? _source : (n) => _sourceOf(level, n),
        deadEndRunner: (s) => SynchronousFuture(isDeadEnd(s)),
        audio: GameAudio(out, enabled: () => true, seed: 1),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return out;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('taps sound: clink, glug; invalid tap', (tester) async {
    final out = await _pump(tester);
    await _tap(tester, 'flask-2');
    expect(out.sfx, [Sfx.select]);
    await _tap(tester, 'flask-0');
    expect(out.sfx, [Sfx.select, Sfx.pour]);
    out.plays.clear();
    await _tap(tester, 'flask-1');
    await _tap(tester, 'flask-0'); // full
    expect(out.sfx, [Sfx.select, Sfx.invalid]);
  });

  testWidgets('Dead End banner and Restart are silent; Undo swishes', (
    tester,
  ) async {
    final out = await _pump(tester);
    await _tap(tester, 'flask-2');
    await _tap(tester, 'flask-0');
    expect(_key('dead-end'), findsOneWidget);
    expect(out.sfx, [Sfx.select, Sfx.pour]);

    out.plays.clear();
    await _tap(tester, 'dead-end-restart');
    await _tap(tester, 'restart');
    await _tap(tester, 'restart');
    expect(out.plays, isEmpty);

    await _tap(tester, 'flask-2');
    await _tap(tester, 'flask-0');
    out.plays.clear();
    await _tap(tester, 'undo');
    expect(out.sfx, [Sfx.undo]);
    await _tap(tester, 'undo'); // nothing left to undo
    expect(out.sfx, [Sfx.undo]);
  });

  // Pour timing (PRD §5): move 0.26 s, then one Layer per 1/3 of the stream.
  final threeLayers = Level(
    flasks: [
      Flask([1, 0, 0, 0]),
      Flask([]),
      Flask([1, 1, 1]),
    ],
    goalQueue: [0, 1],
  );

  testWidgets('glugs play as each Layer falls, not on the tap', (tester) async {
    final out = await _pump(tester, level: threeLayers);
    await _tap(tester, 'flask-0');
    out.plays.clear();
    await tester.tap(_key('flask-1'));
    await tester.pump();
    expect(out.plays, isEmpty, reason: 'source still moving');
    await tester.pump(const Duration(milliseconds: 250));
    expect(out.plays, isEmpty);
    await tester.pump(const Duration(milliseconds: 20));
    expect(out.sfx, [Sfx.pour]);
    await tester.pump(const Duration(milliseconds: 160));
    expect(out.sfx, [Sfx.pour, Sfx.pour]);
    await tester.pumpAndSettle();
    expect(out.sfx, [Sfx.pour, Sfx.pour, Sfx.pour]);
  });

  testWidgets('a Pour cut short by a tap plays no stale glugs', (tester) async {
    final out = await _pump(tester, level: threeLayers);
    await _tap(tester, 'flask-0');
    await tester.tap(_key('flask-1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    out.plays.clear();
    await tester.tap(_key('flask-1')); // finishes the Pour, selects 1
    await tester.pump();
    await tester.pumpAndSettle();
    expect(out.sfx, [Sfx.select]);
  });

  testWidgets('seal pops, orb chimes, Solved chimes with the overlay', (
    tester,
  ) async {
    final out = await _pump(
      tester,
      level: Level(
        flasks: [
          Flask([0, 0, 0]),
          Flask([0]),
        ],
        goalQueue: [0],
      ),
    );
    await _tap(tester, 'flask-1');
    await tester.tap(_key('flask-0'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // landed (0.51 s)
    expect(out.sfx, [Sfx.select, Sfx.pour, Sfx.seal]);
    await tester.pump(const Duration(milliseconds: 600)); // fly not done
    expect(out.sfx.last, Sfx.seal);
    expect(_key('solved'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200)); // orb pops
    expect(out.sfx.last, Sfx.queueAdvance);
    expect(_key('solved'), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(_key('solved'), findsOneWidget);
    expect(out.sfx, [
      Sfx.select,
      Sfx.pour,
      Sfx.seal,
      Sfx.queueAdvance,
      Sfx.solved,
    ]);
    await tester.pump(const Duration(seconds: 3));
  });
}
