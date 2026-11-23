/// Level generator (ADR 0002): seeded random deal + queue-order solver
/// verification with deterministic retries. Pure and synchronous.
library;

import 'board_state.dart';
import 'curve.dart';
import 'level.dart';
import 'prng.dart';
import 'solver.dart';

/// Version of the generator algorithm (generator, curve, PRNG, caps). Part of
/// the seed; bump on any change that alters Level N. Independent of the app
/// version.
const int generatorVersion = 1;

/// Attempts per params set before the fallback (ADR 0002).
const int maxAttempts = 10;

/// Verifies a dealt board; must be deterministic. Default: [solve] in hash
/// mode with [defaultNodeCap].
typedef LevelVerifier = SolveReport Function(BoardState start);

/// A generated Level plus offline-tuning metrics (never used as filters).
class GeneratedLevel {
  const GeneratedLevel({
    required this.levelNumber,
    required this.level,
    required this.params,
    required this.attempts,
    required this.usedFallback,
    required this.report,
  });

  final int levelNumber;
  final Level level;

  /// Params actually dealt: `curve(N)`, or with one extra empty Flask when
  /// [usedFallback].
  final LevelParams params;

  /// Seeds tried in total, including those rejected (1-based count).
  final int attempts;

  final bool usedFallback;

  /// Solver report of the accepted deal: `B − C`, nodes, solution.
  final SolveReport report;
}

SolveReport _defaultVerify(BoardState s) => solve(s);

/// Generates Level [n] (1-based).
///
/// Attempts `0..maxAttempts-1` deal `curve(n)` with seed
/// `[generatorVersion, n, attempt]`; if all fail, attempts
/// `maxAttempts..2·maxAttempts-1` deal the same params with one extra empty
/// Flask. Throws [StateError] if the fallback also fails (never happens for
/// Levels 1–500; see `tool/metrics.dart`).
GeneratedLevel generate(int n, {LevelVerifier verify = _defaultVerify}) {
  final base = curve(n);
  final fallback = LevelParams(
    base.colorCount,
    base.flasksPerColor,
    emptyFlasks: base.emptyFlasks + 1,
  );
  for (var attempt = 0; attempt < 2 * maxAttempts; attempt++) {
    final isFallback = attempt >= maxAttempts;
    final params = isFallback ? fallback : base;
    final level = _deal(params, Prng.seed([generatorVersion, n, attempt]));
    if (level == null) continue;
    final report = verify(BoardState.initial(level));
    if (report.result != Solvability.solvable) continue;
    return GeneratedLevel(
      levelNumber: n,
      level: level,
      params: params,
      attempts: attempt + 1,
      usedFallback: isFallback,
      report: report,
    );
  }
  throw StateError('Level $n: no solvable deal (generator v$generatorVersion)');
}

/// Deals [p]: Fisher–Yates over all Layers into full Flasks (then the empty
/// Flasks), then Fisher–Yates over the Goal Queue multiset, same stream.
/// Null when a Flask starts Completed.
Level? _deal(LevelParams p, Prng rng) {
  final layers = <int>[
    for (var c = 0; c < p.colorCount; c++)
      for (var k = 0; k < p.flasksPerColor * p.capacity; k++) c,
  ];
  rng.shuffle(layers);
  final queue = <int>[
    for (var c = 0; c < p.colorCount; c++)
      for (var k = 0; k < p.flasksPerColor; k++) c,
  ];
  rng.shuffle(queue);
  final flasks = <Flask>[
    for (var i = 0; i < layers.length; i += p.capacity)
      Flask(layers.sublist(i, i + p.capacity)),
    for (var i = 0; i < p.emptyFlasks; i++) Flask(const []),
  ];
  if (flasks.any((f) => f.isCompleted)) return null;
  return Level(flasks: flasks, goalQueue: queue);
}
