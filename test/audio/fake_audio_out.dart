import 'package:flaszki/src/audio/game_audio.dart';

/// One recorded [AudioOut.play] call.
class Played {
  const Played(this.sfx, this.variant, this.volume, this.speed);
  final Sfx sfx;
  final int variant;
  final double volume, speed;

  @override
  String toString() => '$sfx#$variant v$volume s$speed';
}

/// Records calls instead of playing.
class FakeAudioOut implements AudioOut {
  final plays = <Played>[];
  bool muted = false;

  List<Sfx> get sfx => [for (final p in plays) p.sfx];

  @override
  void play(Sfx sfx, {int variant = 0, double volume = 1, double speed = 1}) =>
      plays.add(Played(sfx, variant, volume, speed));

  @override
  void setMuted(bool muted) => this.muted = muted;
}
