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

Finder _key(String k) => find.byKey(ValueKey(k));

Future<FakeAudioOut> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final out = FakeAudioOut();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LevelScreen(
        levelSource: _source,
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
}
