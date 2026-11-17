@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Literals allowed in user-visible positions (store-facing name).
const _allowlist = {'Flaszki'};

Map<String, Object?> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

Set<String> _messageKeys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Hard-coded user-visible literals in [src]: the first string argument of
/// `Text(`/`SelectableText(`, or the value of a label-like named argument.
List<String> hardCodedStrings(String src) {
  const literal = r'''(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''';
  final patterns = [
    RegExp(
      r'\b(?:Text|SelectableText|Tooltip)\(\s*'
      '$literal',
    ),
    RegExp(
      r'\b(?:tooltip|title|label|labelText|hintText|helperText|semanticLabel|'
      r'semanticsLabel|message|applicationName|applicationLegalese)'
      r'\s*:\s*(?:const\s+)?(?:Text\(\s*)?'
      '$literal',
    ),
  ];
  final found = <int, String>{}; // literal end offset → literal
  for (final p in patterns) {
    for (final m in p.allMatches(src)) {
      final s = m.group(1) ?? m.group(2)!;
      // Interpolations are data, not words.
      final words = s
          .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
          .replaceAll(RegExp(r'\$\w+'), '');
      if (RegExp(r'\p{L}', unicode: true).hasMatch(words) &&
          !_allowlist.contains(s)) {
        found[m.end] = s;
      }
    }
  }
  return [for (final k in found.keys.toList()..sort()) found[k]!];
}

void main() {
  test('every ARB message exists in both English and Polish', () {
    final en = _arb('en'), pl = _arb('pl');
    expect(_messageKeys(pl), _messageKeys(en));
    for (final k in _messageKeys(en)) {
      expect((pl[k] as String).trim(), isNotEmpty, reason: k);
      expect(en['@$k'], isNotNull, reason: '@$k description in app_en.arb');
    }
  });

  test('guard spots hard-coded strings and ignores data', () {
    expect(hardCodedStrings("Text('Solved')"), ['Solved']);
    expect(hardCodedStrings("Text(\n  'Level \$n',"), [r'Level $n']);
    expect(hardCodedStrings("tooltip: 'Undo',"), ['Undo']);
    expect(hardCodedStrings("title: const Text('Sound'),"), ['Sound']);
    expect(hardCodedStrings("Text('+\${queue.more}')"), isEmpty);
    expect(hardCodedStrings("title: 'Flaszki',"), isEmpty);
    expect(hardCodedStrings('Text(l10n.solved)'), isEmpty);
  });

  test('lib/ has no hard-coded user-visible strings', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.contains('/l10n/gen/')) continue;
      for (final s in hardCodedStrings(f.readAsStringSync())) {
        offenders.add('${f.path}: "$s"');
      }
    }
    expect(offenders, isEmpty);
  });
}
