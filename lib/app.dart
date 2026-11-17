import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'src/play/level_sequencer.dart';
import 'src/save/save_store.dart';
import 'src/ui/color_fill.dart';
import 'src/ui/level_screen.dart';
import 'src/ui/placeholder_style.dart';
import 'src/ui/settings_sheet.dart';

/// Widest portrait aspect of the game column (ADR 0006).
const double kPortraitAspect = 9 / 16;

/// Root widget: the Level screen in a portrait column, full height, centred
/// with background filling the sides on desktop/web (ADR 0006).
class FlaszkiApp extends StatefulWidget {
  const FlaszkiApp({
    super.key,
    this.levelSource = generateLevelOffThread,
    this.startLevel = 1,
    this.save,
    this.version,
    this.openUrl = launchUrl,
  });

  final LevelSource levelSource;

  /// Level to open when there is no [save].
  final int startLevel;

  /// Local save (#24): resumes from it and writes to it; `null` = none.
  final SaveStore? save;

  /// App version shown in Settings (`X.Y.Z+build`); `null` = hidden.
  final String? version;

  /// Opens the Privacy link.
  final UrlOpener openUrl;

  @override
  State<FlaszkiApp> createState() => _FlaszkiAppState();
}

class _FlaszkiAppState extends State<FlaszkiApp> {
  final _nav = GlobalKey<NavigatorState>();

  /// Live settings; every change is saved (#24 `settings` key). Sound (#29)
  /// reads `settings.value.sound`.
  late final ValueNotifier<Settings> _settings = ValueNotifier(
    widget.save?.settings ?? const Settings(),
  )..addListener(() => widget.save?.saveSettings(_settings.value));

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  void _openSettings() => showSettingsSheet(
    _nav.currentContext!,
    settings: _settings,
    openUrl: widget.openUrl,
    version: widget.version,
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flaszki',
    navigatorKey: _nav,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark),
    home: ValueListenableBuilder(
      valueListenable: _settings,
      builder: (context, s, child) =>
          ColorblindPatterns(enabled: s.colorblindPatterns, child: child!),
      child: ColoredBox(
        color: PlaceholderStyle.sides,
        child: LayoutBuilder(
          builder: (context, box) => Center(
            child: SizedBox(
              key: const ValueKey('column'),
              width: math.min(box.maxWidth, box.maxHeight * kPortraitAspect),
              height: box.maxHeight,
              child: LevelScreen(
                levelSource: widget.levelSource,
                startLevel:
                    widget.save?.initial.levelNumber ?? widget.startLevel,
                initialGame: widget.save?.initial.game,
                onLevelStarted: widget.save?.levelStarted,
                onPour: widget.save?.changed,
                onSolved: widget.save?.solved,
                onOpenSettings: _openSettings,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
