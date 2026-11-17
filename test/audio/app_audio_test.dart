import 'package:flaszki/app.dart';
import 'package:flaszki/src/audio/game_audio.dart';
import 'package:flaszki/src/save/key_value_store.dart';
import 'package:flaszki/src/save/save_store.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_audio_out.dart';

final _sound = find.byKey(const ValueKey('settings-sound'));

/// First Flask with Layers in Level 1.
int _nonEmpty() => generate(1).level.flasks.indexWhere((f) => !f.isEmpty);

void main() {
  late FakeAudioOut out;

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    out = FakeAudioOut();
    await tester.pumpWidget(
      FlaszkiApp(
        levelSource: (n) => SynchronousFuture(generate(n)),
        save: SaveStore(MemoryStore()),
        audioOut: out,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester) async {
    await tester.tap(find.byKey(ValueKey('flask-${_nonEmpty()}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('flask-${_nonEmpty()}'))); // lower
    await tester.pumpAndSettle();
  }

  testWidgets('Sound toggle in Settings is respected', (tester) async {
    await launch(tester);
    await select(tester);
    expect(out.sfx, [Sfx.select]);

    await tester.tap(find.byKey(const ValueKey('settings')));
    await tester.pumpAndSettle();
    await tester.tap(_sound);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(180, 20)); // close sheet
    await tester.pumpAndSettle();

    out.plays.clear();
    await select(tester);
    expect(out.plays, isEmpty);
  });

  testWidgets('mutes when backgrounded, unmutes on resume', (tester) async {
    await launch(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(out.muted, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(out.muted, isFalse);
  });
}
