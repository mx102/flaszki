import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'src/play/level_sequencer.dart';
import 'src/ui/level_screen.dart';
import 'src/ui/style/backdrop_painter.dart';
import 'src/ui/style/style_a.dart';

/// Widest portrait aspect of the game column (ADR 0006).
const double kPortraitAspect = 9 / 16;

/// Root widget: the Level screen in a portrait column, full height, centred
/// with background filling the sides on desktop/web (ADR 0006).
class FlaszkiApp extends StatelessWidget {
  const FlaszkiApp({
    super.key,
    this.levelSource = generateLevelOffThread,
    this.startLevel = 1,
  });

  final LevelSource levelSource;

  /// Level to open; save (#24) passes the saved Level Number.
  final int startLevel;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flaszki',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: StyleA.serif,
      colorScheme: const ColorScheme.dark(surface: StyleA.skyBottom),
    ),
    color: StyleA.skyTop,
    home: CustomPaint(
      painter: const BackdropPainter(),
      child: LayoutBuilder(
        builder: (context, box) => Center(
          child: SizedBox(
            key: const ValueKey('column'),
            width: math.min(box.maxWidth, box.maxHeight * kPortraitAspect),
            height: box.maxHeight,
            child: LevelScreen(
              levelSource: levelSource,
              startLevel: startLevel,
            ),
          ),
        ),
      ),
    ),
  );
}
