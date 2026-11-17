import 'dart:async';

import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../audio/game_audio.dart';
import '../l10n.dart';
import '../play/board_layout.dart';
import '../play/dead_end_checker.dart';
import '../play/goal_queue_view.dart';
import '../play/level_sequencer.dart';
import '../play/play_controller.dart';
import '../play/restart_arm.dart';
import 'anim/juice.dart';
import 'board_view.dart';
import 'bottom_bar.dart';
import 'dead_end_banner.dart';
import 'goal_queue_strip.dart';
import 'style/style_a.dart';

/// Solved overlay auto-advance delay (PRD §4.5).
const solvedAutoAdvance = Duration(seconds: 2);

/// Board padding around the grid.
const double boardPadding = 8;

/// The Level screen (PRD §4): Goal Queue strip, board, bottom bar, Solved
/// overlay. Opens straight into Level [startLevel].
///
/// Seams: [onLevelStarted]/[onGameChanged]/[onSolved] for save (#24), audio and
/// Dead End (#25); [onOpenSettings] for the Settings sheet (#28);
/// [onJuice] for per-event animation cues (audio #29).
class LevelScreen extends StatefulWidget {
  const LevelScreen({
    super.key,
    required this.levelSource,
    this.startLevel = 1,
    this.initialGame,
    this.onLevelStarted,
    this.onGameChanged,
    this.onSolved,
    this.onOpenSettings,
    this.deadEndRunner,
    this.audio,
    this.onJuice,
  });

  final LevelSource levelSource;
  final int startLevel;

  /// Saved Level [startLevel] in progress (#24); else it is generated.
  final Game? initialGame;

  /// Level N is in play with this [Game] (fresh, or restored later by #24).
  final void Function(int levelNumber, Game game)? onLevelStarted;

  /// Called after every tap effect that changed the Game (Pour, Undo,
  /// Restart).
  final void Function(Game game)? onGameChanged;
  final void Function(int levelNumber)? onSolved;
  final VoidCallback? onOpenSettings;

  /// Dead End check (#25); default [checkDeadEndOffThread].
  final DeadEndRunner? deadEndRunner;

  /// Sound effects (#29); `null` = silent.
  final GameAudio? audio;

  /// Pour / seal juice moments (pour start / stream / end, seal, orb pop,
  /// reverse reflow) as they play; see [JuiceCueKind].
  final void Function(JuiceCue cue)? onJuice;

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen>
    with SingleTickerProviderStateMixin {
  late final LevelSequencer _seq = LevelSequencer(
    widget.levelSource,
    startLevel: widget.startLevel,
  );
  PlayController? _play;
  int _levelNumber = 0;
  int _flaskCount = 0;

  final Map<int, int> _shakes = {};
  final RestartArm _arm = RestartArm();
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _armTimer;
  Timer? _solvedTimer;
  bool _advancing = false;
  bool _built = false;

  // Juice (#27): a view layer; the Game is already updated on tap.
  late final Juice _juice = Juice(
    onCue: (c) {
      widget.audio?.cue(c);
      widget.onJuice?.call(c);
    },
  );
  late final Ticker _ticker = createTicker(_tick);
  double _now = 0, _base = 0;
  Duration _reflow = reflowDuration;
  final GlobalKey _orbKey = GlobalKey(), _boardKey = GlobalKey();
  late final DeadEndChecker _deadEnd = DeadEndChecker(
    run: widget.deadEndRunner,
    revealDelay: reflowDuration,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );

  @override
  void initState() {
    super.initState();
    final restored = widget.initialGame;
    if (restored == null) {
      _seq.start().then(_begin);
    } else {
      _seq.resume();
      _beginGame(restored);
    }
  }

  @override
  void dispose() {
    _armTimer?.cancel();
    _solvedTimer?.cancel();
    _deadEnd.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _update(VoidCallback f) => _built ? setState(f) : f();

  void _begin(GeneratedLevel g) => _beginGame(Game(g.level));

  void _beginGame(Game game) {
    if (!mounted) return;
    _update(() {
      _play = PlayController(game);
      _levelNumber = _seq.levelNumber;
      _flaskCount = game.level.flasks.length;
      _shakes.clear();
      _arm.disarm();
      _advancing = false;
      _solvedTimer?.cancel();
      _solvedTimer = null;
      _juice.clear();
    });
    _deadEnd.stateChanged(_play!.game.state);
    widget.onLevelStarted?.call(_levelNumber, _play!.game);
  }

  void _tapFlask(int i) {
    final play = _play;
    if (play == null) return;
    final before = play.state;
    _juice.finishInvolving(i, _now);
    final effect = play.tapFlask(i);
    widget.audio?.tap(effect);
    _deadEnd.input();
    setState(() {
      if (effect is Rejected) {
        _shakes[effect.target] = (_shakes[effect.target] ?? 0) + 1;
      }
      if (effect is Poured) _startPour(before, effect);
    });
    if (effect is Poured) {
      _deadEnd.stateChanged(play.game.state, afterPour: true);
      widget.onGameChanged?.call(play.game);
      if (play.isSolved) _solved();
    }
  }

  void _startPour(BoardState before, Poured p) {
    final after = _play!.state;
    final source = before.flasks[p.from].layers;
    _reflow = reflowDuration;
    _juice.pour(
      from: p.from,
      to: p.to,
      color: source.last,
      layers: p.outcome.layersMoved,
      sourceBefore: source,
      targetBefore: before.flasks[p.to].layers,
      sealed: {for (final s in p.outcome.sealed) s: after.flasks[s].layers[0]},
      now: _now,
    );
    if (!_ticker.isActive) {
      _base = _now;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    _now = _base + elapsed.inMicroseconds / 1e6;
    _juice.advance(_now);
    if (!_juice.isActive) _ticker.stop();
    setState(() {});
    _armSolved();
  }

  /// Undo / Restart moved the Game back: drop juice; sealed Flasks back on
  /// the board reflow in quickly.
  void _rewound(BoardState before) {
    final after = _play!.state;
    final restored = [
      for (var i = 0; i < after.flasks.length; i++)
        if (after.isOnBoard(i) && !before.isOnBoard(i)) i,
    ];
    _juice.clear(restored: restored);
    _reflow = restored.isEmpty ? reflowDuration : reverseReflowDuration;
    if (_ticker.isActive) _ticker.stop();
  }

  /// NEXT orb centre in board coordinates (seal fly-in target).
  Offset? _orbInBoard() {
    final orb = _orbKey.currentContext?.findRenderObject();
    final board = _boardKey.currentContext?.findRenderObject();
    if (orb is! RenderBox || board is! RenderBox) return null;
    if (!orb.hasSize || !board.hasSize) return null;
    return board.globalToLocal(orb.localToGlobal(orb.size.center(Offset.zero)));
  }

  void _solved() {
    widget.onSolved?.call(_levelNumber);
    _solvedTimer?.cancel();
    _solvedTimer = null;
    _armSolved();
  }

  /// "Solved" shows (and its auto-advance counts) once the last seal has
  /// flown into the orb, so the overlay never hides the juice.
  void _armSolved() {
    final play = _play;
    if (play == null || !play.isSolved || _solvedTimer != null) return;
    if (_juice.isActive) return;
    _solvedTimer = Timer(solvedAutoAdvance, _advance);
    widget.audio?.solved(); // the overlay shows from this frame
  }

  void _advance() {
    if (_advancing) return;
    _advancing = true;
    _solvedTimer?.cancel();
    _seq.advance().then(_begin);
  }

  void _undo() => _rewind((play) {
    if (play.undo()) widget.audio?.undo();
  });

  void _restart() {
    if (_play == null) return;
    _armTimer?.cancel();
    if (_arm.press(_clock.elapsed)) {
      _rewind((play) => play.restart());
    } else {
      setState(() {});
      // Timer disarms too, so fake-time tests and real time agree.
      _armTimer = Timer(_arm.window, () {
        if (mounted) setState(_arm.disarm);
      });
    }
  }

  /// Banner Restart: no confirm (PRD §4.4).
  void _restartNow() => _rewind((play) => play.restart());

  /// Undo / Restart: [change] moves the Game back; disarms Restart, drops
  /// juice, rechecks Dead End, saves.
  void _rewind(void Function(PlayController play) change) {
    final play = _play;
    if (play == null) return;
    _armTimer?.cancel();
    final before = play.state;
    setState(() {
      _arm.disarm();
      change(play);
      _rewound(before);
    });
    _deadEnd.stateChanged(play.game.state);
    widget.onGameChanged?.call(play.game);
  }

  bool _back() {
    final handled = _play?.back() ?? false;
    if (handled) setState(() {});
    return handled;
  }

  @override
  Widget build(BuildContext context) {
    _built = true;
    final play = _play;
    return PopScope(
      canPop: play?.selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            _back();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: play == null
                ? const SizedBox.expand()
                : Stack(
                    children: [
                      Column(
                        children: [
                          GoalQueueStrip(
                            // Seals still flying count as not yet taken.
                            queue: GoalQueueView.of([
                              for (final s in _juice.seals)
                                if (_now < s.end) s.color,
                              ...play.state.goalQueue,
                            ]),
                            nextOrbKey: _orbKey,
                            pop: _juice.orbPop(_now),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(boardPadding),
                              child: LayoutBuilder(
                                builder: (context, box) => BoardView(
                                  key: _boardKey,
                                  state: play.state,
                                  juice: _juice,
                                  now: _now,
                                  reflow: _reflow,
                                  orbCenter: _orbInBoard,
                                  metrics: fitBoard(
                                    _flaskCount,
                                    box.maxWidth,
                                    box.maxHeight,
                                  ),
                                  selected: play.selected,
                                  shakes: _shakes,
                                  onTapFlask: _tapFlask,
                                  onTapEmpty: () {
                                    if (play.tapEmpty()) setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                          BottomBar(
                            levelNumber: _levelNumber,
                            canUndo: play.canUndo,
                            restartArmed: _arm.isArmed(_clock.elapsed),
                            onUndo: _undo,
                            onRestart: _restart,
                            onSettings: widget.onOpenSettings,
                          ),
                        ],
                      ),
                      // Shown once the Pour/seal animation ends (§4.4).
                      if (_deadEnd.showing &&
                          !play.isSolved &&
                          !_juice.isActive)
                        Positioned(
                          left: boardPadding,
                          right: boardPadding,
                          bottom: bottomBarHeight + boardPadding,
                          child: DeadEndBanner(
                            onUndo: _undo,
                            onRestart: _restartNow,
                          ),
                        ),
                      if (play.isSolved && !_juice.isActive)
                        Positioned.fill(child: _SolvedOverlay(onTap: _advance)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// "Solved" over the board; tap anywhere advances (PRD §4.5).
class _SolvedOverlay extends StatelessWidget {
  const _SolvedOverlay({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('solved'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: ColoredBox(
      color: StyleA.scrim,
      child: Align(
        alignment: const Alignment(0, -0.16),
        child: Text(
          context.l10n.solved,
          style: StyleA.serifItalic.copyWith(
            fontSize: 48,
            color: StyleA.solved,
          ),
        ),
      ),
    ),
  );
}
