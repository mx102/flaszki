import 'package:flaszki_logic/flaszki_logic.dart';

/// What a tap did; the view turns it into lift / shake / Pour animation.
sealed class TapEffect {
  const TapEffect();
}

/// Flask [index] is now selected (lifts).
class Selected extends TapEffect {
  const Selected(this.index);
  final int index;
}

/// Selection cleared.
class Deselected extends TapEffect {
  const Deselected();
}

/// Pour made; [outcome] lists Layers moved and seals (cascade included).
class Poured extends TapEffect {
  const Poured(this.from, this.to, this.outcome);
  final int from, to;
  final PourOutcome outcome;
}

/// Invalid tap: [target] shakes; selection moved to it if it is not empty.
class Rejected extends TapEffect {
  const Rejected(this.target);
  final int target;
}

/// Tap ignored (Level Solved, Flask not on the board, or an empty Flask with
/// nothing selected).
class Ignored extends TapEffect {
  const Ignored();
}

/// Tap-tap Pour input over a [Game] (PRD §4.2). Plain Dart.
/// Flask indices are the stable indices of [BoardState].
class PlayController {
  PlayController(this.game);

  final Game game;
  int? _selected;

  int? get selected => _selected;
  BoardState get state => game.state;
  bool get isSolved => game.state.isSolved;
  bool get canUndo => game.canUndo;

  TapEffect tapFlask(int i) {
    if (isSolved || !state.isOnBoard(i)) return const Ignored();
    final sel = _selected;
    if (sel == null) {
      // Nothing to pour: not an invalid Pour target, so no shake (§4.2).
      if (state.flasks[i].isEmpty) return const Ignored();
      _selected = i;
      return Selected(i);
    }
    if (sel == i) {
      _selected = null;
      return const Deselected();
    }
    final outcome = game.pour(sel, i);
    if (outcome != null) {
      _selected = null;
      return Poured(sel, i, outcome);
    }
    _selected = state.flasks[i].isEmpty ? null : i;
    return Rejected(i);
  }

  /// Tap on empty board: deselects. Returns whether anything changed.
  bool tapEmpty() => _deselect();

  /// Back / Esc: deselects; false = not handled (system default applies).
  bool back() => _deselect();

  /// Undo the last Pour; false if there is none.
  bool undo() {
    _selected = null;
    if (!game.canUndo) return false;
    game.undo();
    return true;
  }

  void restart() {
    _selected = null;
    game.restart();
  }

  bool _deselect() {
    if (_selected == null) return false;
    _selected = null;
    return true;
  }
}
