import 'package:flaszki/src/play/restart_arm.dart';
import 'package:flutter_test/flutter_test.dart';

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  test('first press arms, second press within ~2 s restarts', () {
    final a = RestartArm();
    expect(a.press(_ms(0)), isFalse);
    expect(a.isArmed(_ms(1000)), isTrue);
    expect(a.press(_ms(1500)), isTrue);
    expect(a.isArmed(_ms(1500)), isFalse);
  });

  test('arm expires after ~2 s; a late press only re-arms', () {
    final a = RestartArm();
    a.press(_ms(0));
    expect(a.isArmed(_ms(2100)), isFalse);
    expect(a.press(_ms(2100)), isFalse);
    expect(a.isArmed(_ms(2200)), isTrue);
  });

  test('disarm cancels', () {
    final a = RestartArm()..press(_ms(0));
    a.disarm();
    expect(a.isArmed(_ms(10)), isFalse);
    expect(a.press(_ms(20)), isFalse);
  });

  test('remaining reports time left while armed', () {
    final a = RestartArm()..press(_ms(500));
    expect(a.remaining(_ms(1000)), _ms(1500));
    expect(a.remaining(_ms(3000)), Duration.zero);
  });
}
