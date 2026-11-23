@TestOn('vm')
library;

import 'dart:io';

import 'package:flaszki/src/audio/game_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final assets = [
    for (final s in Sfx.values)
      for (var v = 0; v < s.variants; v++) s.asset(v),
  ];

  test('every sound asset is a bundled OGG', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/audio/'));
    for (final a in assets) {
      final f = File(a);
      expect(f.existsSync(), isTrue, reason: a);
      expect(String.fromCharCodes(f.readAsBytesSync().take(4)), 'OggS');
    }
  });

  test('every sound asset is credited with a license in CREDITS.md', () {
    final credits = File('CREDITS.md').readAsLinesSync();
    for (final a in assets) {
      final line = credits.where((l) => l.contains(a)).singleOrNull;
      expect(line, isNotNull, reason: a);
      expect(line, anyOf(contains('CC BY 4.0'), contains('CC0')), reason: a);
    }
  });
}
