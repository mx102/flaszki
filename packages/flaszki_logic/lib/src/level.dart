/// Number of distinct Colors in the game; Color ids are `0..maxColors-1`.
const int maxColors = 12;

/// Uniform Flask capacity in Layers (PRD §2).
const int flaskCapacity = 4;

/// A Flask: its Layers as Color ids, bottom → top. Immutable.
class Flask {
  Flask(Iterable<int> layers) : layers = List.unmodifiable(layers);

  final List<int> layers;

  bool get isEmpty => layers.isEmpty;
  bool get isFull => layers.length >= flaskCapacity;
  int get freeSpace => flaskCapacity - layers.length;

  /// Color of the top Layer; null when empty.
  int? get topColor => layers.isEmpty ? null : layers.last;

  /// Number of contiguous same-Color Layers at the top.
  int get topRun {
    if (layers.isEmpty) return 0;
    var n = 1;
    while (n < layers.length && layers[layers.length - 1 - n] == layers.last) {
      n++;
    }
    return n;
  }

  /// Completed Flask: full and single-Color.
  bool get isCompleted => isFull && topRun == layers.length;

  @override
  bool operator ==(Object other) =>
      other is Flask && listEquals(other.layers, layers);

  @override
  int get hashCode => Object.hashAll(layers);

  @override
  String toString() => 'Flask$layers';
}

/// A Level: initial Flasks plus Goal Queue (head first). Immutable.
class Level {
  Level({required Iterable<Flask> flasks, required Iterable<int> goalQueue})
    : flasks = List.unmodifiable(flasks),
      goalQueue = List.unmodifiable(goalQueue);

  /// Parses `{flasks: [[int]], goalQueue: [int]}`. Throws [FormatException]
  /// on bad shape, Color ids outside 0–11, or Flasks over capacity.
  factory Level.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Level: not a map');
    final flasks = json['flasks'];
    final queue = json['goalQueue'];
    if (flasks is! List || queue is! List) {
      throw const FormatException('Level: missing flasks/goalQueue');
    }
    return Level(
      flasks: [
        for (final f in flasks)
          if (f is List && f.length <= flaskCapacity)
            Flask(f.map(_color))
          else
            throw FormatException('Level: bad Flask $f'),
      ],
      goalQueue: queue.map(_color),
    );
  }

  final List<Flask> flasks;
  final List<int> goalQueue;

  Map<String, Object?> toJson() => {
    'flasks': [for (final f in flasks) f.layers],
    'goalQueue': goalQueue,
  };

  static int _color(Object? c) {
    if (c is int && c >= 0 && c < maxColors) return c;
    throw FormatException('Level: bad Color id $c');
  }

  @override
  bool operator ==(Object other) =>
      other is Level &&
      listEquals(other.flasks, flasks) &&
      listEquals(other.goalQueue, goalQueue);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(flasks), Object.hashAll(goalQueue));
}

/// Element-wise list equality.
bool listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
