import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Shakes [child] sideways each time [trigger] changes. Never blocks input.
class Shake extends StatefulWidget {
  const Shake({
    super.key,
    required this.trigger,
    required this.amplitude,
    required this.child,
  });

  final int trigger;
  final double amplitude;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final t = _c.value;
      final dx = t == 0 || t == 1
          ? 0.0
          : math.sin(t * math.pi * 6) * (1 - t) * widget.amplitude;
      return Transform.translate(offset: Offset(dx, 0), child: child);
    },
  );
}
