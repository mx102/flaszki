import 'dart:math' as math;

import 'package:flaszki/src/audio/game_audio.dart';
import 'package:flaszki/src/play/play_controller.dart';
import 'package:flaszki/src/ui/anim/juice.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_audio_out.dart';

void main() {
  late FakeAudioOut out;
  late GameAudio audio;
  var enabled = true;

  setUp(() {
    out = FakeAudioOut();
    enabled = true;
    audio = GameAudio(out, enabled: () => enabled, seed: 1);
  });

  test('Select plays a glass clink', () {
    audio.tap(const Selected(0));
    expect(out.sfx, [Sfx.select]);
  });

  test('invalid tap plays a muted tap; Deselect and Ignored are silent', () {
    audio.tap(const Rejected(1));
    audio.tap(const Deselected());
    audio.tap(const Ignored());
    expect(out.sfx, [Sfx.invalid]);
  });

  test('Undo plays a swish; Restart is silent', () {
    audio.undo();
    audio.restart();
    expect(out.sfx, [Sfx.undo]);
  });

  test('pitch and volume jitter stay within ±5%, seeded', () {
    for (var i = 0; i < 300; i++) {
      audio.tap(const Selected(0));
    }
    final volumes = {for (final p in out.plays) p.volume};
    final speeds = {for (final p in out.plays) p.speed};
    for (final v in volumes) {
      expect(v, inInclusiveRange(0.95, 1.05));
    }
    for (final s in speeds) {
      expect(s, inInclusiveRange(0.95, 1.05));
    }
    expect(volumes.length, greaterThan(100), reason: 'varies');
    expect(speeds.reduce(math.min), lessThan(0.97));
    expect(speeds.reduce(math.max), greaterThan(1.03));

    final again = FakeAudioOut();
    final audio2 = GameAudio(again, enabled: () => true, seed: 1);
    for (var i = 0; i < 300; i++) {
      audio2.tap(const Selected(0));
    }
    expect('${again.plays}', '${out.plays}');
  });

  test('clink, glug and cork pop each have 2–3 variants, all used', () {
    for (final sfx in [Sfx.select, Sfx.pour, Sfx.seal]) {
      expect(sfx.variants, inInclusiveRange(2, 3));
    }
    for (var i = 0; i < 50; i++) {
      audio.tap(const Selected(0));
    }
    expect({for (final p in out.plays) p.variant}, {0, 1, 2});
  });

  test('Sound toggle off: nothing plays', () {
    enabled = false;
    audio.tap(const Selected(0));
    audio.tap(const Rejected(0));
    audio.undo();
    expect(out.plays, isEmpty);
    enabled = true;
    audio.tap(const Selected(0));
    expect(out.sfx, [Sfx.select]);
  });

  test('backgrounded: output muted and no new sounds', () {
    audio.setBackgrounded(true);
    expect(out.muted, isTrue);
    audio.tap(const Selected(0));
    expect(out.plays, isEmpty);
    audio.setBackgrounded(false);
    expect(out.muted, isFalse);
    audio.tap(const Selected(0));
    expect(out.sfx, [Sfx.select]);
  });

  group('Pour (driven by juice cues, so sound follows the animation)', () {
    JuiceCue glug(int fill) => JuiceCue(JuiceCueKind.glug, 2, 0, fill: fill);

    test('a Poured tap itself is silent', () {
      final p = PlayController(
        Game(
          Level(
            flasks: [
              Flask([0]),
              Flask([]),
            ],
            goalQueue: [0],
          ),
        ),
      );
      p.tapFlask(0);
      audio.tap(p.tapFlask(1));
      expect(out.plays, isEmpty);
    });

    test('each glug cue plays a glug at once, pitch rising with fill', () {
      final quiet = GameAudio(out, enabled: () => true, jitter: 0);
      for (final f in [1, 2, 3]) {
        quiet.cue(glug(f));
      }
      expect(out.sfx, [Sfx.pour, Sfx.pour, Sfx.pour]);
      final speeds = [for (final p in out.plays) p.speed];
      expect(speeds[0], lessThan(speeds[1]));
      expect(speeds[1], lessThan(speeds[2]));
    });

    test('waiting cue squeaks the cork; seal pops it; orb pop chimes', () {
      audio.cue(const JuiceCue(JuiceCueKind.waiting, 2, 0));
      audio.cue(const JuiceCue(JuiceCueKind.seal, 2, 0));
      audio.cue(const JuiceCue(JuiceCueKind.orbPop, 2, 0));
      expect(out.sfx, [Sfx.waitingCork, Sfx.seal, Sfx.queueAdvance]);
    });

    test('other cues are silent', () {
      for (final k in [
        JuiceCueKind.pourStart,
        JuiceCueKind.streamStart,
        JuiceCueKind.pourEnd,
        JuiceCueKind.reverseReflow,
      ]) {
        audio.cue(JuiceCue(k, 0, 0));
      }
      expect(out.plays, isEmpty);
    });

    test('Solved overlay shown plays the Solved chime', () {
      audio.solved();
      expect(out.sfx, [Sfx.solved]);
    });

    test('cues respect the Sound toggle and backgrounding', () {
      enabled = false;
      audio.cue(glug(1));
      enabled = true;
      audio.setBackgrounded(true);
      audio.cue(glug(1));
      audio.solved();
      expect(out.plays, isEmpty);
    });
  });
}
