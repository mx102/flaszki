import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'game_audio.dart';
import 'warmup_queue.dart';

/// [AudioOut] on flutter_soloud (PRD §6). Untested glue: behaviour lives in
/// [GameAudio] and [WarmupQueue].
///
/// Web starts the engine on the first pointer down ([unlock], the gesture
/// browsers need); sounds asked for while it loads play once it is ready
/// (if still fresh, see [WarmupQueue]). iOS session = `ambient` (AppDelegate), so it
/// mixes with other apps and respects the silent switch; Android does not
/// request audio focus, so nothing ducks.
class SoloudAudioOut implements AudioOut {
  SoloudAudioOut([SoLoud? soloud]) : _soloud = soloud ?? SoLoud.instance;

  final SoLoud _soloud;
  final Map<String, AudioSource> _sources = {};
  final WarmupQueue<(String, double, double)> _pending = WarmupQueue();
  Future<void>? _starting;
  bool _ready = false;
  bool _muted = false;

  /// Starts the engine and loads every sound (once). Native: call at launch;
  /// web: runs on the first pointer down ([unlock]).
  Future<void> start() => _starting ??= _load();

  @override
  void unlock() => start();

  Future<void> _load() async {
    try {
      if (!_soloud.isInitialized) await _soloud.init(bufferSize: 1024);
      _soloud.setGlobalVolume(_muted ? 0 : 1);
      for (final sfx in Sfx.values) {
        for (var v = 0; v < sfx.variants; v++) {
          final key = sfx.asset(v);
          _sources[key] = await _soloud.loadAsset(key);
        }
      }
    } on Object catch (e) {
      debugPrint('audio unavailable: $e');
    }
    _ready = true;
    for (final (key, volume, speed) in _pending.drain()) {
      final source = _sources[key];
      if (source != null) _fire(source, volume, speed);
    }
  }

  @override
  void play(Sfx sfx, {int variant = 0, double volume = 1, double speed = 1}) {
    start();
    final source = _sources[sfx.asset(variant)];
    if (source != null) {
      _fire(source, volume, speed);
    } else if (!_ready) {
      _pending.add((sfx.asset(variant), volume, speed));
    }
  }

  void _fire(AudioSource source, double volume, double speed) {
    if (_muted || !_soloud.isInitialized) return;
    try {
      final h = _soloud.play(source, volume: volume, paused: true);
      _soloud.setRelativePlaySpeed(h, speed);
      _soloud.setPause(h, false);
    } on Object catch (e) {
      debugPrint('audio play failed: $e');
    }
  }

  @override
  void setMuted(bool muted) {
    _muted = muted;
    if (_soloud.isInitialized) _soloud.setGlobalVolume(muted ? 0 : 1);
  }
}
