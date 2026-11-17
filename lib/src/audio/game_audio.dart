import 'dart:math' as math;

import 'package:flaszki_logic/flaszki_logic.dart' show flaskCapacity;

import '../play/play_controller.dart';
import '../ui/anim/juice.dart';

/// Sound effects (PRD §6). Dead End hint and Restart have none.
enum Sfx {
  /// Select: soft glass clink.
  select(variants: 3),

  /// One glug per Layer poured (+ splash).
  pour(variants: 3),

  /// Invalid tap: dull muted tap.
  invalid,

  /// Seal: cork pop.
  seal(variants: 3),

  /// Goal Queue advance: orb chime.
  queueAdvance,

  /// Waiting Completed Flask appears: quiet cork squeak.
  waitingCork(volume: 0.5),

  /// Solved: chime arpeggio (~1.5 s).
  solved,

  /// Undo: soft reverse swish.
  undo(volume: 0.7);

  const Sfx({this.variants = 1, this.volume = 1});

  /// Number of recorded variants (`<name>_<1..variants>.ogg`).
  final int variants;

  /// Base mix volume.
  final double volume;

  /// Asset key of [variant] (0-based).
  String asset(int variant) => 'assets/audio/${name}_${variant + 1}.ogg';
}

/// Plays [Sfx]. App: `SoloudAudioOut`; tests: a recording fake.
abstract interface class AudioOut {
  /// Fire-and-forget, now; [speed] scales pitch.
  void play(Sfx sfx, {int variant = 0, double volume = 1, double speed = 1});

  /// A user gesture began (pointer down anywhere): web may start the engine
  /// now (browsers need a gesture), before the first sound is asked for.
  void unlock();

  /// Silences all output (app backgrounded).
  void setMuted(bool muted);
}

/// Maps game events to [Sfx] (PRD §6): variants, ±[jitter] pitch/volume,
/// Sound toggle ([enabled]), mute while backgrounded. Pour / seal sounds
/// follow the animation: they play on its [JuiceCue]s, never on a timer, so
/// a Pour cut short plays nothing stale.
class GameAudio {
  GameAudio(this._out, {required this.enabled, int? seed, this.jitter = 0.05})
    : _rng = math.Random(seed);

  final AudioOut _out;
  final math.Random _rng;

  /// Sound toggle (Settings), read on every sound.
  final bool Function() enabled;

  /// Max relative pitch/volume deviation.
  final double jitter;

  bool _backgrounded = false;

  /// React to a tap on a Flask. A Pour sounds through its [cue]s.
  void tap(TapEffect effect) {
    switch (effect) {
      case Selected():
        _play(Sfx.select);
      case Rejected():
        _play(Sfx.invalid);
      case Poured() || Deselected() || Ignored():
        break;
    }
  }

  /// A Pour / seal animation moment (PRD §6 pour timeline).
  void cue(JuiceCue cue) {
    switch (cue.kind) {
      case JuiceCueKind.glug:
        // Pitch rises as the target fills.
        _play(Sfx.pour, speed: 0.9 + 0.25 * cue.fill / flaskCapacity);
      case JuiceCueKind.waiting:
        _play(Sfx.waitingCork);
      case JuiceCueKind.seal:
        _play(Sfx.seal);
      case JuiceCueKind.orbPop:
        _play(Sfx.queueAdvance);
      case JuiceCueKind.pourStart ||
          JuiceCueKind.streamStart ||
          JuiceCueKind.pourEnd ||
          JuiceCueKind.reverseReflow:
        break;
    }
  }

  /// The Solved overlay appeared.
  void solved() => _play(Sfx.solved);

  /// A Pour was undone.
  void undo() => _play(Sfx.undo);

  /// Restart is silent (PRD §6).
  void restart() {}

  /// App went to / came back from the background.
  void setBackgrounded(bool value) {
    _backgrounded = value;
    _out.setMuted(value);
  }

  void _play(Sfx sfx, {double speed = 1}) {
    if (_backgrounded || !enabled()) return;
    _out.play(
      sfx,
      variant: sfx.variants > 1 ? _rng.nextInt(sfx.variants) : 0,
      volume: sfx.volume * _jitter(),
      speed: speed * _jitter(),
    );
  }

  double _jitter() => 1 + (_rng.nextDouble() * 2 - 1) * jitter;
}
