import 'dart:convert';

import 'package:flaszki/app.dart';
import 'package:flaszki/src/save/key_value_store.dart';
import 'package:flaszki/src/save/save_store.dart';
import 'package:flaszki/src/ui/color_fill.dart';
import 'package:flaszki/src/ui/style/orb_painter.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

final _sheet = find.byKey(const ValueKey('settings-sheet'));
final _patterns = find.byKey(const ValueKey('settings-patterns'));
final _sound = find.byKey(const ValueKey('settings-sound'));

void main() {
  late MemoryStore disk;
  late List<Uri> opened;

  /// Launches the app over [disk]; a new call = kill + relaunch.
  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox()); // kill
    await tester.pumpWidget(
      FlaszkiApp(
        levelSource: (n) => SynchronousFuture(generate(n)),
        save: SaveStore(disk),
        version: '1.2.3+4',
        openUrl: (u) async {
          opened.add(u);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('settings')));
    await tester.pumpAndSettle();
    expect(_sheet, findsOneWidget);
  }

  /// Painters of every Flask + Goal Queue orb.
  Iterable<PatternedPainter> fills(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((c) => c.painter)
      .whereType<PatternedPainter>();

  setUp(() {
    disk = MemoryStore();
    opened = [];
  });

  testWidgets('gear opens the sheet with all PRD §4.6 items', (tester) async {
    await launch(tester);
    await openSheet(tester);
    expect(find.text('Colorblind patterns'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Credits and licenses'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.textContaining('1.2.3+4'), findsOneWidget);
  });

  testWidgets('defaults: patterns off, sound on; no patterns painted', (
    tester,
  ) async {
    await launch(tester);
    expect(fills(tester), isNotEmpty);
    expect(fills(tester).every((f) => !f.patterned), isTrue);
    await openSheet(tester);
    expect(tester.widget<SwitchListTile>(_patterns).value, isFalse);
    expect(tester.widget<SwitchListTile>(_sound).value, isTrue);
  });

  testWidgets('patterns toggle paints Layers + orbs, persists on relaunch', (
    tester,
  ) async {
    await launch(tester);
    await openSheet(tester);
    await tester.tap(_patterns);
    await tester.pumpAndSettle();
    expect(jsonDecode(disk.data['settings']!)['colorblindPatterns'], isTrue);
    expect(fills(tester).every((f) => f.patterned), isTrue);

    await launch(tester);
    expect(fills(tester).every((f) => f.patterned), isTrue);
    expect(find.byKey(const ValueKey('orb-next')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('orb-next')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter is OrbPainter &&
              (w.painter! as OrbPainter).patterned,
        ),
      ),
      findsOneWidget,
    );
    await openSheet(tester);
    expect(tester.widget<SwitchListTile>(_patterns).value, isTrue);
  });

  testWidgets('sound toggle persists on relaunch', (tester) async {
    await launch(tester);
    await openSheet(tester);
    await tester.tap(_sound);
    await tester.pumpAndSettle();
    expect(jsonDecode(disk.data['settings']!)['sound'], isFalse);

    await launch(tester);
    await openSheet(tester);
    expect(tester.widget<SwitchListTile>(_sound).value, isFalse);
  });

  testWidgets('Back closes the sheet', (tester) async {
    await launch(tester);
    await openSheet(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets('Esc closes the sheet', (tester) async {
    await launch(tester);
    await openSheet(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
  });

  testWidgets('Privacy opens PRIVACY.md on the Pages site', (tester) async {
    await launch(tester);
    await openSheet(tester);
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://flaszki.pages.dev/PRIVACY.md')]);
  });

  testWidgets('Credits shows CREDITS.md and opens the license page', (
    tester,
  ) async {
    await launch(tester);
    await openSheet(tester);
    await tester.tap(find.text('Credits and licenses'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Third-party assets'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('credits-licenses')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Flaszki'), findsWidgets);
    expect(find.text('Powered by Flutter'), findsOneWidget);
  });
}
