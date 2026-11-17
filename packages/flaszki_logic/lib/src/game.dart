import 'board_state.dart';
import 'level.dart';

/// One Pour in the log: stable Flask indices (positions in the Level).
class Pour {
  const Pour(this.from, this.to);

  final int from;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is Pour && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'Pour($from → $to)';
}

/// A Level in play: initial snapshot + Pour log (PRD §2, §7, ADR 0005).
/// Current [state] is the snapshot with the log replayed.
class Game {
  Game(this.level) : _state = BoardState.initial(level);

  /// Restores from [toJson] output by replaying the Pour log. Throws
  /// [FormatException] on bad shape, bad snapshot or an illegal Pour.
  factory Game.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Game: not a map');
    final pours = json['pours'];
    if (pours is! List) throw const FormatException('Game: missing pours');
    final g = Game(Level.fromJson(json['snapshot']));
    for (final p in pours) {
      if (p is! List || p.length != 2 || p[0] is! int || p[1] is! int) {
        throw FormatException('Game: bad Pour $p');
      }
      if (g.pour(p[0] as int, p[1] as int) == null) {
        throw FormatException('Game: illegal Pour $p');
      }
    }
    return g;
  }

  /// `{snapshot: Level.toJson(), pours: [[from, to], ...]}`.
  Map<String, Object?> toJson() => {
    'snapshot': level.toJson(),
    'pours': [
      for (final p in _pours) [p.from, p.to],
    ],
  };

  /// Initial snapshot (Flasks + Goal Queue).
  final Level level;

  final List<Pour> _pours = [];
  BoardState _state;

  BoardState get state => _state;

  /// Pours made so far, oldest first. Unmodifiable view.
  List<Pour> get pours => List.unmodifiable(_pours);

  bool get canUndo => _pours.isNotEmpty;

  /// Applies and logs a Pour; returns null (nothing logged) if illegal.
  PourOutcome? pour(int from, int to) {
    if (!_state.canPour(from, to)) return null;
    final r = _state.pour(from, to);
    _pours.add(Pour(from, to));
    _state = r.state;
    return r;
  }

  /// Drops the last Pour and replays the log (reverts its seals).
  void undo() {
    if (_pours.isEmpty) return;
    _pours.removeLast();
    _state = _replay(level, _pours);
  }

  /// Back to the initial state; clears the log (and so Undo history).
  void restart() {
    _pours.clear();
    _state = BoardState.initial(level);
  }

  static BoardState _replay(Level level, Iterable<Pour> pours) {
    var s = BoardState.initial(level);
    for (final p in pours) {
      s = s.pour(p.from, p.to).state;
    }
    return s;
  }
}
