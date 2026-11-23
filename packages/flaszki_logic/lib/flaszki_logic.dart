/// Pure-Dart game logic for Flaszki: rules, Pour, Goal Queue, generator,
/// curve, solver, Dead End check and save model (PRD §8, ADR 0001).
///
/// Must not import Flutter, Flame or `dart:ui`.
library;

export 'src/board_state.dart';
export 'src/curve.dart';
export 'src/dead_end.dart';
export 'src/game.dart';
export 'src/generator.dart';
export 'src/level.dart' hide listEquals;
export 'src/prng.dart' show Prng, maxPrngBound;
export 'src/solver.dart';
