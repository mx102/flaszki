import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'src/play/level_sequencer.dart';
import 'src/save/save_store.dart';
import 'src/ui/level_screen.dart';
import 'src/ui/placeholder_style.dart';

/// Widest portrait aspect of the game column (ADR 0006).
const double kPortraitAspect = 9 / 16;

/// Root widget: the Level screen in a portrait column, full height, centred
/// with background filling the sides on desktop/web (ADR 0006).
class FlaszkiApp extends StatelessWidget {
  const FlaszkiApp({
    super.key,
    this.levelSource = generateLevelOffThread,
    this.startLevel = 1,
    this.save,
  });

  final LevelSource levelSource;

  /// Level to open when there is no [save].
  final int startLevel;

  /// Local save (#24): resumes from it and writes to it; `null` = none.
  final SaveStore? save;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flaszki',
    debugShowCheckedModeBanner: false,
    home: ColoredBox(
      color: PlaceholderStyle.sides,
      child: LayoutBuilder(
        builder: (context, box) => Center(
          child: SizedBox(
            key: const ValueKey('column'),
            width: math.min(box.maxWidth, box.maxHeight * kPortraitAspect),
            height: box.maxHeight,
            child: LevelScreen(
              levelSource: levelSource,
              startLevel: save?.initial.levelNumber ?? startLevel,
              initialGame: save?.initial.game,
              onLevelStarted: save?.levelStarted,
              onPour: save?.changed,
              onSolved: save?.solved,
            ),
          ),
        ),
      ),
    ),
  );
}
