import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart' show compute;

/// Produces Level N; may run off the UI thread.
typedef LevelSource = Future<GeneratedLevel> Function(int levelNumber);

GeneratedLevel _generate(int n) => generate(n);

/// Default [LevelSource]: `compute` runs [generate] in an isolate on native
/// and on the main thread (event loop) on web (PRD §3.1, ADR 0001).
Future<GeneratedLevel> generateLevelOffThread(int n) =>
    compute(_generate, n, debugLabel: 'generate($n)');

/// Current Level + pre-generated next one (PRD §3.1, §4.5): as soon as
/// Level N starts, N+1 is requested, so advancing after Solved is instant.
///
/// Save (#24) seam: pass the saved Level Number as [startLevel].
class LevelSequencer {
  LevelSequencer(this._source, {this.startLevel = 1});

  final LevelSource _source;
  final int startLevel;

  late int _levelNumber = startLevel;
  GeneratedLevel? _current;
  Future<GeneratedLevel>? _next;
  bool _nextReady = false;

  int get levelNumber => _levelNumber;
  GeneratedLevel? get current => _current;

  /// Whether Level N+1 has finished generating.
  bool get nextReady => _nextReady;

  /// Loads Level [startLevel] and starts pre-generating the next.
  Future<GeneratedLevel> start() async {
    final g = await _source(startLevel);
    _began(startLevel, g);
    return g;
  }

  /// Resumes a saved Level [startLevel] (not regenerated: it finishes from
  /// its snapshot, ADR 0005) and starts pre-generating the next.
  void resume() => _began(startLevel, null);

  /// Moves to Level N+1 (waits only if it is still generating).
  Future<GeneratedLevel> advance() async {
    final n = _levelNumber + 1;
    final g = await (_next ?? _source(n));
    _began(n, g);
    return g;
  }

  /// Level [n] is current ([g] = `null` when resumed from a save).
  void _began(int n, GeneratedLevel? g) {
    _levelNumber = n;
    _current = g;
    _nextReady = false;
    final next = _source(n + 1);
    _next = next;
    next.then((_) {
      if (identical(_next, next)) _nextReady = true;
    }, onError: (Object _) {});
  }
}
