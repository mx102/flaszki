import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: bottomBarHeight,
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('undo'),
            tooltip: l10n.undo,
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
              tooltip: restartArmed ? l10n.restartConfirm : l10n.restart,
              onPressed: onRestart,
              color: restartArmed
                  ? PlaceholderStyle.armed
                  : PlaceholderStyle.text,
              icon: const Icon(Icons.restart_alt),
            ),
          ),
          Expanded(
            child: Text(
              l10n.levelLabel(levelNumber),
              textAlign: TextAlign.center,
              style: PlaceholderStyle.serifItalic.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(width: 48),
          IconButton(
            key: const ValueKey('settings'),
            tooltip: l10n.settings,
            onPressed: onSettings,
            color: PlaceholderStyle.text,
            disabledColor: PlaceholderStyle.text.withValues(alpha: 0.5),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
