import 'dart:io';

import 'package:test/test.dart';

/// ADR 0001: the logic package stays pure Dart so it runs headless and on
/// every target. It must never import Flutter, Flame or dart:ui.
void main() {
  test('logic package imports no Flutter, Flame or dart:ui', () {
    final forbidden = RegExp(
      r'''^\s*(import|export)\s+['"](package:(flutter|flame)[a-z_]*/|dart:ui)''',
      multiLine: true,
    );
    final offenders = <String>[];
    for (final dir in ['lib', 'test', 'bin']) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final f in d.listSync(recursive: true).whereType<File>()) {
        if (f.path.endsWith('.dart') &&
            forbidden.hasMatch(f.readAsStringSync())) {
          offenders.add(f.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('pubspec declares no Flutter or Flame dependency', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      isNot(contains(RegExp(r'^\s+(flutter|flame)[a-z_]*:', multiLine: true))),
    );
  });
}
