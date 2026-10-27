import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('noBorrow(186, 107) is the regrouping slip 81', () {
    expect(noBorrow(186, 107), 81);
  });

  test('dropCarry(186, 79) forgets the carry: 255', () {
    expect(dropCarry(186, 79), 255);
  });

  test('dropCarry is null when the ones do not carry', () {
    expect(dropCarry(152, 84), isNull);
  });

  test('reverseDigits(79) is 97', () {
    expect(reverseDigits(79), 97);
  });

  test('lemon find-the-fig-tree routes', () {
    expect(findBRoutes(lemon), {
      81: Mistake.regrouping,
      293: Mistake.oppositeOp,
      107: Mistake.gapAsHeight,
      97: Mistake.swappedDigits,
    });
    expect(hasCollision(lemon), isFalse);
  });

  test('a problem whose slip equals the answer collides', () {
    final p = ComparisonProblem.fromJson(problemJson('x', a: 11, diff: 1));
    expect(hasCollision(p), isTrue);
  });
}
