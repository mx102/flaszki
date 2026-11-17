import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

/// Portrait aspect of the game column (ADR 0006).
const double kPortraitAspect = 9 / 16;

/// Placeholder game; the board lands in later tickets.
class FlaszkiGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF1B2440);
}

/// Root widget: the game drawn as a portrait column centred in the window,
/// background filling the sides on desktop/web (ADR 0006).
class FlaszkiApp extends StatefulWidget {
  const FlaszkiApp({super.key});

  @override
  State<FlaszkiApp> createState() => _FlaszkiAppState();
}

class _FlaszkiAppState extends State<FlaszkiApp> {
  final _game = FlaszkiGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flaszki',
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: const Color(0xFF0F1528),
        child: Center(
          child: AspectRatio(
            aspectRatio: kPortraitAspect,
            child: GameWidget<FlaszkiGame>(game: _game),
          ),
        ),
      ),
    );
  }
}
