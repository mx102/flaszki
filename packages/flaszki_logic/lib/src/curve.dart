/// Difficulty curve (ADR 0004): a hand-written table that depends only on the
/// Level number. Part of the versioned generator algorithm: any change bumps
/// `generatorVersion`.
library;

import 'level.dart' show flaskCapacity;

/// Shape of a Level before the deal.
class LevelParams {
  const LevelParams(
    this.colorCount,
    this.flasksPerColor, {
    this.emptyFlasks = 2,
  });

  /// Distinct Colors, `≤ maxColors`; Color ids `0..colorCount-1`.
  final int colorCount;

  /// Full Flasks per Color (same for every Color).
  final int flasksPerColor;

  /// Empty Flasks (2; 3 only via the generator's fallback).
  final int emptyFlasks;

  /// Flask capacity in Layers.
  int get capacity => flaskCapacity;

  /// Total Flasks on the board.
  int get flaskCount => colorCount * flasksPerColor + emptyFlasks;

  @override
  bool operator ==(Object other) =>
      other is LevelParams &&
      other.colorCount == colorCount &&
      other.flasksPerColor == flasksPerColor &&
      other.emptyFlasks == emptyFlasks;

  @override
  int get hashCode => Object.hash(colorCount, flasksPerColor, emptyFlasks);

  @override
  String toString() =>
      'LevelParams($colorCount×$flasksPerColor, $emptyFlasks empty)';
}

/// Endless-play cycle from Level 41, indexed by `(N − 41) mod 6`.
const List<LevelParams> _endless = [
  LevelParams(12, 1),
  LevelParams(10, 1),
  LevelParams(7, 2),
  LevelParams(11, 1),
  LevelParams(12, 1),
  LevelParams(6, 2),
];

const LevelParams _lateBreather = LevelParams(8, 1);

/// Ramp Levels 1–40 (×1): 3 Colors L1–3, then +1 every 4 Levels, capped at 12.
LevelParams _ramp(int n) {
  final colors = n <= 3 ? 3 : 4 + (n - 4) ~/ 4;
  return LevelParams(colors < 12 ? colors : 12, 1);
}

/// [LevelParams] for Level [n] (1-based).
LevelParams curve(int n) {
  if (n < 1) throw ArgumentError.value(n, 'n', 'Level numbers start at 1');
  final breather = n % 5 == 0;
  if (n <= 40) return _ramp(breather ? (n - 8 > 1 ? n - 8 : 1) : n);
  if (breather) return _lateBreather;
  return _endless[(n - 41) % 6];
}
