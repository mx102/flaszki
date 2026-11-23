import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_version.dart';

const _pubspec = '''
name: flaszki
description: "x"
version: 1.2.3+7

environment:
  sdk: ^3.14.0
''';

void main() {
  group('releaseVersion', () {
    test('tag matching pubspec version yields build name', () {
      expect(releaseVersion('v1.2.3', _pubspec), '1.2.3');
    });

    test('accepts full refs/tags/ ref', () {
      expect(releaseVersion('refs/tags/v1.2.3', _pubspec), '1.2.3');
    });

    test('pubspec without build number', () {
      expect(releaseVersion('v0.1.0', 'name: a\nversion: 0.1.0\n'), '0.1.0');
    });

    test('rejects tag not matching pubspec', () {
      expect(
        () => releaseVersion('v1.2.4', _pubspec),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed tags', () {
      for (final tag in ['1.2.3', 'v1.2', 'v1.2.3-rc1', 'v1.2.3+7', 'vx.y.z']) {
        expect(
          () => releaseVersion(tag, _pubspec),
          throwsA(isA<FormatException>()),
          reason: tag,
        );
      }
    });

    test('rejects pubspec without version', () {
      expect(
        () => releaseVersion('v1.2.3', 'name: a\n'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
