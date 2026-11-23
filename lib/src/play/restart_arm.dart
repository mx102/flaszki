/// Two-tap Restart (PRD §4.6): first press arms for [window], a second press
/// while armed restarts. No modal. Plain Dart; time comes from the caller
/// (monotonic, e.g. a Stopwatch's elapsed).
class RestartArm {
  RestartArm({this.window = const Duration(seconds: 2)});

  final Duration window;
  Duration? _armedAt;

  /// Returns true when this press should restart.
  bool press(Duration now) {
    if (isArmed(now)) {
      _armedAt = null;
      return true;
    }
    _armedAt = now;
    return false;
  }

  bool isArmed(Duration now) => remaining(now) > Duration.zero;

  /// Time left armed; zero when not armed.
  Duration remaining(Duration now) {
    final at = _armedAt;
    if (at == null) return Duration.zero;
    final left = at + window - now;
    return left > Duration.zero ? left : Duration.zero;
  }

  void disarm() => _armedAt = null;
}
