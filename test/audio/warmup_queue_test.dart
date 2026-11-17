import 'package:flaszki/src/audio/warmup_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var now = Duration.zero;
  late WarmupQueue<String> q;
  setUp(() {
    now = Duration.zero;
    q = WarmupQueue(maxAge: const Duration(milliseconds: 300), now: () => now);
  });

  test('sounds asked for while the engine loads play once it is ready', () {
    q.add('clink');
    now = const Duration(milliseconds: 100);
    q.add('glug');
    expect(q.drain(), ['clink', 'glug']);
    expect(q.drain(), isEmpty);
  });

  test('sounds too old by the time it is ready are dropped (not late)', () {
    q.add('clink');
    now = const Duration(milliseconds: 250);
    q.add('glug');
    now = const Duration(milliseconds: 301);
    expect(q.drain(), ['glug']);
  });
}
