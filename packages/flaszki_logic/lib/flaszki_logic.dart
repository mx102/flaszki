/// Pure-Dart game logic for Flaszki: rules, Pour, Goal Queue, generator,
/// curve, solver, Dead End check and save model (PRD §8, ADR 0001).
///
/// Must not import Flutter, Flame or `dart:ui`.
library;

export 'src/board_state.dart';
export 'src/game.dart';
export 'src/level.dart' hide listEquals;
