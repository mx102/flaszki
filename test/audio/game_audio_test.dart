import 'dart:math' as math;

import 'package:flaszki/src/audio/game_audio.dart';
import 'package:flaszki/src/play/play_controller.dart';
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

  group('Pour', () {
    // Goal Queue [0, 1]; Flask 2 fills with 1 while 0 is at the head.
    late PlayController play;
    setUp(
      () => play = PlayController(
        Game(
          Level(
            flasks: [
              Flask([0, 0, 0]),
              Flask([0]),
              Flask([1, 1, 1]),
              Flask([1]),
              Flask([]),
            ],
            goalQueue: [0, 1],
          ),
        ),
      ),
    );
    TapEffect pour(int from, int to) {
      play.tapFlask(from);
      return play.tapFlask(to);
    }

    test('one glug per Layer moved, pitch rising as the target fills', () {
      final quiet = GameAudio(out, enabled: () => true, jitter: 0);
      quiet.tap(pour(0, 4));
      expect(out.sfx, [Sfx.pour, Sfx.pour, Sfx.pour]);
      final speeds = [for (final p in out.plays) p.speed];
      expect(speeds[0], lessThan(speeds[1]));
      expect(speeds[1], lessThan(speeds[2]));
      final delays = [for (final p in out.plays) p.delay];
      expect(delays[0], Duration.zero);
      expect(delays[1], greaterThan(delays[0]));
      expect(delays[2], greaterThan(delays[1]));
    });

    test('target filling an empty Flask starts lower than a fuller one', () {
      final quiet = GameAudio(out, enabled: () => true, jitter: 0);
      quiet.tap(pour(1, 4)); // into empty → fill 1
      final low = out.plays.single.speed;
      out.plays.clear();
      quiet.tap(pour(3, 2)); // 3 → 4 Layers
      expect(out.plays.first.speed, greaterThan(low));
    });

    test('Completed Flask left waiting squeaks its cork', () {
      audio.tap(pour(3, 2));
      expect(out.sfx, [Sfx.pour, Sfx.waitingCork]);
    });

    test('Seal pops a cork and advances the queue; last Seal → Solved', () {
      audio.tap(pour(3, 2));
      out.plays.clear();
      audio.tap(pour(1, 0)); // seals 0, then waiting 2 in cascade
      expect(out.sfx, [
        Sfx.pour,
        Sfx.seal,
        Sfx.queueAdvance,
        Sfx.seal,
        Sfx.queueAdvance,
        Sfx.solved,
      ]);
      final delays = [for (final p in out.plays) p.delay];
      for (var i = 1; i < delays.length; i++) {
        expect(delays[i], greaterThan(delays[i - 1]), reason: '$i');
      }
    });
  });
}
