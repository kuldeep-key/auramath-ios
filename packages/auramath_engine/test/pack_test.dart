import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('pack reads problems by id, timers and badges', () {
    expect(pack.version, 'test-1');
    expect(pack.problems['lemon']!.aValue, 186);
    expect(pack.problems['easier']!.ask, Ask.b);
    expect(pack.timers.pulseMs, 15000);
    expect(pack.timers.stillMs, 60000);
    expect(pack.hintLineIds, ['cmp.hint1', 'cmp.hint2', 'cmp.hint3']);
    expect(pack.badges['tree']!.name, 'Tree Detective');
    expect(pack.lines['cmp.right'], 'Yes! {v} {u}!');
  });
}
