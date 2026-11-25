// Renders the Google Play listing graphics (#32) into
// fastlane/metadata/android/<locale>/images/:
//
//   flutter test tool/render_store.dart
//
// icon.png 512² (IconPainter, full-bleed; Play masks it), featureGraphic.png
// 1024×500, phoneScreenshots/*.png 1080×1920 of the real app in fixed
// states. Deterministic: levels come from `generate`, states from its solver.
// Checked by test/tool/store_listing_test.dart. The icon (also drawn in the
// feature graphic) is all rights reserved (ADR 0003), not CC BY.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flaszki/app.dart';
import 'package:flaszki/src/save/key_value_store.dart';
import 'package:flaszki/src/save/save_store.dart';
import 'package:flaszki/src/ui/style/backdrop_painter.dart';
import 'package:flaszki/src/ui/style/icon_painter.dart';
import 'package:flaszki/src/ui/style/style_a.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _root = 'fastlane/metadata/android';
const _locales = {'en-US': Locale('en'), 'pl-PL': Locale('pl')};

/// Feature graphic tagline per locale.
const _tagline = {
  'en-US': 'Pour. Sort. Seal in order.',
  'pl-PL': 'Przelewaj. Sortuj. Zamykaj po kolei.',
};

const _shot = Size(1080, 1920);
const _shotDpr = 2.7; // 400×711 logical: a typical phone

Future<void> _loadFonts() async {
  Future<ByteData> file(String p) async =>
      ByteData.sublistView(File(p).readAsBytesSync());
  await (FontLoader(StyleA.serif)
        ..addFont(file('assets/fonts/EBGaramond.ttf'))
        ..addFont(file('assets/fonts/EBGaramond-Italic.ttf')))
      .load();
  final sdk = Platform.environment['FLUTTER_ROOT']!;
  await (FontLoader('MaterialIcons')..addFont(
        file(
          '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ),
      ))
      .load();
}

void _write(String path, ByteData png) => File(path)
  ..createSync(recursive: true)
  ..writeAsBytesSync(png.buffer.asUint8List());

Future<ByteData> _png(ui.Image img) async =>
    (await img.toByteData(format: ui.ImageByteFormat.png))!;

/// Solver solution of Level [levelNumber] from its start.
List<Pour> _solution(int levelNumber) =>
    solve(BoardState.initial(generate(levelNumber).level)).solution!;

/// Pours of [levelNumber]'s solution, stopping right after one leaves a
/// Completed Flask waiting (not the queue head) on the board, plus [extra].
List<Pour> _toWaiting(int levelNumber, {int extra = 0}) {
  final sol = _solution(levelNumber);
  var s = BoardState.initial(generate(levelNumber).level);
  for (var k = 0; k < sol.length; k++) {
    s = s.pour(sol[k].from, sol[k].to).state;
    final waiting = [
      for (var i = 0; i < s.flasks.length; i++)
        if (s.isOnBoard(i) && s.flasks[i].isCompleted) i,
    ];
    if (waiting.isNotEmpty) return sol.sublist(0, k + 1 + extra);
  }
  throw StateError('Level $levelNumber: no waiting Completed Flask');
}

/// First Dead End reached from [levelNumber]'s start by a seeded random walk.
List<Pour> _toDeadEnd(int levelNumber) {
  final level = generate(levelNumber).level;
  final rnd = math.Random(1);
  for (var walk = 0; walk < 1000; walk++) {
    var s = BoardState.initial(level);
    final pours = <Pour>[];
    for (var step = 0; step < 80; step++) {
      final legal = [
        for (var a = 0; a < s.flasks.length; a++)
          for (var b = 0; b < s.flasks.length; b++)
            // Never straight back: it only wastes the walk.
            if (s.canPour(a, b) && (pours.isEmpty || pours.last != Pour(b, a)))
              Pour(a, b),
      ];
      if (legal.isEmpty) break;
      final p = legal[rnd.nextInt(legal.length)];
      s = s.pour(p.from, p.to).state;
      pours.add(p);
      if (s.goalQueue.isEmpty) break;
      // A late, mostly-full board reads best; skip trivial early Dead Ends.
      if (pours.length >= 4 && isDeadEnd(s)) return pours;
    }
  }
  throw StateError('Level $levelNumber: no Dead End found');
}

/// One app state for a screenshot.
class _Scene {
  const _Scene(
    this.name,
    this.levelNumber, {
    this.pours = const [],
    this.patterns = false,
    this.pourNow,
    this.captureAfter = const Duration(seconds: 1),
  });

  final String name;
  final int levelNumber;
  final List<Pour> pours;
  final bool patterns;

  /// A Pour tapped after restore, captured mid-animation.
  final Pour? pourNow;

  /// Time from the last input to the capture.
  final Duration captureAfter;
}

List<_Scene> _scenes() {
  final pourScene = _toWaiting(14, extra: 2);
  return [
    _Scene(
      '1_pour',
      14,
      pours: pourScene.sublist(0, pourScene.length - 1),
      pourNow: pourScene.last,
      captureAfter: const Duration(milliseconds: 380),
    ),
    _Scene('2_queue', 38, pours: _toWaiting(38)),
    _Scene('3_patterns', 22, pours: _toWaiting(22), patterns: true),
    _Scene('4_dead_end', 18, pours: _toDeadEnd(18)),
  ];
}

SaveStore _save(_Scene s) {
  final kv = MemoryStore();
  final store = SaveStore(kv, log: (_) {});
  final game = Game(generate(s.levelNumber).level);
  for (final p in s.pours) {
    game.pour(p.from, p.to);
  }
  store
    ..levelStarted(s.levelNumber, game)
    ..saveSettings(Settings(colorblindPatterns: s.patterns, sound: false));
  return SaveStore(kv, log: (_) {}); // as on relaunch
}

Future<void> _capture(
  WidgetTester tester,
  String path, {
  double pixelRatio = 1,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  await tester.runAsync(() async {
    _write(path, await _png(await boundary.toImage(pixelRatio: pixelRatio)));
  });
}

/// Lets the off-thread Dead End check finish, then pumps [d].
Future<void> _awaitDeadEndCheck(WidgetTester tester, Duration d) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pump(d);
}

Widget _featureGraphic(String locale) => Directionality(
  textDirection: TextDirection.ltr,
  child: CustomPaint(
    painter: const BackdropPainter(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 96),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 280,
            child: CustomPaint(painter: IconPainter(rounded: true)),
          ),
          const SizedBox(width: 64),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flaszki',
                  style: TextStyle(
                    fontFamily: StyleA.serif,
                    fontSize: 112,
                    height: 1,
                    color: StyleA.solved,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _tagline[locale]!,
                  style: StyleA.serifItalic.copyWith(fontSize: 34),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  setUpAll(_loadFonts);

  test('icon 512', () async {
    final rec = ui.PictureRecorder();
    const IconPainter().paint(Canvas(rec), const Size.square(512));
    final png = await _png(await rec.endRecording().toImage(512, 512));
    for (final l in _locales.keys) {
      _write('$_root/$l/images/icon.png', png);
    }
  });

  for (final l in _locales.keys) {
    testWidgets('$l feature graphic', (tester) async {
      tester.view
        ..physicalSize = const Size(1024, 500)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(key: const ValueKey('shot'), child: _featureGraphic(l)),
      );
      await _capture(tester, '$_root/$l/images/featureGraphic.png');
    });
  }

  final scenes = _scenes();
  for (final MapEntry(key: l, value: locale) in _locales.entries) {
    for (final s in scenes) {
      testWidgets('$l ${s.name}', (tester) async {
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = true);
        tester.view
          ..physicalSize = _shot
          ..devicePixelRatio = _shotDpr;
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('shot'),
            child: FlaszkiApp(
              levelSource: (n) => SynchronousFuture(generate(n)),
              save: _save(s),
            ),
          ),
        );
        await _awaitDeadEndCheck(tester, const Duration(seconds: 2));
        if (s.pourNow case final p?) {
          await tester.tap(find.byKey(ValueKey('flask-${p.from}')));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.byKey(ValueKey('flask-${p.to}')));
          await tester.pump();
        }
        await tester.pump(s.captureAfter);
        await _capture(
          tester,
          '$_root/$l/images/phoneScreenshots/${s.name}.png',
          pixelRatio: _shotDpr,
        );
        // Let pending animations and timers finish before teardown.
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }
}
