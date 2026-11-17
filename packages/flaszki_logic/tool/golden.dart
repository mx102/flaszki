/// Golden runner for Levels 1–100 (ADR 0002), for AOT checks:
///
///     dart compile exe tool/golden.dart -o build/golden && build/golden
///
/// Exits 1 on any mismatch with `test/golden_levels.dart`. `--print` prints a
/// fresh table to paste there after an intentional `generatorVersion` bump.
library;

import 'dart:io';

import 'package:flaszki_logic/flaszki_logic.dart';

import '../test/golden_levels.dart';

void main(List<String> args) {
  final got = [for (var n = 1; n <= 100; n++) levelHash(generate(n).level)];
  if (args.contains('--print')) {
    print('const int goldenGeneratorVersion = $generatorVersion;');
    print('const List<int> goldenHashes = [');
    for (final h in got) {
      print('  0x${h.toRadixString(16).padLeft(8, '0')},');
    }
    print('];');
    return;
  }
  var bad = 0;
  if (generatorVersion != goldenGeneratorVersion) {
    stderr.writeln(
      'generatorVersion $generatorVersion != golden '
      '$goldenGeneratorVersion',
    );
    bad++;
  }
  for (var n = 1; n <= 100; n++) {
    final want = n <= goldenHashes.length ? goldenHashes[n - 1] : null;
    if (got[n - 1] != want) {
      stderr.writeln(
        'Level $n: got ${got[n - 1].toRadixString(16)}, '
        'want ${want?.toRadixString(16)}',
      );
      bad++;
    }
  }
  if (bad > 0) exit(1);
  print('golden OK: Levels 1–100 (generatorVersion $generatorVersion)');
}
