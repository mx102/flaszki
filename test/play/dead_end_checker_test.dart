import 'dart:async';

import 'package:flaszki/src/play/dead_end_checker.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controllable fake time + solver: every wait and every check is a pending
/// Completer the test resolves by hand.
class Harness {
  final waits = <(Duration, Completer<void>)>[];
  final checks = <(BoardState, Completer<bool>)>[];
  int notified = 0;

  late final DeadEndChecker checker = make();

  DeadEndChecker make({
    Duration idleDelay = Duration.zero,
    Duration revealDelay = Duration.zero,
  }) => DeadEndChecker(
    run: (s) {
      final c = Completer<bool>();
      checks.add((s, c));
      return c.future;
    },
    wait: (d) {
      if (d == Duration.zero) return Future.value();
      final c = Completer<void>();
      waits.add((d, c));
      return c.future;
    },
    idleDelay: idleDelay,
    revealDelay: revealDelay,
    onChanged: () => notified++,
  );
}

BoardState board(List<List<int>> flasks, List<int> queue) =>
    BoardState.initial(Level(flasks: flasks.map(Flask.new), goalQueue: queue));

final a = board(
  [
    [0, 0, 1],
    [1, 1, 0],
    [],
  ],
  [0, 1],
);
final b = a.pour(0, 2).state;

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a proven Dead End shows the banner and notifies', () async {
    final h = Harness();
    h.checker.stateChanged(a);
    await settle();
    expect(h.checks.single.$1, same(a));
    expect(h.checker.showing, isFalse);
    h.checks.single.$2.complete(true);
    await settle();
    expect(h.checker.showing, isTrue);
    expect(h.notified, 1);
  });

  test('not a Dead End (or unknown) shows nothing', () async {
    final h = Harness();
    h.checker.stateChanged(a);
    await settle();
    h.checks.single.$2.complete(false);
    await settle();
    expect(h.checker.showing, isFalse);
    expect(h.notified, 0);
  });

  test('a result for a state no longer current is dropped', () async {
    final h = Harness();
    h.checker.stateChanged(a);
    await settle();
    h.checker.stateChanged(b);
    await settle();
    h.checks[0].$2.complete(true); // stale: for a
    await settle();
    expect(h.checker.showing, isFalse);
    h.checks[1].$2.complete(false);
    await settle();
    expect(h.checker.showing, isFalse);
  });

  test('a failed check shows nothing', () async {
    final h = Harness();
    h.checker.stateChanged(a);
    await settle();
    h.checks.single.$2.completeError(StateError('isolate died'));
    await settle();
    expect(h.checker.showing, isFalse);
  });

  test('banner hides at once when the state changes (Undo/Restart)', () async {
    final h = Harness();
    h.checker.stateChanged(b);
    await settle();
    h.checks.single.$2.complete(true);
    await settle();
    h.checker.stateChanged(a);
    expect(h.checker.showing, isFalse);
    expect(h.notified, 2);
  });

  test('a Pour from a shown Dead End keeps the banner, no re-check', () async {
    final h = Harness();
    h.checker.stateChanged(a);
    await settle();
    h.checks.single.$2.complete(true);
    await settle();
    h.checker.stateChanged(b, afterPour: true);
    await settle();
    expect(h.checker.showing, isTrue);
    expect(h.checks, hasLength(1));
    expect(h.notified, 1);
  });

  test('banner waits for the Pour/seal animation (reveal delay)', () async {
    final h = Harness();
    final c = h.make(revealDelay: const Duration(milliseconds: 250));
    c.stateChanged(a);
    await settle();
    h.checks.single.$2.complete(true);
    await settle();
    expect(c.showing, isFalse);
    final (d, reveal) = h.waits.single;
    expect(d, const Duration(milliseconds: 250));
    reveal.complete();
    await settle();
    expect(c.showing, isTrue);
  });

  test('web: check starts only after idle delay without input', () async {
    final h = Harness();
    final c = h.make(idleDelay: const Duration(seconds: 1));
    c.stateChanged(a);
    await settle();
    expect(h.checks, isEmpty);
    c.input(); // e.g. a select tap
    h.waits.single.$2.complete();
    await settle();
    expect(h.checks, isEmpty, reason: 'input restarts the idle wait');
    expect(h.waits, hasLength(2));
    h.waits[1].$2.complete();
    await settle();
    expect(h.checks.single.$1, same(a));
  });

  test(
    'web: a state change during the idle wait skips the old check',
    () async {
      final h = Harness();
      final c = h.make(idleDelay: const Duration(seconds: 1));
      c.stateChanged(a);
      await settle();
      c.stateChanged(b);
      await settle();
      for (final w in h.waits) {
        w.$2.complete();
      }
      await settle();
      expect(h.checks.single.$1, same(b));
    },
  );

  test('after dispose results are dropped and nothing notifies', () async {
    final h = Harness();
    h.checker.stateChanged(a);
    await settle();
    h.checker.dispose();
    h.checks.single.$2.complete(true);
    await settle();
    expect(h.notified, 0);
    h.checker.stateChanged(b);
    expect(h.checks, hasLength(1));
  });
}
