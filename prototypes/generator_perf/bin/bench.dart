// PROTOTYPE — throwaway. Answers "Prototype generator + solver performance"
// (mx102/flaszki#6). Implements ADR 0002 roughly; no tests, no polish.
//
// Run:  dart run bin/bench.dart            (JIT)
//       dart compile exe bin/bench.dart -o /tmp/b && /tmp/b   (AOT)
//       dart compile js -O2 bin/bench.dart -o /tmp/b.js && node /tmp/b.js  (web/dart2js)
import 'dart:typed_data';

const int two32 = 4294967296;
const int generatorVersion = 1;

// ---------- PRNG: 32-bit ops that behave identically on VM and JS ----------
int mul32(int a, int b) {
  final lo = (a & 0xFFFF) * b; // < 2^48
  final hi = ((((a >>> 16) * b) % 65536) * 65536);
  return (lo + hi) % two32;
}

int rotl(int x, int k) => ((x * (1 << k)) % two32) + (x >>> (32 - k));

int fmix(int z) {
  z = mul32(z ^ (z >>> 16), 0x85ebca6b);
  z = mul32(z ^ (z >>> 13), 0xc2b2ae35);
  return z ^ (z >>> 16);
}

class Rng {
  int s0 = 0, s1 = 0, s2 = 0, s3 = 0;
  Rng(int version, int n, int attempt) {
    var st = fmix(fmix(fmix(version) ^ n) ^ attempt);
    int sm() {
      st = (st + 0x9e3779b9) % two32;
      return fmix(st);
    }

    s0 = sm();
    s1 = sm();
    s2 = sm();
    s3 = sm();
  }
  int next() {
    final r = mul32(rotl(mul32(s1, 5), 7), 9);
    final t = (s1 * 512) % two32;
    s2 ^= s0;
    s3 ^= s1;
    s1 ^= s2;
    s0 ^= s3;
    s2 ^= t;
    s3 = rotl(s3, 11);
    return r;
  }

  // Lemire bounded int in [0, range)
  int below(int range) {
    var m = next() * range;
    var l = m % two32;
    if (l < range) {
      final t = (two32 - range) % range;
      while (l < t) {
        m = next() * range;
        l = m % two32;
      }
    }
    return m ~/ two32;
  }
}

// ---------- Level ----------
class Params {
  final int colors, perColor, empties, cap;
  const Params(this.colors, this.perColor, this.empties, [this.cap = 4]);
  @override
  String toString() => 'C$colors x$perColor E$empties';
}

class Level {
  final int flasks, cap;
  final Uint8List cells; // flask f, slot j (bottom=0): cells[f*cap+j], 0 = empty
  final Int32List height;
  final List<int> queue;
  Level(this.flasks, this.cap, this.cells, this.height, this.queue);
  Level copy() => Level(flasks, cap, Uint8List.fromList(cells),
      Int32List.fromList(height), List.of(queue));
}

Level? deal(Params p, Rng rng) {
  final filled = p.colors * p.perColor;
  final layers = <int>[];
  for (var c = 1; c <= p.colors; c++) {
    for (var k = 0; k < p.perColor * p.cap; k++) layers.add(c);
  }
  for (var i = layers.length - 1; i > 0; i--) {
    final j = rng.below(i + 1);
    final t = layers[i];
    layers[i] = layers[j];
    layers[j] = t;
  }
  final q = <int>[];
  for (var c = 1; c <= p.colors; c++) {
    for (var k = 0; k < p.perColor; k++) q.add(c);
  }
  for (var i = q.length - 1; i > 0; i--) {
    final j = rng.below(i + 1);
    final t = q[i];
    q[i] = q[j];
    q[j] = t;
  }
  final f = filled + p.empties;
  final cells = Uint8List(f * p.cap);
  final h = Int32List(f);
  for (var i = 0; i < filled; i++) {
    var uniform = true;
    for (var j = 0; j < p.cap; j++) {
      cells[i * p.cap + j] = layers[i * p.cap + j];
      if (layers[i * p.cap + j] != layers[i * p.cap]) uniform = false;
    }
    if (uniform) return null; // reject starting Completed Flask
    h[i] = p.cap;
  }
  return Level(f, p.cap, cells, h, q);
}

// ---------- Solver (queue rules) ----------
enum Res { solved, unsolvable, capHit }

class SolveOut {
  final Res res;
  final int nodes, length;
  SolveOut(this.res, this.nodes, this.length);
}

class Solver {
  final int cap;
  final int nodeCap;
  final int f;
  final Uint8List c;
  final Int32List h; // -1 = removed (sealed)
  final List<int> q;
  int qi = 0;
  int nodes = 0;
  final visited = <String>{};
  final visitedH = <int>{};
  final codes = <int>[];
  static bool fastKey = false;

  // Order-independent 52-bit hash (sum of mixed per-Flask codes). A collision
  // can only cause a false "visited" -> missed solution -> Level rejected,
  // never an unsolvable Level accepted.
  int hkey() {
    var k = 0;
    for (var i = 0; i < f; i++) {
      if (h[i] < 0) continue;
      var code = 0;
      for (var j = 0; j < h[i]; j++) code = code * 13 + c[i * cap + j];
      final a = fmix(code + 1), b = fmix(code ^ 0x5bd1e995) % 1048576;
      k = (k + a * 1048576 + b) % 4503599627370496;
    }
    return (k + fmix(qi + 77)) % 4503599627370496;
  }

  Solver(Level l, this.nodeCap)
      : cap = l.cap,
        f = l.flasks,
        c = Uint8List.fromList(l.cells),
        h = Int32List.fromList(l.height),
        q = l.queue;

  bool completed(int i) {
    if (h[i] != cap) return false;
    final b = i * cap;
    for (var j = 1; j < cap; j++) {
      if (c[b + j] != c[b]) return false;
    }
    return true;
  }

  String key() {
    codes.clear();
    for (var i = 0; i < f; i++) {
      if (h[i] < 0) continue;
      var code = 0;
      for (var j = 0; j < h[i]; j++) code = code * 13 + c[i * cap + j];
      // distinguish heights: base-13 with nonzero digits is already unique
      codes.add(code);
    }
    codes.sort();
    codes.add(qi);
    return String.fromCharCodes(codes);
  }

  /// Removes head-Color Completed Flasks; returns removed indices.
  List<int> seal() {
    List<int>? removed;
    var again = true;
    while (again && qi < q.length) {
      again = false;
      for (var i = 0; i < f; i++) {
        if (h[i] == cap && c[i * cap] == q[qi] && completed(i)) {
          (removed ??= []).add(i);
          h[i] = -1;
          qi++;
          again = true;
          break;
        }
      }
    }
    return removed ?? const [];
  }

  SolveOut solve() {
    seal();
    final r = dfs(0);
    if (r >= 0) return SolveOut(Res.solved, nodes, r);
    return SolveOut(nodes >= nodeCap ? Res.capHit : Res.unsolvable, nodes, 0);
  }

  // returns solution length or -1
  int dfs(int depth) {
    if (qi == q.length) return depth;
    if (nodes >= nodeCap) return -1;
    if (fastKey ? !visitedH.add(hkey()) : !visited.add(key())) return -1;
    nodes++;
    // gen moves with simple priority
    final moves = <int>[]; // encoded prio<<16 | src<<8 | dst
    final head = q[qi];
    for (var s = 0; s < f; s++) {
      final hs = h[s];
      if (hs <= 0 || completed(s)) continue;
      final col = c[s * cap + hs - 1];
      var run = 1;
      while (run < hs && c[s * cap + hs - 1 - run] == col) run++;
      final uniform = run == hs;
      var triedEmpty = false;
      for (var d = 0; d < f; d++) {
        if (d == s) continue;
        final hd = h[d];
        if (hd < 0 || hd == cap) continue;
        int prio;
        if (hd == 0) {
          if (uniform || triedEmpty) continue;
          triedEmpty = true;
          prio = 1;
        } else {
          if (c[d * cap + hd - 1] != col) continue;
          final amt = run < cap - hd ? run : cap - hd;
          prio = (hd + amt == cap && col == head) ? 3 : 2;
          // keep partial pours; they're legal
        }
        moves.add((prio << 16) | (s << 8) | d);
      }
    }
    moves.sort((a, b) => b - a);
    for (final m in moves) {
      final s = (m >> 8) & 0xFF, d = m & 0xFF;
      final hs = h[s], hd = h[d];
      final col = c[s * cap + hs - 1];
      var run = 1;
      while (run < hs && c[s * cap + hs - 1 - run] == col) run++;
      final amt = run < cap - hd ? run : cap - hd;
      for (var k = 0; k < amt; k++) {
        c[d * cap + hd + k] = col;
        c[s * cap + hs - 1 - k] = 0;
      }
      h[s] = hs - amt;
      h[d] = hd + amt;
      final qBefore = qi;
      final removed = seal();
      final r = dfs(depth + 1);
      if (r >= 0) return r;
      for (final i in removed) h[i] = cap;
      qi = qBefore;
      for (var k = 0; k < amt; k++) {
        c[d * cap + hd + k] = 0;
        c[s * cap + hs - 1 - k] = col;
      }
      h[s] = hs;
      h[d] = hd;
      if (nodes >= nodeCap) return -1;
    }
    return -1;
  }
}

// ---------- Bench ----------
class Attempt {
  final Res res;
  final int nodes;
  final double ms;
  Attempt(this.res, this.nodes, this.ms);
}

int pct(List<num> xs, double p) {
  final s = List.of(xs)..sort();
  return s[((s.length - 1) * p).round()].round();
}

double pctD(List<double> xs, double p) {
  final s = List.of(xs)..sort();
  return s[((s.length - 1) * p).round()];
}

String f1(double x) => x.toStringAsFixed(1);

void main(List<String> args) {
  Solver.fastKey = args.contains('--fast-key') || const bool.fromEnvironment('FAST');
  print('fastKey=${Solver.fastKey}');
  final levels = 200;
  const bigCap = 1000000;
  const maxAttempts = 30;
  final configs = const [
    Params(4, 1, 2),
    Params(6, 1, 2),
    Params(8, 1, 2),
    Params(10, 1, 2),
    Params(12, 1, 2),
    Params(12, 1, 1),
    Params(12, 1, 3),
    Params(6, 2, 2),
    Params(12, 2, 2),
  ];
  final caps = [2000, 10000, 50000, 200000, 1000000];

  // warmup (JIT/V8)
  for (var n = 0; n < 30; n++) {
    final l = deal(const Params(8, 1, 2), Rng(99, n, 0));
    if (l != null) Solver(l, 20000).solve();
  }

  print('## Pass 1: per-attempt solver stats (nodeCap=$bigCap, '
      'maxAttempts=$maxAttempts, Levels 1..$levels)');
  print('| config | deals rejected (start Completed) | solved | unsolvable '
      '(exhausted) | capHit | solved nodes p50/p95/max | unsolv nodes p50/max '
      '| µs/node | solve len p50 |');
  print('|---|---|---|---|---|---|---|---|---|');
  final perConfig = <Params, List<List<Attempt?>>>{};
  for (final p in configs) {
    var rejected = 0;
    final sw = Stopwatch();
    final all = <Attempt>[];
    final perLevel = <List<Attempt?>>[];
    final lens = <int>[];
    var totalNodes = 0;
    var totalUs = 0;
    for (var n = 1; n <= levels; n++) {
      final atts = <Attempt?>[];
      for (var i = 0; i < maxAttempts; i++) {
        final rng = Rng(generatorVersion, n, i);
        final l = deal(p, rng);
        if (l == null) {
          rejected++;
          atts.add(null);
          continue;
        }
        sw
          ..reset()
          ..start();
        final out = Solver(l, bigCap).solve();
        sw.stop();
        final a = Attempt(out.res, out.nodes, sw.elapsedMicroseconds / 1000);
        totalNodes += out.nodes;
        totalUs += sw.elapsedMicroseconds;
        atts.add(a);
        all.add(a);
        if (out.res == Res.solved) {
          lens.add(out.length);
          break;
        }
      }
      perLevel.add(atts);
    }
    perConfig[p] = perLevel;
    final sol = all.where((a) => a.res == Res.solved).map((a) => a.nodes).toList();
    final uns =
        all.where((a) => a.res == Res.unsolvable).map((a) => a.nodes).toList();
    final ch = all.where((a) => a.res == Res.capHit).length;
    print('| $p | $rejected | ${sol.length} | ${uns.length} | $ch | '
        '${sol.isEmpty ? '-' : '${pct(sol, .5)}/${pct(sol, .95)}/${pct(sol, 1)}'} | '
        '${uns.isEmpty ? '-' : '${pct(uns, .5)}/${pct(uns, 1)}'} | '
        '${f1(totalUs / (totalNodes == 0 ? 1 : totalNodes))} | '
        '${lens.isEmpty ? '-' : pct(lens, .5)} |');
  }

  print('');
  print('## Pass 2: simulated generate() per Level under node caps '
      '(nodes summed over attempts; ms = nodes × measured µs/node)');
  print('| config | nodeCap | Levels needing >1 attempt | max attempts used | '
      'fail after $maxAttempts | total nodes p50/p95/max |');
  print('|---|---|---|---|---|---|');
  for (final p in configs) {
    for (final capN in caps) {
      final tot = <int>[];
      var multi = 0, maxUsed = 0, fail = 0;
      for (final atts in perConfig[p]!) {
        var nodes = 0, used = 0;
        var ok = false;
        for (final a in atts) {
          used++;
          if (a == null) continue;
          if (a.res == Res.solved && a.nodes <= capN) {
            nodes += a.nodes;
            ok = true;
            break;
          }
          nodes += a.nodes < capN ? a.nodes : capN;
        }
        // NB: attempts beyond those recorded (level solved earlier with bigCap)
        // are unknown; count as failure-to-find within recorded attempts.
        if (!ok) fail++;
        if (used > 1) multi++;
        if (used > maxUsed) maxUsed = used;
        tot.add(nodes);
      }
      print('| $p | $capN | $multi | $maxUsed | $fail | '
          '${pct(tot, .5)}/${pct(tot, .95)}/${pct(tot, 1)} |');
    }
  }

  // ---- Pass 3: real generate() wall time with chosen caps ----
  const chosenCap = 50000;
  const chosenAttempts = 20;
  print('');
  print('## Pass 3: real generate() wall time, nodeCap=$chosenCap, '
      'maxAttempts=$chosenAttempts (+fallback E+1)');
  print('| config | ms p50 | ms p95 | ms max | fallbacks | level hash |');
  print('|---|---|---|---|---|---|');
  for (final p in configs) {
    final times = <double>[];
    var fallbacks = 0;
    var hash = 0x811c9dc5;
    final sw = Stopwatch();
    for (var n = 1; n <= levels; n++) {
      sw
        ..reset()
        ..start();
      Level? got;
      for (var i = 0; i < chosenAttempts && got == null; i++) {
        final l = deal(p, Rng(generatorVersion, n, i));
        if (l == null) continue;
        if (Solver(l, chosenCap).solve().res == Res.solved) got = l;
      }
      if (got == null) {
        fallbacks++;
        final p2 = Params(p.colors, p.perColor, p.empties + 1, p.cap);
        for (var i = 0; i < chosenAttempts && got == null; i++) {
          final l = deal(p2, Rng(generatorVersion, n, 1000 + i));
          if (l == null) continue;
          if (Solver(l, chosenCap).solve().res == Res.solved) got = l;
        }
      }
      sw.stop();
      times.add(sw.elapsedMicroseconds / 1000);
      if (got != null) {
        for (final x in got.cells) hash = mul32(hash ^ x, 0x01000193);
        for (final x in got.queue) hash = mul32(hash ^ x, 0x01000193);
      } else {
        hash = mul32(hash ^ 0xFF, 0x01000193);
      }
    }
    print('| $p | ${f1(pctD(times, .5))} | ${f1(pctD(times, .95))} | '
        '${f1(pctD(times, 1))} | $fallbacks | ${hash.toRadixString(16)} |');
  }

  // ---- Pass 4: Dead End check cost from mid-game states ----
  print('');
  print('## Pass 4: Dead End check (solver from mid-game state after k random '
      'legal Pours), nodeCap=$chosenCap');
  print('| config | k | states | solvable | dead end (proved) | capHit | '
      'ms p50 | ms p95 | ms max |');
  print('|---|---|---|---|---|---|---|---|---|');
  for (final p in [const Params(8, 1, 2), const Params(12, 1, 2), const Params(12, 2, 2)]) {
    for (final k in [5, 15, 30]) {
      final times = <double>[];
      var s = 0, d = 0, chit = 0;
      final sw = Stopwatch();
      for (var n = 1; n <= 100; n++) {
        Level? l;
        for (var i = 0; i < 20 && l == null; i++) {
          l = deal(p, Rng(generatorVersion, n, i));
        }
        if (l == null) continue;
        final play = Solver(l.copy(), 1);
        play.seal();
        final rng = Rng(7, n, k);
        var ok = true;
        for (var step = 0; step < k && ok; step++) {
          // random legal pour (no pruning)
          final legal = <int>[];
          for (var a = 0; a < play.f; a++) {
            if (play.h[a] <= 0) continue;
            for (var b = 0; b < play.f; b++) {
              if (a == b || play.h[b] < 0 || play.h[b] == play.cap) continue;
              final top = play.c[a * play.cap + play.h[a] - 1];
              if (play.h[b] == 0 || play.c[b * play.cap + play.h[b] - 1] == top) {
                legal.add(a * 256 + b);
              }
            }
          }
          if (legal.isEmpty || play.qi == play.q.length) {
            ok = false;
            break;
          }
          final m = legal[rng.below(legal.length)];
          final sI = m ~/ 256, dI = m % 256;
          final hs = play.h[sI], hd = play.h[dI];
          final col = play.c[sI * play.cap + hs - 1];
          var run = 1;
          while (run < hs && play.c[sI * play.cap + hs - 1 - run] == col) run++;
          final amt = run < play.cap - hd ? run : play.cap - hd;
          for (var x = 0; x < amt; x++) {
            play.c[dI * play.cap + hd + x] = col;
            play.c[sI * play.cap + hs - 1 - x] = 0;
          }
          play.h[sI] = hs - amt;
          play.h[dI] = hd + amt;
          play.seal();
        }
        final mid = Level(play.f, play.cap, play.c, play.h, play.q);
        final solver = Solver(mid, chosenCap)..qi = play.qi;
        sw
          ..reset()
          ..start();
        final out = solver.solve();
        sw.stop();
        times.add(sw.elapsedMicroseconds / 1000);
        switch (out.res) {
          case Res.solved:
            s++;
          case Res.unsolvable:
            d++;
          case Res.capHit:
            chit++;
        }
      }
      print('| $p | $k | ${times.length} | $s | $d | $chit | '
          '${f1(pctD(times, .5))} | ${f1(pctD(times, .95))} | '
          '${f1(pctD(times, 1))} |');
    }
  }
}
