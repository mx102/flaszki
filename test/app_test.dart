import 'package:flaszki/app.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shows the game in a full-height portrait column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      FlaszkiApp(levelSource: (n) => SynchronousFuture(generate(n))),
    );

    final size = tester.getSize(find.byKey(const ValueKey('column')));
    expect(size.height, 900);
    expect(size.width, lessThan(size.height));
  });
}
