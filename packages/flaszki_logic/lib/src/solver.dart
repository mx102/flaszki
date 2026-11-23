/// Queue-order solver (ADR 0002): depth-first search with move ordering,
/// pruning, a node cap and an order-independent visited set.
library;

import 'dart:typed_data';

import 'board_state.dart';
import 'game.dart' show Pour;
import 'level.dart';
import 'prng.dart' show fmix32;

/// Default node cap (ADR 0002); part of the versioned generator algorithm.
const int defaultNodeCap = 50000;

/// Solver verdict.
enum Solvability {
  /// A solution was found.
  solvable,

  /// Search exhausted without a solution (in [VisitedKey.exact] mode: a
  /// proven Dead End).
  unsolvable,

  /// Node cap hit before a verdict.
  unknown,
}

/// How visited states are keyed.
enum VisitedKey {
  /// Order-independent 52-bit hash in `Set<int>` (generator mode). A
  /// collision can only make a solvable state look unsolvable.
  hash,

  /// Exact canonical key (Dead End mode): no false "unsolvable".
  exact,
}

/// Solver result plus difficulty metrics.
class SolveReport {
  const SolveReport(
    this.result,
    this.nodes,
    this.mergeLowerBound,
    this.solution,
  );

  final Solvability result;

  /// States expanded (≤ node cap).
  final int nodes;

  /// `B − C`: same-Color runs on board minus remaining Goal Queue entries;
  /// a lower bound on merging Pours.
  final int mergeLowerBound;

  /// Pours (stable Flask indices) from the input state to Solved; null
  /// unless [result] is [Solvability.solvable]. Not necessarily shortest.
  final List<Pour>? solution;

  /// Length of [solution]; 0 when not solvable.
  int get solutionLength => solution?.length ?? 0;
}

/// Solves [state] under queue rules: only a Completed Flask of the head
/// Color is sealed (lowest index first, cascading). Deterministic; capped by
/// node count, never wall-clock time.
SolveReport solve(
  BoardState state, {
  int nodeCap = defaultNodeCap,
  VisitedKey visited = VisitedKey.hash,
}) => _Solver(state, visited).run(nodeCap);

const int _cap = flaskCapacity;
const int _two52 = 0x10000000000000;
const int _two20 = 0x100000;

class _Frame {
  _Frame(this.moves);

  final List<int> moves;
  int next = 0;

  // Undo info for the move currently applied from this frame (src < 0: none).
  int src = -1, dst = 0, amount = 0, color = 0, queueBefore = 0;
  List<int> sealed = const [];
}

class _Solver {
  _Solver(BoardState s, this.mode)
    : n = s.flasks.length,
      cells = Uint8List(s.flasks.length * _cap),
      heights = Int32List(s.flasks.length),
      queue = s.goalQueue {
    for (var i = 0; i < n; i++) {
      if (!s.isOnBoard(i)) {
        heights[i] = -1;
        continue;
      }
      final layers = s.flasks[i].layers;
      heights[i] = layers.length;
      for (var j = 0; j < layers.length; j++) {
        cells[i * _cap + j] = layers[j] + 1; // 0 = empty slot
      }
    }
  }

  final VisitedKey mode;
  final int n;
  final Uint8List cells;
  final Int32List heights; // -1 = sealed
  final List<int> queue;
  int qi = 0;

  final _hashes = <int>{};
  final _exact = <String>{};
  final _codes = <int>[];

  bool _completed(int i) => heights[i] == _cap && _uniform(i);

  /// All Layers of Flask [i] one Color (true when empty).
  bool _uniform(int i) {
    final b = i * _cap;
    for (var j = 1; j < heights[i]; j++) {
      if (cells[b + j] != cells[b]) return false;
    }
    return true;
  }

  /// Layers in the top same-Color run of non-empty Flask [s].
  int _topRun(int s) {
    final hs = heights[s];
    final col = cells[s * _cap + hs - 1];
    var run = 1;
    while (run < hs && cells[s * _cap + hs - 1 - run] == col) {
      run++;
    }
    return run;
  }

  /// Seals head-Color Completed Flasks (cascade); returns sealed indices.
  List<int> _seal() {
    List<int>? sealed;
    while (qi < queue.length) {
      final head = queue[qi] + 1;
      var hit = -1;
      for (var i = 0; i < n; i++) {
        if (heights[i] == _cap && cells[i * _cap] == head && _completed(i)) {
          hit = i;
          break;
        }
      }
      if (hit < 0) break;
      (sealed ??= []).add(hit);
      heights[hit] = -1;
      qi++;
    }
    return sealed ?? const [];
  }

  int _code(int i) {
    var code = 0;
    for (var j = 0; j < heights[i]; j++) {
      code = code * 13 + cells[i * _cap + j];
    }
    return code; // < 13^4, unique per content (digits 1–12, length implied)
  }

  /// Marks the current state visited; false if it already was.
  bool _visit() {
    if (mode == VisitedKey.hash) {
      var k = 0;
      for (var i = 0; i < n; i++) {
        if (heights[i] < 0) continue;
        final code = _code(i);
        final a = fmix32(code + 1);
        final b = fmix32(code ^ 0x5bd1e995) % _two20;
        k = (k + a * _two20 + b) % _two52; // stays < 2^53
      }
      return _hashes.add((k + fmix32(qi + 77)) % _two52);
    }
    _codes.clear();
    for (var i = 0; i < n; i++) {
      if (heights[i] >= 0) _codes.add(_code(i));
    }
    _codes
      ..sort()
      ..add(qi);
    return _exact.add(String.fromCharCodes(_codes));
  }

  /// Legal, unpruned moves as `prio << 16 | src << 8 | dst`, best first.
  List<int> _moves() {
    final moves = <int>[];
    final head = queue[qi] + 1;
    for (var s = 0; s < n; s++) {
      final hs = heights[s];
      if (hs <= 0 || _completed(s)) continue; // prune: out of Completed Flask
      final col = cells[s * _cap + hs - 1];
      final run = _topRun(s);
      final uniform = run == hs;
      var triedEmpty = false;
      for (var d = 0; d < n; d++) {
        if (d == s) continue;
        final hd = heights[d];
        if (hd < 0 || hd == _cap) continue;
        int prio;
        if (hd == 0) {
          // prune: single-Color Flask into empty; >1 empty target
          if (uniform || triedEmpty) continue;
          triedEmpty = true;
          prio = 1;
        } else {
          if (cells[d * _cap + hd - 1] != col) continue;
          final amount = run < _cap - hd ? run : _cap - hd;
          prio = (col == head && hd + amount == _cap && _uniform(d)) ? 3 : 2;
        }
        moves.add((prio << 16) | (s << 8) | d);
      }
    }
    moves.sort((a, b) => b - a);
    return moves;
  }

  void _apply(_Frame f, int move) {
    final s = (move >> 8) & 0xFF, d = move & 0xFF;
    final hs = heights[s], hd = heights[d];
    final col = cells[s * _cap + hs - 1];
    final run = _topRun(s);
    final amount = run < _cap - hd ? run : _cap - hd;
    for (var k = 0; k < amount; k++) {
      cells[d * _cap + hd + k] = col;
      cells[s * _cap + hs - 1 - k] = 0;
    }
    heights[s] = hs - amount;
    heights[d] = hd + amount;
    f
      ..src = s
      ..dst = d
      ..amount = amount
      ..color = col
      ..queueBefore = qi
      ..sealed = _seal();
  }

  void _undo(_Frame f) {
    for (final i in f.sealed) {
      heights[i] = _cap;
    }
    qi = f.queueBefore;
    final s = f.src, d = f.dst;
    final hs = heights[s], hd = heights[d];
    for (var k = 0; k < f.amount; k++) {
      cells[d * _cap + hd - 1 - k] = 0;
      cells[s * _cap + hs + k] = f.color;
    }
    heights[s] = hs + f.amount;
    heights[d] = hd - f.amount;
    f.src = -1;
  }

  int _mergeLowerBound() {
    var blocks = 0;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < heights[i]; j++) {
        if (j == 0 || cells[i * _cap + j] != cells[i * _cap + j - 1]) blocks++;
      }
    }
    return blocks - (queue.length - qi);
  }

  SolveReport run(int nodeCap) {
    _seal();
    final bound = _mergeLowerBound();
    if (qi == queue.length) {
      return SolveReport(Solvability.solvable, 0, bound, const []);
    }
    if (nodeCap < 1) return SolveReport(Solvability.unknown, 0, bound, null);
    _visit();
    var nodes = 1;
    final frames = [_Frame(_moves())];
    while (frames.isNotEmpty) {
      final top = frames.last;
      if (top.src >= 0) _undo(top);
      if (top.next == top.moves.length) {
        frames.removeLast();
        continue;
      }
      _apply(top, top.moves[top.next++]);
      if (qi == queue.length) {
        return SolveReport(Solvability.solvable, nodes, bound, [
          for (final f in frames) Pour(f.src, f.dst),
        ]);
      }
      if (!_visit()) continue;
      if (nodes >= nodeCap) {
        return SolveReport(Solvability.unknown, nodes, bound, null);
      }
      nodes++;
      frames.add(_Frame(_moves()));
    }
    return SolveReport(Solvability.unsolvable, nodes, bound, null);
  }
}
