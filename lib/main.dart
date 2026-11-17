import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'src/audio/soloud_audio_out.dart';
import 'src/save/key_value_store.dart';
import 'src/save/save_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final kv = await SharedPrefsStore.open(schemaVersions.keys.toSet());
  String? version;
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } on Object catch (e) {
    debugPrint('version unavailable: $e');
  }
  final audio = SoloudAudioOut();
  if (!kIsWeb) unawaited(audio.start()); // web: on first tap (unlock)
  runApp(FlaszkiApp(save: SaveStore(kv), version: version, audioOut: audio));
}
