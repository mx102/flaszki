import 'dart:async';

import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../play/board_layout.dart';
import '../play/dead_end_checker.dart';
import '../play/goal_queue_view.dart';
import '../play/level_sequencer.dart';
import '../play/play_controller.dart';
import '../play/restart_arm.dart';
import 'board_view.dart';
import 'bottom_bar.dart';
import 'dead_end_banner.dart';
import 'goal_queue_strip.dart';
import 'placeholder_style.dart';

/// Solved overlay auto-advance delay (PRD §4.5).
const solvedAutoAdvance = Duration(seconds: 2);

/// Board padding around the grid.
const double boardPadding = 8;

/// The Level screen (PRD §4): Goal Queue strip, board, bottom bar, Solved
/// overlay. Opens straight into Level [startLevel].
///
/// Seams: [onLevelStarted]/[onPour]/[onSolved] for save (#24), audio and
/// Dead End (#25); [onOpenSettings] for the Settings sheet (#28).
class LevelScreen extends StatefulWidget {
  const LevelScreen({
    super.key,
    required this.levelSource,
    this.startLevel = 1,
    this.initialGame,
    this.onLevelStarted,
    this.onPour,
    this.onSolved,
    this.onOpenSettings,
    this.deadEndRunner,
  });

  final LevelSource levelSource;
  final int startLevel;

  /// Saved Level [startLevel] in progress (#24); else it is generated.
  final Game? initialGame;

  /// Level N is in play with this [Game] (fresh, or restored later by #24).
  final void Function(int levelNumber, Game game)? onLevelStarted;

  /// Called after every tap effect that changed the Game (Pour, Undo,
  /// Restart).
  final void Function(Game game)? onPour;
  final void Function(int levelNumber)? onSolved;
  final VoidCallback? onOpenSettings;

  /// Dead End check (#25); default [checkDeadEndOffThread].
  final DeadEndRunner? deadEndRunner;

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
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
    });
    _deadEnd.stateChanged(_play!.game.state);
    widget.onLevelStarted?.call(_levelNumber, _play!.game);
  }

  void _tapFlask(int i) {
    final play = _play;
    if (play == null) return;
    final effect = play.tapFlask(i);
    _deadEnd.input();
    setState(() {
      if (effect is Rejected) {
        _shakes[effect.target] = (_shakes[effect.target] ?? 0) + 1;
      }
    });
    if (effect is Poured) {
      _deadEnd.stateChanged(play.game.state, afterPour: true);
      widget.onPour?.call(play.game);
      if (play.isSolved) _solved();
    }
  }

  void _solved() {
    widget.onSolved?.call(_levelNumber);
    _solvedTimer?.cancel();
    _solvedTimer = Timer(solvedAutoAdvance, _advance);
  }

  void _advance() {
    if (_advancing) return;
    _advancing = true;
    _solvedTimer?.cancel();
    _seq.advance().then(_begin);
  }

  void _undo() {
    final play = _play;
    if (play == null) return;
    setState(() {
      _arm.disarm();
      play.undo();
    });
    _deadEnd.stateChanged(play.game.state);
    widget.onPour?.call(play.game);
  }

  void _restart() {
    final play = _play;
    if (play == null) return;
    _armTimer?.cancel();
    if (_arm.press(_clock.elapsed)) {
      setState(play.restart);
      _deadEnd.stateChanged(play.game.state);
      widget.onPour?.call(play.game);
    } else {
      setState(() {});
      // Timer disarms too, so fake-time tests and real time agree.
      _armTimer = Timer(_arm.window, () {
        if (mounted) setState(_arm.disarm);
      });
    }
  }

  /// Banner Restart: no confirm (PRD §4.4).
  void _restartNow() {
    final play = _play;
    if (play == null) return;
    _armTimer?.cancel();
    setState(() {
      _arm.disarm();
      play.restart();
    });
    _deadEnd.stateChanged(play.game.state);
    widget.onPour?.call(play.game);
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
          color: PlaceholderStyle.background,
          child: SafeArea(
            child: play == null
                ? const SizedBox.expand()
                : Stack(
                    children: [
                      Column(
                        children: [
                          GoalQueueStrip(
                            queue: GoalQueueView.of(play.state.goalQueue),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(boardPadding),
                              child: LayoutBuilder(
                                builder: (context, box) => BoardView(
                                  state: play.state,
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
                      if (_deadEnd.showing && !play.isSolved)
                        Positioned(
                          left: boardPadding,
                          right: boardPadding,
                          bottom: bottomBarHeight + boardPadding,
                          child: DeadEndBanner(
                            onUndo: _undo,
                            onRestart: _restartNow,
                          ),
                        ),
                      if (play.isSolved)
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
      color: const Color(0x88000000),
      child: Center(
        child: Text(
          'Solved',
          style: PlaceholderStyle.serifItalic.copyWith(fontSize: 48),
        ),
      ),
    ),
  );
}
