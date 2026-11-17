import 'package:material_ui/material_ui.dart';

import 'placeholder_style.dart';

/// Height of the bottom bar (PRD §4.1).
const double bottomBarHeight = 60;

/// Bottom bar: Undo, Restart (armed look while armed), "Level N", gear
/// (PRD §4.6). Gear calls [onSettings] (Settings sheet = #28).
class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.levelNumber,
    required this.canUndo,
    required this.restartArmed,
    required this.onUndo,
    required this.onRestart,
    this.onSettings,
  });

  final int levelNumber;
  final bool canUndo;
  final bool restartArmed;
  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: bottomBarHeight,
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('undo'),
          tooltip: 'Undo',
          onPressed: canUndo ? onUndo : null,
          color: PlaceholderStyle.text,
          disabledColor: PlaceholderStyle.text.withValues(alpha: 0.3),
          icon: const Icon(Icons.undo),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: restartArmed
                ? PlaceholderStyle.armed.withValues(alpha: 0.3)
                : null,
          ),
          child: IconButton(
            key: const ValueKey('restart'),
            tooltip: restartArmed ? 'Tap again to restart' : 'Restart',
            onPressed: onRestart,
            color: restartArmed
                ? PlaceholderStyle.armed
                : PlaceholderStyle.text,
            icon: const Icon(Icons.restart_alt),
          ),
        ),
        Expanded(
          child: Text(
            'Level $levelNumber',
            textAlign: TextAlign.center,
            style: PlaceholderStyle.serifItalic.copyWith(fontSize: 20),
          ),
        ),
        const SizedBox(width: 48),
        IconButton(
          key: const ValueKey('settings'),
          tooltip: 'Settings',
          onPressed: onSettings,
          color: PlaceholderStyle.text,
          disabledColor: PlaceholderStyle.text.withValues(alpha: 0.5),
          icon: const Icon(Icons.settings),
        ),
      ],
    ),
  );
}
