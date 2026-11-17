// Release tag check (PRD §11, ADR 0007): a `vX.Y.Z` tag must match the
// `version:` in pubspec.yaml (build number ignored; CI uses the run number).
//
// Usage: dart run tool/release_version.dart <tag or refs/tags/tag>
// Prints the build name (X.Y.Z) on success; exits 1 with a message otherwise.
import 'dart:io';

final _tag = RegExp(r'^(?:refs/tags/)?v(\d+\.\d+\.\d+)$');
final _version = RegExp(
  r'^version:\s*(\d+\.\d+\.\d+)(?:\+\d+)?\s*$',
  multiLine: true,
);

/// Returns the build name `X.Y.Z` if [tag] is `vX.Y.Z` and matches the
/// pubspec version; throws [FormatException] otherwise.
String releaseVersion(String tag, String pubspec) {
  final t = _tag.firstMatch(tag);
  if (t == null) throw FormatException('Tag must be vX.Y.Z', tag);
  final v = _version.firstMatch(pubspec);
  if (v == null) throw const FormatException('No X.Y.Z version in pubspec');
  if (t[1] != v[1]) {
    throw FormatException('Tag ${t[1]} != pubspec version ${v[1]}', tag);
  }
  return t[1]!;
}

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/release_version.dart <tag>');
    exit(64);
  }
  try {
    stdout.writeln(
      releaseVersion(args[0], File('pubspec.yaml').readAsStringSync()),
    );
  } on FormatException catch (e) {
    stderr.writeln('Release version check failed: ${e.message} (${e.source})');
    exit(1);
  }
}
