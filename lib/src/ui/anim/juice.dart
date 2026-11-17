/// Pour / seal juice (PRD §4.2, §4.3, §5) as a pure view layer over game
/// state: the Game updates instantly on tap; animations here are pure
/// functions of (event, t) in seconds, so they test without frames.
library;

import 'dart:math' as math;

import 'package:flaszki_logic/flaszki_logic.dart' show flaskCapacity;

import '../style/flask_painter.dart' show FluidBand, fluidBands;

/// Ease in-out quad (as in the visual-style prototype).
double easeInOut(double t) =>
    t < .5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;

double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

/// Pour phases (PRD §5): move beside target, pour, return.
class PourTiming {
  PourTiming(this.layers)
    : move = 0.26,
      pour = 0.14 + 0.11 * layers,
      back = 0.24;

  final int layers;
  final double move, pour, back;

  double get total => move + pour + back;

  /// Stream ends; the target's surface wobbles from here.
  double get landsAt => move + pour;

  /// When the [k]-th Layer (0-based) starts falling: Layers spread evenly
  /// over the stream.
  double glugAt(int k) => move + pour * k / layers;
}

/// Peak target-surface wobble, in Layers; decays after landing.
const double wobbleAmplitude = 0.22;
const double _wobbleDecay = 6;

/// One Pour's look at time t (PRD §5 pour juice).
class PourFrame {
  const PourFrame({
    required this.approach,
    required this.tilt,
    this.fullTilt = 0,
    required this.progress,
    required this.source,
    required this.target,
    required this.stream,
    required this.wobble,
    required this.wobblePhase,
    required this.done,
  });

  /// 0 = source at its cell, 1 = beside the target, mouth over it.
  final double approach;

  /// Unsigned tilt (radians); the view signs it toward the target.
  final double tilt;

  /// Tilt at the pouring pose (sets where the source parks).
  final double fullTilt;

  /// Share of the Layers already poured, 0..1.
  final double progress;

  /// Fractional bands to draw in source / target.
  final List<FluidBand> source, target;

  /// Stream thickness factor 0..1 (0 = no stream).
  final double stream;

  /// Target surface wobble amplitude (Layers) and sine phase.
  final double wobble, wobblePhase;
  final bool done;
}

/// A Pour of [layers] Layers of [color] from [from] to [to], begun at
/// [start] (seconds). [sourceBefore]/[targetBefore] are Layer lists before
/// the Pour; the Game is already past it.
class PourAnim {
  PourAnim({
    required this.from,
    required this.to,
    required this.color,
    required this.layers,
    required this.sourceBefore,
    required this.targetBefore,
    required this.start,
    this.leavesWaiting = false,
  }) : timing = PourTiming(layers);

  final int from, to, color, layers;
  final List<int> sourceBefore, targetBefore;

  /// The target ends Completed but not sealed (a waiting Completed Flask).
  final bool leavesWaiting;
  final double start;
  final PourTiming timing;

  /// Set when finished early (a tap involved [from] or [to]).
  double? finishedAt;

  bool involves(int flask) => flask == from || flask == to;

  /// When the Pour lands (or was cut short).
  double get landedAt {
    final natural = start + timing.landsAt;
    final f = finishedAt;
    return f != null && f < natural ? f : natural;
  }

  double get endsAt {
    final natural = start + timing.total;
    final f = finishedAt;
    return f != null && f < natural ? f : natural;
  }

  PourFrame frameAt(double now) {
    final tm = timing;
    final t = now - start;
    final f = finishedAt;
    if ((f != null && now >= f) || now >= start + tm.total) {
      return PourFrame(
        approach: 0,
        tilt: 0,
        progress: 1,
        source: _bands(sourceBefore, -layers.toDouble()),
        target: _bands(targetBefore, layers.toDouble()),
        stream: 0,
        wobble: 0,
        wobblePhase: 0,
        done: true,
      );
    }
    final pm = _clamp01(t / tm.move);
    final pp = _clamp01((t - tm.move) / tm.pour);
    final pb = _clamp01((t - tm.landsAt) / tm.back);
    final k = pb > 0 ? 1 - easeInOut(pb) : easeInOut(pm);
    final moved = layers * pp;
    final left = sourceBefore.length - moved;
    final fullTilt = 1.05 + 0.45 * (1 - left / flaskCapacity);
    final stream = pp <= 0 || pp >= 1
        ? 0.0
        : (pp > .85 ? (1 - pp) / .15 : (pp < .1 ? pp / .1 : 1.0));
    final sinceLand = t - tm.landsAt;
    final wobble = sinceLand < 0
        ? 0.0
        : wobbleAmplitude * math.exp(-_wobbleDecay * sinceLand);
    return PourFrame(
      approach: k,
      tilt: k * fullTilt,
      fullTilt: fullTilt,
      progress: pp,
      source: _bands(sourceBefore, -moved),
      target: _bands(targetBefore, moved),
      stream: stream,
      wobble: wobble,
      wobblePhase: sinceLand < 0 ? 0 : sinceLand * 22,
      done: false,
    );
  }

  /// Bands of [before] with [delta] Layers of [color] added (+) or taken
  /// (−) at the top.
  List<FluidBand> _bands(List<int> before, double delta) {
    final out = fluidBands(before);
    if (delta > 0) {
      if (out.isNotEmpty && out.last.color == color) {
        out.last = FluidBand(color, out.last.layers + delta);
      } else {
        out.add(FluidBand(color, delta));
      }
    } else if (delta < 0 && out.isNotEmpty) {
      final rest = out.last.layers + delta;
      if (rest <= 1e-9) {
        out.removeLast();
      } else {
        out.last = FluidBand(out.last.color, rest);
      }
    }
    return out;
  }
}

/// Seal (PRD §4.3): cork drop, arc fly into the NEXT orb, orb pop.
abstract final class SealTiming {
  static const double cork = 0.28;
  static const double fly = 0.5;
  static const double total = cork + fly;

  /// Gap between cascade seals.
  static const double stagger = 0.25;

  /// NEXT orb pop after a seal lands.
  static const double pop = 0.3;
}

/// One seal's look at time t.
class SealFrame {
  const SealFrame({required this.cork, required this.fly});

  /// Cork drop 0..1 (1 = seated); fly 0..1 (1 = in the orb).
  final double cork, fly;

  /// Scale / opacity while flying (prototype: shrink to 1/4, fade to 0.4).
  double get scale => 1 - fly * 0.75;
  double get opacity => 1 - fly * 0.6;
}

/// Sealed Flask [flask] of [color], [index]-th seal of [pour]'s cascade.
class SealAnim {
  SealAnim(this.flask, this.color, this.pour, this.index);

  final int flask, color, index;
  final PourAnim pour;

  /// Starts when its Pour lands (early if the Pour was cut short).
  double get start => pour.landedAt + index * SealTiming.stagger;
  double get end => start + SealTiming.total;

  SealFrame frameAt(double now) {
    final t = now - start;
    return SealFrame(
      cork: easeInOut(_clamp01(t / SealTiming.cork)),
      fly: easeInOut(_clamp01((t - SealTiming.cork) / SealTiming.fly)),
    );
  }
}

/// Per-event hooks (audio #29 etc.).
enum JuiceCueKind {
  /// Source lifts and moves toward the target ([JuiceCue.flask] = source).
  pourStart,

  /// Stream begins ([JuiceCue.flask] = source).
  streamStart,

  /// One Layer starts falling into the target ([JuiceCue.flask] = target,
  /// [JuiceCue.fill] = its Layers once this one lands).
  glug,

  /// Stream lands / Pour cut short ([JuiceCue.flask] = target).
  pourEnd,

  /// Pour landed leaving the target a waiting Completed Flask (hovering
  /// cork; [JuiceCue.flask] = target).
  waiting,

  /// Cork drops on a sealed Flask.
  seal,

  /// Sealed Flask reaches the NEXT orb; orb pops.
  orbPop,

  /// Undo restored a sealed Flask; board reflows back quickly.
  reverseReflow,
}

class JuiceCue {
  const JuiceCue(this.kind, this.flask, this.color, {this.fill = 0});

  final JuiceCueKind kind;
  final int flask;

  /// Fluid Color id involved (-1 for [JuiceCueKind.reverseReflow]).
  final int color;

  /// [JuiceCueKind.glug]: target Layers after this one (1..capacity).
  final int fill;

  @override
  String toString() => 'JuiceCue(${kind.name}, $flask, $color, $fill)';
}

/// All in-flight juice. Never gates input: the Game is already updated;
/// [pour] and [finishInvolving] cut any animation on the Flasks a tap
/// touches, others keep running (overlap). Time is in seconds.
class Juice {
  Juice({this.onCue});

  /// Fired as each [JuiceCueKind] moment is passed (see [advance]).
  void Function(JuiceCue cue)? onCue;

  final List<PourAnim> _pours = [];
  final List<SealAnim> _seals = [];
  final Set<PourAnim> _streamCued = {}, _endCued = {};
  final Map<PourAnim, int> _glugsCued = {};
  final Set<SealAnim> _sealCued = {};
  double? _popAt;
  double _now = 0;

  bool get isActive =>
      _pours.isNotEmpty ||
      _seals.isNotEmpty ||
      (_popAt != null && _now < _popAt! + SealTiming.pop);

  Iterable<PourAnim> get pours => _pours;
  Iterable<SealAnim> get seals => _seals;

  /// The in-flight Pour [flask] is source or target of.
  PourAnim? pourOf(int flask) {
    for (final p in _pours.reversed) {
      if (p.involves(flask)) return p;
    }
    return null;
  }

  SealAnim? sealOf(int flask) {
    for (final s in _seals) {
      if (s.flask == flask) return s;
    }
    return null;
  }

  /// Sealed Flasks still drawn in the grid (cork, fly) at [now]; the grid
  /// reflows once they are gone.
  Set<int> ghosts(double now) => {
    for (final s in _seals)
      if (now < s.end) s.flask,
  };

  /// NEXT orb pop strength 0..1 at [now].
  double orbPop(double now) {
    final at = _popAt;
    if (at == null || now < at) return 0;
    final k = (now - at) / SealTiming.pop;
    return k >= 1 ? 0 : math.sin(k * math.pi);
  }

  /// A Pour just made in the Game; [sealed] = sealed Flask → Color, in
  /// seal order.
  void pour({
    required int from,
    required int to,
    required int color,
    required int layers,
    required List<int> sourceBefore,
    required List<int> targetBefore,
    Map<int, int> sealed = const {},
    required double now,
  }) {
    finishInvolving(from, now);
    finishInvolving(to, now);
    final p = PourAnim(
      from: from,
      to: to,
      color: color,
      layers: layers,
      sourceBefore: sourceBefore,
      targetBefore: targetBefore,
      start: now,
      leavesWaiting:
          !sealed.containsKey(to) &&
          targetBefore.length + layers == flaskCapacity &&
          targetBefore.every((c) => c == color),
    );
    _pours.add(p);
    var i = 0;
    for (final MapEntry(key: f, value: c) in sealed.entries) {
      _seals.add(SealAnim(f, c, p, i++));
    }
    _cue(JuiceCueKind.pourStart, from, color);
    advance(now);
  }

  /// Ends at once any Pour [flask] is part of (a tap touched it).
  void finishInvolving(int flask, double now) {
    for (final p in _pours.where((p) => p.involves(flask)).toList()) {
      p.finishedAt = now;
      _land(p);
      _drop(p);
    }
  }

  /// Undo / Restart: drop all juice; [restored] = sealed Flasks back on
  /// the board (quick reverse reflow).
  void clear({Iterable<int> restored = const []}) {
    _pours.clear();
    _seals.clear();
    _streamCued.clear();
    _endCued.clear();
    _glugsCued.clear();
    _sealCued.clear();
    _popAt = null;
    for (final f in restored) {
      _cue(JuiceCueKind.reverseReflow, f, -1);
    }
  }

  /// Moves time to [now]: fires due cues, drops finished animations.
  void advance(double now) {
    _now = now;
    for (final p in _pours.toList()) {
      if (!_streamCued.contains(p) && now >= p.start + p.timing.move) {
        _streamCued.add(p);
        _cue(JuiceCueKind.streamStart, p.from, p.color);
      }
      // Layers due before the Pour lands; one cut short plays no more.
      for (var k = _glugsCued[p] ?? 0; k < p.layers; k++) {
        final at = p.start + p.timing.glugAt(k);
        if (now < at || at >= p.landedAt) break;
        _glugsCued[p] = k + 1;
        _cue(
          JuiceCueKind.glug,
          p.to,
          p.color,
          fill: p.targetBefore.length + k + 1,
        );
      }
      if (now >= p.landedAt) _land(p);
      if (now >= p.endsAt) _drop(p);
    }
    for (final s in _seals.toList()) {
      if (!_sealCued.contains(s) && now >= s.start) {
        _sealCued.add(s);
        _cue(JuiceCueKind.seal, s.flask, s.color);
      }
      if (now >= s.end) {
        _seals.remove(s);
        _sealCued.remove(s);
        _popAt = s.end;
        _cue(JuiceCueKind.orbPop, s.flask, s.color);
      }
    }
  }

  void _land(PourAnim p) {
    if (!_endCued.add(p)) return;
    _cue(JuiceCueKind.pourEnd, p.to, p.color);
    if (p.leavesWaiting) _cue(JuiceCueKind.waiting, p.to, p.color);
  }

  void _drop(PourAnim p) {
    _pours.remove(p);
    _streamCued.remove(p);
    _endCued.remove(p);
    _glugsCued.remove(p);
  }

  void _cue(JuiceCueKind kind, int flask, int color, {int fill = 0}) =>
      onCue?.call(JuiceCue(kind, flask, color, fill: fill));
}
