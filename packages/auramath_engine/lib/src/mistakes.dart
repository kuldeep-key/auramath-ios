import 'problem.dart';

/// The mistake a wrong number shows, so the right help can follow.
enum Mistake { regrouping, carry, oppositeOp, gapAsHeight, swappedDigits }

/// Subtraction without regrouping: each column's digits subtracted the
/// smaller from the larger, right-aligned. 186 − 107 gives 81.
int noBorrow(int x, int y) {
  final xs = x.toString().split('').reversed.toList();
  final ys = y.toString().split('').reversed.toList();
  final digits = [
    for (var i = 0; i < xs.length; i++)
      (int.parse(xs[i]) - (i < ys.length ? int.parse(ys[i]) : 0)).abs(),
  ];
  return int.parse(digits.reversed.join());
}

/// Addition that forgets the carry from the ones, or null when the ones do
/// not carry.
int? dropCarry(int x, int y) => (x % 10) + (y % 10) >= 10 ? x + y - 10 : null;

int reverseDigits(int n) => int.parse(n.toString().split('').reversed.join());

/// Every wrong answer to "find b" that maps to a known mistake.
Map<int, Mistake> findBRoutes(ComparisonProblem p) {
  final a = p.aValue, d = p.diff;
  if (p.big == BigSide.a) {
    return {
      noBorrow(a, d): Mistake.regrouping,
      a + d: Mistake.oppositeOp,
      d: Mistake.gapAsHeight,
      reverseDigits(p.bValue): Mistake.swappedDigits,
    };
  }
  return {
    ?dropCarry(a, d): Mistake.carry,
    a - d: Mistake.oppositeOp,
    d: Mistake.gapAsHeight,
    reverseDigits(p.bValue): Mistake.swappedDigits,
  };
}

/// True when two mistakes give the same number, or a mistake gives the right
/// answer: the app could not tell which help to give.
bool hasCollision(ComparisonProblem p) {
  final a = p.aValue, d = p.diff;
  final numbers = p.big == BigSide.a
      ? [noBorrow(a, d), a + d, d, reverseDigits(p.bValue)]
      : [?dropCarry(a, d), a - d, d, reverseDigits(p.bValue)];
  return numbers.toSet().length != numbers.length || numbers.contains(p.bValue);
}
