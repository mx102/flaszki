import 'package:flaszki/src/audio/game_audio.dart';

/// One recorded [AudioOut.play] call.
class Played {
  const Played(this.sfx, this.variant, this.volume, this.speed, this.delay);
  final Sfx sfx;
  final int variant;
  final double volume, speed;
  final Duration delay;

  @override
  String toString() =>
      '$sfx#$variant v$volume s$speed +${delay.inMilliseconds}ms';
}

/// Records calls instead of playing.
class FakeAudioOut implements AudioOut {
  final plays = <Played>[];
  bool muted = false;

  List<Sfx> get sfx => [for (final p in plays) p.sfx];

  @override
  void play(
    Sfx sfx, {
    int variant = 0,
    double volume = 1,
    double speed = 1,
    Duration delay = Duration.zero,
  }) => plays.add(Played(sfx, variant, volume, speed, delay));

  @override
  void setMuted(bool muted) => this.muted = muted;
}
