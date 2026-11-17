import 'package:flutter/widgets.dart';

/// Style A, apothecary glass (PRD §5): colors, fonts and shared helpers.
/// Painters live next to this file (backdrop / flask / orb / cork).
abstract final class StyleA {
  /// Palette L1, Color id 0–11 → swatch. Ids are stable across versions
  /// (ADR 0005, PRD §5.1); never reorder.
  static const palette = [
    Color(0xFFE6194B), // 0 red
    Color(0xFF3CB44B), // 1 green
    Color(0xFFFFE119), // 2 yellow
    Color(0xFF4363D8), // 3 blue
    Color(0xFFF58231), // 4 orange
    Color(0xFF911EB4), // 5 purple
    Color(0xFF42D4F4), // 6 cyan
    Color(0xFFF032E6), // 7 magenta
    Color(0xFF9AD61E), // 8 lime (L1: darker than P1 #bfef45)
    Color(0xFFFABED4), // 9 pink
    Color(0xFF9A6324), // 10 brown
    Color(0xFFF4F4F4), // 11 white
  ];

  static Color color(int id) => palette[id % palette.length];

  // Backdrop: night-blue vertical gradient + radial vignette.
  static const skyTop = Color(0xFF1A2F4D);
  static const skyBottom = Color(0xFF0A1220);
  static const vignetteCenter = Color(0x1A78AAFF); // rgba(120,170,255,.10)
  static const vignetteEdge = Color(0x59000000); // rgba(0,0,0,.35)
  static const shelf = Color(0x1AA0C8FF); // rgba(160,200,255,.10)

  // Glass.
  static const glassFill = Color(0x0FC8E1FF); // rgba(200,225,255,.06)
  static const glassOutline = Color(0xBFD2EBFF); // rgba(210,235,255,.75)
  static const orbOutline = Color(0xB3DCF0FF); // rgba(220,240,255,.7)

  // Cork + badge.
  static const cork = Color(0xFFB88555);
  static const corkPores = Color(0x593C1E0A);
  static const badge = Color(0xE6E6F5FF);
  static const badgeText = Color(0xFF14233A);

  // Text / UI chrome.
  static const text = Color(0xFFDFEFFF);
  static const label = Color(0xD9DCF0FF); // rgba(220,240,255,.85)
  static const solved = Color(0xFFE8F3FF);
  static const armed = Color(0xFFFFB74D);
  static const scrim = Color(0x8C000000); // rgba(0,0,0,.55)

  /// EB Garamond (OFL, bundled; see CREDITS.md). Variable `wght` axis.
  static const serif = 'EB Garamond';

  /// Serif italic for "Level N" and "Solved" (PRD §5).
  static const serifItalic = TextStyle(
    fontFamily: serif,
    fontStyle: FontStyle.italic,
    color: label,
  );

  /// Small-caps serif for "NEXT".
  static const smallCaps = TextStyle(
    fontFamily: serif,
    fontSize: 11,
    letterSpacing: 2.5,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    fontFeatures: [FontFeature.enable('c2sc'), FontFeature.enable('smcp')],
    color: Color(0xBFDCF0FF),
  );

  /// [c] lightened (f > 0, towards white) or darkened (f < 0), as the
  /// prototype's `shade()`.
  static Color shade(Color c, double f) {
    double m(double v) => f < 0 ? v * (1 + f) : v + (1 - v) * f;
    return Color.from(alpha: c.a, red: m(c.r), green: m(c.g), blue: m(c.b));
  }
}
