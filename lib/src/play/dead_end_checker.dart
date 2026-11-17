import 'dart:async';

import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb;

/// Runs the Dead End check for a state; may run off the UI thread.
typedef DeadEndRunner = Future<bool> Function(BoardState state);

/// Waits [d]; injectable so tests control time.
typedef Wait = Future<void> Function(Duration d);

bool _isDeadEnd(BoardState s) => isDeadEnd(s);

/// Default [DeadEndRunner]: `compute` runs the exact-mode solver in an
/// isolate on native and on the main thread on web (PRD §4.4).
Future<bool> checkDeadEndOffThread(BoardState s) =>
    compute(_isDeadEnd, s, debugLabel: 'deadEnd');

/// Default idle delay: web runs the check on the main thread, so only after
/// 1 s without input; native starts at once (isolate).
const Duration defaultDeadEndIdle = kIsWeb
    ? Duration(seconds: 1)
    : Duration.zero;

/// Dead End hint scheduling (PRD §4.4): after every state change, check the
/// new state; show the banner only on a proven Dead End, and only once
/// [revealDelay] (the Pour/seal animation) has passed. Results for a state
/// that is no longer current are dropped. Never blocks the caller.
class DeadEndChecker {
  DeadEndChecker({
    DeadEndRunner? run,
    Wait? wait,
    this.idleDelay = defaultDeadEndIdle,
    this.revealDelay = Duration.zero,
    this.onChanged,
  }) : _run = run ?? checkDeadEndOffThread,
       _injectedWait = wait;

  final DeadEndRunner _run;
  final Wait? _injectedWait;
  final Set<Timer> _timers = {};

  /// Quiet time (no input) before the check starts.
  final Duration idleDelay;

  /// Minimum time from the state change until the banner may appear.
  final Duration revealDelay;

  /// Called whenever [showing] changes.
  final void Function()? onChanged;

  int _generation = 0;
  int _inputs = 0;
  bool _showing = false;
  bool _disposed = false;

  /// Whether the Dead End banner should be shown for the current state.
  bool get showing => _showing;

  /// The current state changed to [state]. Pass [afterPour] when [state]
  /// follows the previous one by a Pour: a Pour from a Dead End always
  /// leads to a Dead End, so a shown banner stays without a new check.
  void stateChanged(BoardState state, {bool afterPour = false}) {
    if (_disposed) return;
    final gen = ++_generation;
    if (afterPour && _showing) return;
    _set(false);
    _check(gen, state);
  }

  /// Any player input (e.g. a select tap): postpones a check still waiting
  /// for [idleDelay] of quiet.
  void input() => _inputs++;

  /// Stops notifying; pending results are dropped.
  void dispose() {
    _disposed = true;
    _generation++;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Default wait: a Timer that [dispose] cancels (the Future then never
  /// completes), so nothing outlives the screen.
  Future<void> _wait(Duration d) {
    final injected = _injectedWait;
    if (injected != null) return injected(d);
    if (d == Duration.zero) return Future.value();
    final c = Completer<void>();
    late final Timer t;
    t = Timer(d, () {
      _timers.remove(t);
      c.complete();
    });
    _timers.add(t);
    return c.future;
  }

  bool _stale(int gen) => _disposed || gen != _generation;

  Future<void> _check(int gen, BoardState state) async {
    final reveal = _wait(revealDelay);
    bool dead;
    try {
      int inputs;
      do {
        inputs = _inputs;
        await _wait(idleDelay);
        if (_stale(gen)) return;
      } while (inputs != _inputs);
      dead = await _run(state);
      await reveal;
    } catch (_) {
      return; // A failed check is no hint.
    }
    if (_stale(gen)) return;
    _set(dead);
  }

  void _set(bool v) {
    if (_showing == v) return;
    _showing = v;
    onChanged?.call();
  }
}
