import 'dart:convert';

import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:test/test.dart';

final sample = Level(
  flasks: [
    Flask([1, 0, 0, 0]),
    Flask([0]),
    Flask([1, 1, 1]),
    Flask([]),
  ],
  goalQueue: [0, 1],
);

void main() {
  test('JSON shape: snapshot (flasks + goalQueue) and pours', () {
    final g = Game(sample)..pour(0, 1);
    expect(jsonDecode(jsonEncode(g.toJson())), {
      'snapshot': {
        'flasks': [
          [1, 0, 0, 0],
          [0],
          [1, 1, 1],
          [],
        ],
        'goalQueue': [0, 1],
      },
      'pours': [
        [0, 1],
      ],
    });
  });

  test('fromJson replays pours: exact board, queue and Undo history', () {
    final g = Game(sample)..pour(0, 1);
    final restored = Game.fromJson(jsonDecode(jsonEncode(g.toJson())));
    expect(restored.level, sample);
    expect(restored.pours, [const Pour(0, 1)]);
    expect(restored.state.goalQueue, [1]);
    expect(restored.state.isOnBoard(1), isFalse);
    restored.undo();
    expect(restored.state.isOnBoard(1), isTrue);
    expect(restored.state.goalQueue, [0, 1]);
  });

  group('fromJson rejects corrupt data with FormatException', () {
    final bad = <String, Object?>{
      'not a map': 42,
      'missing pours': {
        'snapshot': {'flasks': [], 'goalQueue': []},
      },
      'Color out of range': {
        'snapshot': {
          'flasks': [
            [12],
          ],
          'goalQueue': [12],
        },
        'pours': [],
      },
      'overfull Flask': {
        'snapshot': {
          'flasks': [
            [0, 0, 0, 0, 0],
          ],
          'goalQueue': [0],
        },
        'pours': [],
      },
      'illegal Pour in log': {
        'snapshot': {
          'flasks': [
            [0],
            [1],
          ],
          'goalQueue': [0, 1],
        },
        'pours': [
          [0, 1],
        ],
      },
      'malformed Pour': {
        'snapshot': {
          'flasks': [
            [0],
            [],
          ],
          'goalQueue': [0],
        },
        'pours': [
          [0],
        ],
      },
    };
    bad.forEach((name, json) {
      test(name, () {
        expect(() => Game.fromJson(json), throwsFormatException);
      });
    });
  });
}
