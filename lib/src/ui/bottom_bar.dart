import 'package:material_ui/material_ui.dart';

import 'style/style_a.dart';

/// Height of the bottom bar (PRD §4.1).
const double bottomBarHeight = 60;

/// Bottom bar: Undo, Restart (armed look while armed), serif italic
/// "Level N", gear (PRD §4.6). Gear calls [onSettings] (Settings sheet =
/// #28). Buttons are small glass discs (Style A).
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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _GlassButton(
            key: const ValueKey('undo'),
            tooltip: 'Undo',
            onPressed: canUndo ? onUndo : null,
            icon: Icons.undo,
          ),
          const SizedBox(width: 8),
          _GlassButton(
            key: const ValueKey('restart'),
            tooltip: restartArmed ? 'Tap again to restart' : 'Restart',
            onPressed: onRestart,
            icon: Icons.restart_alt,
            armed: restartArmed,
          ),
          Expanded(
            child: Text(
              'Level $levelNumber',
              textAlign: TextAlign.center,
              style: StyleA.serifItalic.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(width: 48),
          _GlassButton(
            key: const ValueKey('settings'),
            tooltip: 'Settings',
            onPressed: onSettings,
            icon: Icons.settings,
          ),
        ],
      ),
    ),
  );
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.armed = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool armed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final tint = armed ? StyleA.armed : const Color(0xFFFFFFFF);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.6,
          colors: [
            tint.withValues(alpha: armed ? 0.45 : 0.25),
            tint.withValues(alpha: armed ? 0.15 : 0.06),
          ],
        ),
        border: Border.all(
          color: tint.withValues(alpha: enabled ? 0.33 : 0.15),
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 22,
        color: armed ? StyleA.armed : StyleA.text,
        disabledColor: StyleA.text.withValues(alpha: 0.3),
        icon: Icon(icon),
      ),
    );
  }
}
