import 'package:flutter/widgets.dart';

/// Whether colorblind patterns are on (Settings, PRD §4.6) for the subtree.
class ColorblindPatterns extends InheritedWidget {
  const ColorblindPatterns({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ColorblindPatterns>()
          ?.enabled ??
      false;

  @override
  bool updateShouldNotify(ColorblindPatterns old) => old.enabled != enabled;
}

/// A painter that draws Colors and can overlay their patterns; tests read
/// [patterned] to check the Settings toggle reaches every Layer and orb.
abstract interface class PatternedPainter implements CustomPainter {
  bool get patterned;
}
