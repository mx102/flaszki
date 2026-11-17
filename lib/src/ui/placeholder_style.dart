import 'package:flutter/widgets.dart';

/// Placeholder look; Style A (#26) replaces this file's values and the
/// painters in flask_view.dart / goal_queue_strip.dart.
abstract final class PlaceholderStyle {
  /// Color id 0–11 → swatch (stable ids, palette L1 comes with #26).
  static const colors = [
    Color(0xFFE6194B),
    Color(0xFF3CB44B),
    Color(0xFFFFE119),
    Color(0xFF4363D8),
    Color(0xFFF58231),
    Color(0xFF911EB4),
    Color(0xFF42D4F4),
    Color(0xFFF032E6),
    Color(0xFFBFEF45),
    Color(0xFFFABED4),
    Color(0xFF9A6324),
    Color(0xFFF4F4F4),
  ];

  static const background = Color(0xFF1B2440);
  static const sides = Color(0xFF0F1528);
  static const glass = Color(0x99CFE3FF);
  static const cork = Color(0xFFB08850);
  static const text = Color(0xFFE8EEF8);
  static const armed = Color(0xFFFFB74D);

  /// Serif italic for "Level N" and "Solved" (PRD §5); real font in #26.
  static const serifItalic = TextStyle(
    fontFamily: 'serif',
    fontStyle: FontStyle.italic,
    color: text,
  );

  static Color color(int id) => colors[id % colors.length];
}
