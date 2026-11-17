import 'package:material_ui/material_ui.dart';

import 'style/style_a.dart';

/// Non-modal Dead End hint (PRD §4.4) with inline Undo and Restart (this
/// Restart needs no confirm). Strings localized in #30; look in #26.
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
              'No way to finish from here',
              style: StyleA.serifItalic.copyWith(fontSize: 16),
            ),
          ),
          TextButton(
            key: const ValueKey('dead-end-undo'),
            onPressed: onUndo,
            child: const Text('Undo', style: TextStyle(color: StyleA.text)),
          ),
          TextButton(
            key: const ValueKey('dead-end-restart'),
            onPressed: onRestart,
            child: const Text('Restart', style: TextStyle(color: StyleA.armed)),
          ),
        ],
      ),
    ),
  );
}
