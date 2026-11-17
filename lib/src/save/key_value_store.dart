import 'package:shared_preferences/shared_preferences.dart';

/// String key-value persistence behind the save (ADR 0005). Reads are
/// synchronous (loaded once at launch); writes may complete later.
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// In-memory [KeyValueStore]; a new store over the same [data] map
/// simulates an app relaunch in tests.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  String? getString(String key) => data[key];

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}

/// `shared_preferences` on all targets (web: localStorage).
class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SharedPrefsStore> open(Set<String> keys) async =>
      SharedPrefsStore._(
        await SharedPreferencesWithCache.create(
          cacheOptions: SharedPreferencesWithCacheOptions(allowList: keys),
        ),
      );

  @override
  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } on Object {
      return null; // non-String value under our key: treat as missing
    }
  }

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
