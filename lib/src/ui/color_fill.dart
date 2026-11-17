import 'package:flutter/widgets.dart';

import 'color_pattern.dart';

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

/// Fills its box with Color [colorId] ([color]) plus its pattern when
/// [ColorblindPatterns] is on. Used by Layers and Goal Queue orbs.
class ColorFill extends StatelessWidget {
  const ColorFill({super.key, required this.colorId, required this.color});

  final int colorId;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: ColorFillPainter(
      colorId: colorId,
      color: color,
      patterned: ColorblindPatterns.of(context),
    ),
    child: const SizedBox.expand(),
  );
}

/// Base fill + [paintPattern] when [patterned].
class ColorFillPainter extends CustomPainter {
  const ColorFillPainter({
    required this.colorId,
    required this.color,
    required this.patterned,
  });

  final int colorId;
  final Color color;
  final bool patterned;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = color);
    if (patterned) paintPattern(canvas, rect, colorId, color);
  }

  @override
  bool shouldRepaint(ColorFillPainter old) =>
      old.colorId != colorId ||
      old.color != color ||
      old.patterned != patterned;
}
