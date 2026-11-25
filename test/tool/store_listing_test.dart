// Play listing (fastlane `supply` layout, #32): text within Play's limits,
// graphics at Play's required sizes. Regenerate graphics with
// `flutter test tool/render_store.dart`.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _root = 'fastlane/metadata/android';
const _locales = ['en-US', 'pl-PL'];

String _text(String locale, String name) =>
    File('$_root/$locale/$name').readAsStringSync().trim();

/// PNG width × height from the IHDR chunk.
(int, int) _pngSize(String path) {
  final b = ByteData.sublistView(File(path).readAsBytesSync());
  expect(b.getUint32(0), 0x89504E47, reason: '$path is not a PNG');
  return (b.getUint32(16), b.getUint32(20));
}

void main() {
  for (final l in _locales) {
    group(l, () {
      test('text within Play limits', () {
        expect(_text(l, 'title.txt').length, inInclusiveRange(1, 30));
        expect(
          _text(l, 'short_description.txt').length,
          inInclusiveRange(1, 80),
        );
        expect(
          _text(l, 'full_description.txt').length,
          inInclusiveRange(1, 4000),
        );
        expect(
          _text(l, 'changelogs/default.txt').length,
          inInclusiveRange(1, 500),
        );
      });

      test('icon 512², feature graphic 1024×500', () {
        expect(_pngSize('$_root/$l/images/icon.png'), (512, 512));
        expect(_pngSize('$_root/$l/images/featureGraphic.png'), (1024, 500));
      });

      test('2–8 portrait 9:16 phone screenshots', () {
        final shots = Directory('$_root/$l/images/phoneScreenshots')
            .listSync()
            .map((f) => f.path)
            .where((p) => p.endsWith('.png'))
            .toList();
        expect(shots.length, inInclusiveRange(2, 8));
        for (final s in shots) {
          expect(_pngSize(s), (1080, 1920), reason: s);
        }
      });
    });
  }
}
