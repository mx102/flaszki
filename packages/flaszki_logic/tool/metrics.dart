/// Dev metrics for Levels 1–N (default 500; ADR 0004). Not run in CI.
///
///     dart run tool/metrics.dart [maxLevel] [--levels]
///     dart compile exe tool/metrics.dart -o build/metrics && build/metrics
///
/// Re-verifies every Level by replaying the solver's solution through `Game`
/// (queue-order rules) and exits 1 if any Level fails. Reports per-config
/// difficulty metrics (B − C, nodes, solution length) and wall time.
library;

import 'dart:io';

import 'package:flaszki_logic/flaszki_logic.dart';

class _Row {
  _Row(this.n, this.g, this.ms);
  final int n;
  final GeneratedLevel g;
  final double ms;
}

double _pct(List<double> xs, double p) {
  final s = [...xs]..sort();
  return s[((s.length - 1) * p).round()];
}

String _f(double x) => x.toStringAsFixed(2);

void main(List<String> args) {
  final maxLevel =
      int.tryParse(
        args.firstWhere((a) => !a.startsWith('--'), orElse: () => ''),
      ) ??
      500;
  final perLevel = args.contains('--levels');
  // Warm up the JIT / caches so Level 1 is not an outlier.
  for (var n = 1; n <= 20; n++) {
    generate(n);
  }

  final rows = <_Row>[];
  final failures = <String>[];
  final sw = Stopwatch();
  for (var n = 1; n <= maxLevel; n++) {
    sw
      ..reset()
      ..start();
    final GeneratedLevel g;
    try {
      g = generate(n);
    } on StateError catch (e) {
      failures.add('$e');
      continue;
    }
    sw.stop();
    rows.add(_Row(n, g, sw.elapsedMicroseconds / 1000));
    final game = Game(g.level);
    for (final p in g.report.solution!) {
      if (game.pour(p.from, p.to) == null) break;
    }
    if (!game.state.isSolved) failures.add('Level $n: solution does not solve');
  }

  if (perLevel) {
    print('| N | config | attempts | fallback | B−C | nodes | sol len | ms |');
    print('|---|---|---|---|---|---|---|---|');
    for (final r in rows) {
      final p = r.g.params;
      print(
        '| ${r.n} | ${p.colorCount}×${p.flasksPerColor}+'
        '${p.emptyFlasks} | ${r.g.attempts} | ${r.g.usedFallback} | '
        '${r.g.report.mergeLowerBound} | ${r.g.report.nodes} | '
        '${r.g.report.solutionLength} | ${_f(r.ms)} |',
      );
    }
    print('');
  }

  print('Levels 1–$maxLevel, generatorVersion $generatorVersion');
  print(
    '| config | Levels | B−C avg | nodes avg/max | sol len avg | '
    'max attempts | fallbacks | ms p50 | ms p95 | ms max |',
  );
  print('|---|---|---|---|---|---|---|---|---|---|');
  final byConfig = <String, List<_Row>>{};
  for (final r in rows) {
    final p = curve(r.n);
    byConfig
        .putIfAbsent('${p.colorCount}×${p.flasksPerColor}', () => [])
        .add(r);
  }
  final keys = byConfig.keys.toList()..sort();
  for (final k in [...keys, 'all']) {
    final rs = k == 'all' ? rows : byConfig[k]!;
    double avg(num Function(_Row) f) =>
        rs.fold<num>(0, (a, r) => a + f(r)) / rs.length;
    final nodes = rs.map((r) => r.g.report.nodes);
    final ms = [for (final r in rs) r.ms];
    print(
      '| $k | ${rs.length} | ${avg((r) => r.g.report.mergeLowerBound).toStringAsFixed(1)} | '
      '${avg((r) => r.g.report.nodes).round()}/${nodes.reduce((a, b) => a > b ? a : b)} | '
      '${avg((r) => r.g.report.solutionLength).toStringAsFixed(1)} | '
      '${rs.map((r) => r.g.attempts).reduce((a, b) => a > b ? a : b)} | '
      '${rs.where((r) => r.g.usedFallback).length} | ${_f(_pct(ms, .5))} | '
      '${_f(_pct(ms, .95))} | ${_f(_pct(ms, 1))} |',
    );
  }
  final worst = rows.reduce((a, b) => a.ms >= b.ms ? a : b);
  final total = rows.fold<double>(0, (a, r) => a + r.ms);
  print('');
  print(
    'mean ${_f(total / rows.length)} ms/Level; worst Level ${worst.n} '
    '(${worst.g.params}) ${_f(worst.ms)} ms',
  );
  if (failures.isNotEmpty) {
    failures.forEach(stderr.writeln);
    exit(1);
  }
  print('all ${rows.length} Levels solvable in queue order');
}
