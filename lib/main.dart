import 'package:flutter/widgets.dart';

import 'app.dart';
import 'src/save/key_value_store.dart';
import 'src/save/save_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final kv = await SharedPrefsStore.open(schemaVersions.keys.toSet());
  runApp(FlaszkiApp(save: SaveStore(kv)));
}
