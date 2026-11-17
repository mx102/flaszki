// Renders the app icon PNGs from IconPainter into assets/icon/.
//
//   flutter test tool/render_icon.dart
//   dart run flutter_launcher_icons   # Android, iOS, macOS, web, Windows
//
// Linux loads assets/icon/icon_rounded.png at runtime (my_application.cc).
// The icon is all rights reserved (ADR 0003), not CC BY.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flaszki/src/ui/style/icon_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _render(String name, int px, CustomPainter p, {double pad = 0}) {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final inner = px * (1 - 2 * pad);
  canvas.translate(px * pad, px * pad);
  p.paint(canvas, Size.square(inner));
  return rec.endRecording().toImage(px, px).then((img) async {
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('assets/icon/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  test('render icons', () async {
    // Full-bleed square: iOS, Android legacy, store listings.
    await _render('icon', 1024, const IconPainter());
    // Rounded square: web, Windows, Linux.
    await _render('icon_rounded', 1024, const IconPainter(rounded: true));
    // macOS: rounded square inside Apple's ~10 % margin.
    await _render(
      'icon_macos',
      1024,
      const IconPainter(rounded: true),
      pad: 100 / 1024,
    );
    // Android adaptive layers.
    await _render(
      'icon_foreground',
      1024,
      const IconPainter(foregroundOnly: true),
    );
    await _render(
      'icon_background',
      1024,
      const IconPainter(backgroundOnly: true),
    );
  });
}
