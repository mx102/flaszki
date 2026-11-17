import 'dart:convert';

import 'package:flaszki/src/save/key_value_store.dart';
import 'package:flaszki/src/save/save_store.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryStore disk;
  late List<String> logs;

  /// A fresh [SaveStore] over the same storage = app relaunch.
  SaveStore launch() => SaveStore(disk, log: logs.add);

  setUp(() {
    disk = MemoryStore();
    logs = [];
  });

  test(
    'missing save = new player: Level 1, no Level in progress, defaults',
    () {
      final s = launch().initial;
      expect(s.levelNumber, 1);
      expect(s.game, isNull);
      expect(s.settings, const Settings());
      expect(s.settings.sound, isTrue);
      expect(s.settings.colorblindPatterns, isFalse);
      expect(logs, isEmpty);
    },
  );

  test('kill mid-Level → relaunch restores exact board + Undo history', () {
    final level = generate(3).level;
    final store = launch();
    final game = Game(level);
    store.levelStarted(3, game);
    final moves = generate(3).report.solution!.take(3).toList();
    for (final p in moves) {
      game.pour(p.from, p.to);
      store.changed(game);
    }

    final s = launch().initial; // fresh instance = relaunch
    expect(s.levelNumber, 3);
    final g = s.game!;
    expect(g.toJson(), game.toJson());
    expect(g.state.goalQueue, game.state.goalQueue);
    expect(g.pours, moves);
    g.undo();
    game.undo();
    expect(g.toJson(), game.toJson());
    expect(g.canUndo, isTrue);
    expect(logs, isEmpty);
  });

  test('Undo and Restart are saved too', () {
    final store = launch();
    final game = Game(generate(2).level);
    store.levelStarted(2, game);
    final p = generate(2).report.solution!.first;
    game.pour(p.from, p.to);
    store.changed(game);
    game.undo();
    store.changed(game);
    expect(launch().initial.game!.pours, isEmpty);
    game.pour(p.from, p.to);
    store.changed(game);
    game.restart();
    store.changed(game);
    expect(launch().initial.game!.canUndo, isFalse);
  });

  test('Solved → next Level Number, Level cleared (N+1 not saved)', () {
    final store = launch();
    final game = Game(generate(1).level);
    store.levelStarted(1, game);
    for (final p in generate(1).report.solution!) {
      game.pour(p.from, p.to);
      store.changed(game);
    }
    store.solved(1);
    final s = launch().initial;
    expect(s.levelNumber, 2);
    expect(s.game, isNull);
    expect(disk.data.containsKey('level'), isFalse);
  });

  test('solved Level left by a kill before Solved write counts as Solved', () {
    final store = launch();
    final game = Game(generate(1).level);
    store.levelStarted(1, game);
    for (final p in generate(1).report.solution!) {
      game.pour(p.from, p.to);
      store.changed(game);
    }
    final s = launch().initial;
    expect(s.levelNumber, 2);
    expect(s.game, isNull);
  });

  test('settings round-trip', () {
    const custom = Settings(colorblindPatterns: true, sound: false);
    launch().saveSettings(custom);
    expect(launch().initial.settings, custom);
    expect(launch().settings, custom);
  });

  group('corrupting each key separately → only that key falls back', () {
    const custom = Settings(colorblindPatterns: true, sound: false);

    /// Level 4 in progress with 2 Pours, custom settings.
    Game seed() {
      final store = launch();
      store.saveSettings(custom);
      final game = Game(generate(4).level);
      store.levelStarted(4, game);
      for (final p in generate(4).report.solution!.take(2)) {
        game.pour(p.from, p.to);
        store.changed(game);
      }
      return game;
    }

    const corruptions = {
      'not JSON': '{{{',
      'wrong shape': '[1,2]',
      'newer schemaVersion': '{"schemaVersion":99,"levelNumber":4}',
    };

    for (final MapEntry(key: what, value: bad) in corruptions.entries) {
      test('progress: $what → Level 1, settings kept', () {
        seed();
        disk.data['progress'] = bad;
        final s = launch().initial;
        expect(s.levelNumber, 1);
        expect(s.game, isNull); // level 4 ≠ progress 1
        expect(s.settings, custom);
        expect(logs, isNotEmpty);
      });

      test('level: $what → Level N fresh, settings kept', () {
        seed();
        disk.data['level'] = bad;
        final s = launch().initial;
        expect(s.levelNumber, 4);
        expect(s.game, isNull);
        expect(s.settings, custom);
        expect(logs.single, contains('level'));
      });

      test('settings: $what → defaults, Level kept', () {
        final game = seed();
        disk.data['settings'] = bad;
        final s = launch().initial;
        expect(s.settings, const Settings());
        expect(s.levelNumber, 4);
        expect(s.game!.toJson(), game.toJson());
        expect(logs.single, contains('settings'));
      });
    }

    test('level with an illegal Pour → Level N fresh', () {
      seed();
      final j = jsonDecode(disk.data['level']!) as Map<String, Object?>;
      disk.data['level'] = jsonEncode({
        ...j,
        'pours': [
          [0, 0],
        ],
      });
      expect(launch().initial.game, isNull);
      expect(logs.single, contains('level'));
    });

    test('settings with wrong field types → defaults', () {
      seed();
      disk.data['settings'] = '{"schemaVersion":1,"sound":"yes"}';
      expect(launch().initial.settings, const Settings());
    });
  });

  test('level for another Level Number than progress is discarded', () {
    final store = launch();
    store.levelStarted(5, Game(generate(5).level));
    disk.data['progress'] = '{"schemaVersion":1,"levelNumber":6}';
    final s = launch().initial;
    expect(s.levelNumber, 6);
    expect(s.game, isNull);
  });

  test('older schemaVersion runs forward-only migrations in order', () {
    disk.data['progress'] = '{"schemaVersion":0,"level":7}';
    final store = SaveStore(
      disk,
      log: logs.add,
      migrations: {
        'progress': {
          0: (j) => {'levelNumber': j['level']},
        },
      },
    );
    expect(store.initial.levelNumber, 7);
  });

  test('older schemaVersion without a migration falls back', () {
    disk.data['progress'] = '{"schemaVersion":0,"levelNumber":7}';
    expect(launch().initial.levelNumber, 1);
    expect(logs.single, contains('progress'));
  });
}
