import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'src/audio/game_audio.dart';
import 'src/play/level_sequencer.dart';
import 'src/l10n.dart';
import 'src/save/save_store.dart';
import 'src/ui/color_fill.dart';
import 'src/ui/level_screen.dart';
import 'src/ui/settings_sheet.dart';
import 'src/ui/style/backdrop_painter.dart';
import 'src/ui/style/style_a.dart';

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
    this.audioOut,
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

  /// Sound output (#29); `null` = silent.
  final AudioOut? audioOut;

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

  /// Sound effects, gated by the Sound toggle; muted while backgrounded.
  late final GameAudio? _audio = widget.audioOut == null
      ? null
      : GameAudio(widget.audioOut!, enabled: () => _settings.value.sound);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: () => _audio?.setBackgrounded(true),
    onShow: () => _audio?.setBackgrounded(false),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
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
  Widget build(BuildContext context) => Listener(
    // Any pointer down is the web audio unlock gesture (#29).
    onPointerDown: (_) => widget.audioOut?.unlock(),
    behavior: HitTestBehavior.translucent,
    child: _app(),
  );

  Widget _app() => MaterialApp(
    title: 'Flaszki',
    navigatorKey: _nav,
    debugShowCheckedModeBanner: false,
    // System locale, fallback English (first supported) (PRD §4.7).
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: StyleA.serif,
      colorScheme: const ColorScheme.dark(surface: StyleA.skyBottom),
    ),
    color: StyleA.skyTop,
    home: ValueListenableBuilder(
      valueListenable: _settings,
      builder: (context, s, child) =>
          ColorblindPatterns(enabled: s.colorblindPatterns, child: child!),
      child: CustomPaint(
        painter: const BackdropPainter(),
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
                audio: _audio,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
