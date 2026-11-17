/// Golden fingerprints of Levels 1–100 for the current `generatorVersion`
/// (ADR 0002). Shared by `golden_test.dart` (VM, dart2js, dart2wasm) and
/// `tool/golden.dart` (AOT; `--print` regenerates this table).
library;

import 'package:flaszki_logic/flaszki_logic.dart';
// ignore: implementation_imports
import 'package:flaszki_logic/src/prng.dart' show mul32;

/// FNV-1a-style 32-bit fingerprint of a Level's Flasks and Goal Queue,
/// platform-stable (uint32 ops via [mul32] only).
int levelHash(Level level) {
  var h = 0x811c9dc5;
  void add(int x) => h = mul32(h ^ x, 0x01000193);
  add(level.flasks.length);
  for (final f in level.flasks) {
    add(0x100 + f.layers.length);
    f.layers.forEach(add);
  }
  add(0x200 + level.goalQueue.length);
  level.goalQueue.forEach(add);
  return h;
}

const int goldenGeneratorVersion = 1;

/// `goldenHashes[n - 1]` = `levelHash(generate(n).level)`.
const List<int> goldenHashes = [
  0x0f3d9370,
  0xfeeb216e,
  0xd163692a,
  0xba12d0c5,
  0x32f260e0,
  0xb870de3d,
  0xa5388b13,
  0xc8ee0ef7,
  0x2307956d,
  0x1a506a3c,
  0x11d1dbc1,
  0xdbc83330,
  0x29df53de,
  0x5355d182,
  0x2c9addbb,
  0xf6c310fc,
  0x7d898b90,
  0xffef486c,
  0x628c8d50,
  0x8e37e77e,
  0x21ba4d8f,
  0x1da4d6ad,
  0x40871f6f,
  0x58bc3ae5,
  0x142c7af4,
  0x90b647f9,
  0x8a819afb,
  0x6f120144,
  0x5965f67c,
  0xd2721ae3,
  0x9f817fc4,
  0x21012294,
  0x02ab2f00,
  0xfdaebef4,
  0xf2dea231,
  0x4dbd2827,
  0x008baa19,
  0xc7cfbc1b,
  0x8c1dc2bb,
  0x194be160,
  0xd3f5fbb7,
  0x0c48ae62,
  0xb768931b,
  0xda2ce844,
  0x3a648ed1,
  0x614f5e0f,
  0x08a472a1,
  0x8c63c6fc,
  0xc138d6a7,
  0x59be6499,
  0xb9b4ed8d,
  0x2168ede3,
  0xf0c554db,
  0x7b41b8f2,
  0x1472f1a1,
  0x302e7a84,
  0x929ac3db,
  0x5341f575,
  0x315bfea9,
  0xc74cb613,
  0x88aa6147,
  0xc2eae18c,
  0xb410da9b,
  0x03746f07,
  0x93037855,
  0x25005e48,
  0x67d64709,
  0xd73e17c8,
  0x33cd5871,
  0xece74381,
  0x6e6b2be5,
  0x8a50614c,
  0xd02eb567,
  0x5783b6f2,
  0x85a7b4d9,
  0xedf13945,
  0x9e02ae35,
  0x5ae975c0,
  0x35aff48f,
  0x51244ba3,
  0x8aa933d7,
  0xabfe3755,
  0xa360c775,
  0x6a839d42,
  0x87101433,
  0xf15be78c,
  0x0ac3a465,
  0xff308239,
  0x400a0b85,
  0x243ffde5,
  0x7fe239bd,
  0x35d4a478,
  0x97159d9b,
  0xa74572af,
  0x028f8cb3,
  0x48a0f8fe,
  0x57bc4cf3,
  0x25678b4a,
  0xeecf65d9,
  0x0105943f,
];
