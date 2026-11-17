import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import 'style/style_a.dart';

/// Non-modal Dead End hint (PRD §4.4) with inline Undo and Restart (this
/// Restart needs no confirm).
class DeadEndBanner extends StatelessWidget {
  const DeadEndBanner({
    super.key,
    required this.onUndo,
    required this.onRestart,
  });

  final VoidCallback onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('dead-end'),
    color: StyleA.skyBottom.withValues(alpha: 0.92),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: StyleA.orbOutline.withValues(alpha: 0.35)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.deadEnd,
              style: StyleA.serifItalic.copyWith(fontSize: 16),
            ),
          ),
          TextButton(
            key: const ValueKey('dead-end-undo'),
            onPressed: onUndo,
            child: Text(
              context.l10n.undo,
              style: const TextStyle(color: StyleA.text),
            ),
          ),
          TextButton(
            key: const ValueKey('dead-end-restart'),
            onPressed: onRestart,
            child: Text(
              context.l10n.restart,
              style: const TextStyle(color: StyleA.armed),
            ),
          ),
        ],
      ),
    ),
  );
}
