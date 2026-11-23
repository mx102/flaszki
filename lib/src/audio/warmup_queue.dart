/// Holds sounds asked for while the audio engine is still starting, so the
/// first sound on web (engine started by that very tap) is not lost; ones
/// older than [maxAge] when the engine is ready are dropped, not played late.
class WarmupQueue<T> {
  WarmupQueue({this.maxAge = const Duration(milliseconds: 300), this.now});

  final Duration maxAge;

  /// Clock; default a monotonic stopwatch. Injectable for tests.
  final Duration Function()? now;

  final Stopwatch _watch = Stopwatch()..start();
  final List<(Duration, T)> _items = [];

  Duration get _now => now?.call() ?? _watch.elapsed;

  void add(T item) => _items.add((_now, item));

  /// The still-fresh items, oldest first; empties the queue.
  List<T> drain() {
    final cutoff = _now - maxAge;
    final out = [
      for (final (at, item) in _items)
        if (at >= cutoff) item,
    ];
    _items.clear();
    return out;
  }
}
