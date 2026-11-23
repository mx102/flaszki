import 'dart:convert';

import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';

import 'key_value_store.dart';

/// Player settings (PRD §4.6, §7). `music`/`haptics` reserved.
@immutable
class Settings {
  const Settings({
    this.colorblindPatterns = false,
    this.sound = true,
    this.music = false,
    this.haptics = false,
  });

  /// Missing fields take their defaults; a wrong type throws
  /// [FormatException].
  factory Settings.fromJson(Map<String, Object?> json) {
    bool flag(String k, bool fallback) => switch (json[k]) {
      null => fallback,
      final bool b => b,
      final v => throw FormatException('$k: $v'),
    };
    const d = Settings();
    return Settings(
      colorblindPatterns: flag('colorblindPatterns', d.colorblindPatterns),
      sound: flag('sound', d.sound),
      music: flag('music', d.music),
      haptics: flag('haptics', d.haptics),
    );
  }

  final bool colorblindPatterns;
  final bool sound;
  final bool music;
  final bool haptics;

  Map<String, Object?> toJson() => {
    'colorblindPatterns': colorblindPatterns,
    'sound': sound,
    'music': music,
    'haptics': haptics,
  };

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.colorblindPatterns == colorblindPatterns &&
      other.sound == sound &&
      other.music == music &&
      other.haptics == haptics;

  @override
  int get hashCode => Object.hash(colorblindPatterns, sound, music, haptics);
}

/// What the app resumes into.
class SaveData {
  const SaveData({
    required this.levelNumber,
    this.game,
    required this.settings,
  });

  final int levelNumber;

  /// Level [levelNumber] in progress, rebuilt from its snapshot + Pours.
  final Game? game;
  final Settings settings;
}

const progressKey = 'progress';
const levelKey = 'level';
const settingsKey = 'settings';

/// Current `schemaVersion` per key.
const schemaVersions = {progressKey: 1, levelKey: 1, settingsKey: 1};

/// One forward step: JSON at schemaVersion v → v+1 (fields only; the
/// `schemaVersion` field itself is ignored after migrating).
typedef Migration = Map<String, Object?> Function(Map<String, Object?> json);

/// Per key, `{v: step v→v+1}`. Bump [schemaVersions] and add a step here
/// whenever a key's shape changes; migrations run one version at a time.
const Map<String, Map<int, Migration>> saveMigrations = {};

/// Local save (ADR 0005, PRD §7): three JSON keys, each with its own
/// `schemaVersion`; each falls back on its own (logged only) when missing,
/// corrupt or newer than this app knows.
class SaveStore {
  SaveStore(
    this._kv, {
    void Function(String)? log,
    this.migrations = saveMigrations,
  }) : _log = log ?? debugPrint;

  final KeyValueStore _kv;
  final void Function(String) _log;
  final Map<String, Map<int, Migration>> migrations;

  /// Loaded once, at launch.
  late final SaveData initial = _load();

  int _levelNumber = 1;

  /// Level [levelNumber] is in play with [game] (fresh or restored).
  void levelStarted(int levelNumber, Game game) {
    _levelNumber = levelNumber;
    _write(progressKey, {'levelNumber': levelNumber});
    gameChanged(game);
  }

  /// After every Pour, Undo and Restart.
  void gameChanged(Game game) =>
      _write(levelKey, {'levelNumber': _levelNumber, ...game.toJson()});

  /// On Solved: Level Number++, `level` cleared.
  void solved(int levelNumber) {
    _levelNumber = levelNumber + 1;
    _write(progressKey, {'levelNumber': _levelNumber});
    _kv.remove(levelKey);
  }

  void _write(String key, Map<String, Object?> value) => _kv.setString(
    key,
    jsonEncode({'schemaVersion': schemaVersions[key], ...value}),
  );

  /// Current settings (as loaded, then as last saved).
  Settings get settings => _settings ?? initial.settings;
  Settings? _settings;

  /// Settings sheet (#28) calls this on every toggle.
  void saveSettings(Settings s) {
    _settings = s;
    _write(settingsKey, s.toJson());
  }

  SaveData _load() {
    var n =
        _read(progressKey, (j) {
          final n = j['levelNumber'];
          if (n is! int || n < 1) throw const FormatException('levelNumber');
          return n;
        }) ??
        1;
    var game = _read(levelKey, (j) {
      if (j['levelNumber'] != n) {
        throw FormatException('levelNumber ${j['levelNumber']} ≠ progress $n');
      }
      return Game.fromJson(j);
    });
    if (game != null && game.state.isSolved) {
      n++; // killed between the last Pour and the Solved write
      game = null;
    }
    final settings = _read(settingsKey, Settings.fromJson) ?? const Settings();
    _levelNumber = n;
    return SaveData(levelNumber: n, game: game, settings: settings);
  }

  /// Reads [key], migrating it forward to the current `schemaVersion`.
  /// `null` if missing; logs and returns `null` if corrupt or newer.
  T? _read<T>(String key, T Function(Map<String, Object?>) parse) {
    final raw = _kv.getString(key);
    if (raw == null) return null;
    try {
      var json = jsonDecode(raw);
      if (json is! Map<String, Object?>) throw const FormatException('shape');
      final stored = json['schemaVersion'];
      final current = schemaVersions[key]!;
      if (stored is! int || stored > current) {
        throw FormatException('schemaVersion $stored (app knows $current)');
      }
      for (var v = stored; v < current; v++) {
        final step = migrations[key]?[v];
        if (step == null) throw FormatException('no migration from v$v');
        json = step(json);
      }
      return parse(json);
    } on Object catch (e) {
      _log('save: discarding `$key` ($e)');
      return null;
    }
  }
}
