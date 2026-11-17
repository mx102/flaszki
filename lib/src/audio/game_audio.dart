import 'dart:math' as math;

import 'package:flaszki_logic/flaszki_logic.dart'
    show PourOutcome, flaskCapacity;

import '../play/play_controller.dart';

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
  /// Fire-and-forget; [speed] scales pitch, [delay] schedules it later.
  void play(
    Sfx sfx, {
    int variant = 0,
    double volume = 1,
    double speed = 1,
    Duration delay = Duration.zero,
  });

  /// Silences all output (app backgrounded).
  void setMuted(bool muted);
}

/// Sound timeline of one Pour (PRD §6). #27 may retune to the animation.
const glugGap = Duration(milliseconds: 110);
const sealGap = Duration(milliseconds: 300);
const chimeAfterSeal = Duration(milliseconds: 120);
const solvedAfterChime = Duration(milliseconds: 250);

/// Maps game events to [Sfx] (PRD §6): variants, ±[jitter] pitch/volume,
/// Sound toggle ([enabled]), mute while backgrounded.
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

  /// React to a tap on a Flask.
  void tap(TapEffect effect) {
    switch (effect) {
      case Selected():
        _play(Sfx.select);
      case Rejected():
        _play(Sfx.invalid);
      case Poured(:final to, :final outcome):
        _poured(to, outcome);
      case Deselected() || Ignored():
        break;
    }
  }

  /// A Pour was undone.
  void undo() => _play(Sfx.undo);

  /// Restart is silent (PRD §6).
  void restart() {}

  /// App went to / came back from the background.
  void setBackgrounded(bool value) {
    _backgrounded = value;
    _out.setMuted(value);
  }

  void _poured(int to, PourOutcome outcome) {
    final layers = outcome.layersMoved;
    final state = outcome.state;
    final before = state.flasks[to].layers.length - layers;
    for (var k = 0; k < layers; k++) {
      final fill = (before + k + 1) / flaskCapacity;
      _play(Sfx.pour, speed: 0.9 + 0.25 * fill, delay: glugGap * k);
    }
    var t = glugGap * layers;
    final sealed = outcome.sealed;
    if (state.isOnBoard(to) && state.flasks[to].isCompleted) {
      _play(Sfx.waitingCork, delay: t);
    }
    for (var i = 0; i < sealed.length; i++) {
      if (i > 0) t += sealGap;
      _play(Sfx.seal, delay: t);
      _play(Sfx.queueAdvance, delay: t + chimeAfterSeal);
    }
    if (state.isSolved) {
      _play(Sfx.solved, delay: t + chimeAfterSeal + solvedAfterChime);
    }
  }

  void _play(Sfx sfx, {double speed = 1, Duration delay = Duration.zero}) {
    if (_backgrounded || !enabled()) return;
    _out.play(
      sfx,
      variant: sfx.variants > 1 ? _rng.nextInt(sfx.variants) : 0,
      volume: sfx.volume * _jitter(),
      speed: speed * _jitter(),
      delay: delay,
    );
  }

  double _jitter() => 1 + (_rng.nextDouble() * 2 - 1) * jitter;
}
