import 'package:flame/game.dart';
import 'package:flaszki/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder app shows the game in a portrait column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FlaszkiApp());

    final game = find.byType(GameWidget<FlaszkiGame>);
    expect(game, findsOneWidget);
    final size = tester.getSize(game);
    expect(size.height, 900);
    expect(size.width, lessThan(size.height));
  });
}
