import 'package:flaszki/src/ui/anim/juice.dart';
import 'package:flaszki/src/ui/style/flask_painter.dart';
import 'package:flutter_test/flutter_test.dart';

List<FluidBand> _round(List<FluidBand> bs) => [
  for (final b in bs) FluidBand(b.color, (b.layers * 1e6).round() / 1e6),
];

void main() {
  group('PourTiming (PRD §5: 0.26 + (0.14 + 0.11 × Layers) + 0.24 s)', () {
    test('1 Layer ≈ 0.75 s, 3 Layers ≈ 0.97 s', () {
      expect(PourTiming(1).move, closeTo(0.26, 1e-9));
      expect(PourTiming(1).pour, closeTo(0.25, 1e-9));
      expect(PourTiming(1).back, closeTo(0.24, 1e-9));
      expect(PourTiming(1).total, closeTo(0.75, 1e-9));
      expect(PourTiming(3).total, closeTo(0.97, 1e-9));
      expect(PourTiming(3).landsAt, closeTo(0.73, 1e-9));
    });
  });

  group('PourAnim frame', () {
    // Source [0, 1, 1] pours two 1s into empty target.
    final a = PourAnim(
      from: 0,
      to: 2,
      color: 1,
      layers: 2,
      sourceBefore: const [0, 1, 1],
      targetBefore: const [],
      start: 10,
    );
    final tm = PourTiming(2);

    test('starts at rest, Layers untouched', () {
      final f = a.frameAt(10);
      expect(f.approach, 0);
      expect(f.tilt, 0);
      expect(f.source, const [FluidBand(0, 1), FluidBand(1, 2)]);
      expect(f.target, isEmpty);
      expect(f.stream, 0);
    });

    test('mid-pour: half the Layers moved, stream on', () {
      final f = a.frameAt(10 + tm.move + tm.pour / 2);
      expect(f.approach, 1);
      expect(f.progress, closeTo(0.5, 1e-9));
      expect(_round(f.source), const [FluidBand(0, 1), FluidBand(1, 1)]);
      expect(_round(f.target), const [FluidBand(1, 1)]);
      expect(f.stream, greaterThan(0));
    });

    test('tilts more as the source empties', () {
      final early = a.frameAt(10 + tm.move + 0.01).tilt;
      final late = a.frameAt(10 + tm.landsAt - 0.01).tilt;
      expect(early, greaterThan(1));
      expect(late, greaterThan(early));
    });

    test('lands: target surface wobbles, decaying; done at total', () {
      final w1 = a.frameAt(10 + tm.landsAt + 0.02).wobble;
      final w2 = a.frameAt(10 + tm.landsAt + 0.2).wobble;
      expect(w1, greaterThan(w2));
      expect(w2, greaterThan(0));
      final end = a.frameAt(10 + tm.total);
      expect(end.done, isTrue);
      expect(end.approach, 0);
      expect(end.tilt, 0);
      expect(end.wobble, 0);
      expect(end.source, const [FluidBand(0, 1)]);
      expect(end.target, const [FluidBand(1, 2)]);
    });
  });

  group('Juice timeline', () {
    late List<JuiceCue> cues;
    late Juice juice;
    setUp(() {
      cues = [];
      juice = Juice(onCue: cues.add);
    });

    void pour(
      int from,
      int to,
      double now, {
      int layers = 1,
      List<int> sealed = const [],
    }) => juice.pour(
      from: from,
      to: to,
      color: 3,
      layers: layers,
      sourceBefore: List.filled(layers, 3),
      targetBefore: const [],
      sealed: {for (final s in sealed) s: 3},
      now: now,
    );

    List<String> kinds() => [for (final c in cues) '${c.kind.name}:${c.flask}'];

    test('cues fire in order as time passes: start, stream, end', () {
      pour(0, 1, 0);
      expect(kinds(), ['pourStart:0']);
      juice.advance(0.1);
      expect(kinds(), ['pourStart:0']);
      juice.advance(0.3);
      expect(kinds(), ['pourStart:0', 'streamStart:0']);
      juice.advance(0.6);
      expect(kinds(), ['pourStart:0', 'streamStart:0', 'pourEnd:1']);
      expect(juice.isActive, isTrue, reason: 'still returning');
      juice.advance(0.75);
      expect(juice.isActive, isFalse);
      expect(juice.pourOf(0), isNull);
    });

    test('Pours on other Flasks overlap', () {
      pour(0, 1, 0);
      pour(2, 3, 0.1);
      juice.advance(0.4);
      expect(juice.pourOf(0)!.frameAt(0.4).progress, greaterThan(0));
      expect(juice.pourOf(3)!.frameAt(0.4).approach, greaterThan(0));
    });

    test('a new Pour on an animating Flask finishes the old one first', () {
      pour(0, 1, 0);
      pour(1, 2, 0.1);
      expect(kinds(), ['pourStart:0', 'pourEnd:1', 'pourStart:1']);
      expect(juice.pourOf(0), isNull);
      expect(juice.pourOf(1)!.from, 1);
    });

    test('finishInvolving cuts a Pour short; end cue fires once', () {
      pour(0, 1, 0);
      juice.finishInvolving(0, 0.05);
      juice.advance(1);
      expect(kinds(), ['pourStart:0', 'pourEnd:1']);
      expect(juice.isActive, isFalse);
    });

    test('seal: Flask stays a ghost from land through cork + fly; '
        'orb pops at the end', () {
      pour(0, 1, 0, sealed: [1]);
      final tm = PourTiming(1);
      expect(juice.ghosts(0), {1});
      juice.advance(tm.landsAt + 0.01);
      expect(kinds().last, 'seal:1');
      final s = juice.sealOf(1)!;
      expect(s.frameAt(tm.landsAt + 0.01).fly, 0);
      expect(s.frameAt(tm.landsAt + SealTiming.cork + 0.2).fly, greaterThan(0));
      final end = tm.landsAt + SealTiming.total;
      juice.advance(end + 0.01);
      expect(kinds().last, 'orbPop:1');
      expect(juice.ghosts(end + 0.01), isEmpty);
      expect(juice.orbPop(end + 0.05), greaterThan(0));
      expect(juice.orbPop(end + 1), 0);
    });

    test('cascade seals are staggered', () {
      pour(0, 1, 0, sealed: [1, 4]);
      final a = juice.sealOf(1)!.start, b = juice.sealOf(4)!.start;
      expect(b - a, closeTo(SealTiming.stagger, 1e-9));
    });

    test('early-finished Pour starts its seal at once', () {
      pour(0, 1, 0, sealed: [1]);
      juice.finishInvolving(1, 0.1);
      expect(juice.sealOf(1)!.start, closeTo(0.1, 1e-9));
    });

    test('clear (Undo/Restart) drops everything; reverse reflow cue', () {
      pour(0, 1, 0, sealed: [1]);
      juice.clear(restored: [1]);
      expect(juice.isActive, isFalse);
      expect(juice.ghosts(0.1), isEmpty);
      expect(kinds().last, 'reverseReflow:1');
    });
  });
}
