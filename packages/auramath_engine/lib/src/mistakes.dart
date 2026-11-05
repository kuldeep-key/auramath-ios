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

/// Every way a child can get "find b" wrong, with the number it gives. A
/// slip that happens to give the right answer (no regrouping needed, a
/// palindrome) cannot happen in this problem, so it is left out.
List<(int, Mistake)> _mistakes(ComparisonProblem p) {
  final a = p.aValue, d = p.diff;
  final all = p.big == BigSide.a
      ? [
          (noBorrow(a, d), Mistake.regrouping),
          (a + d, Mistake.oppositeOp),
          (d, Mistake.gapAsHeight),
          (reverseDigits(p.bValue), Mistake.swappedDigits),
        ]
      : [
          if (dropCarry(a, d) case final carry?) (carry, Mistake.carry),
          (a - d, Mistake.oppositeOp),
          (d, Mistake.gapAsHeight),
          (reverseDigits(p.bValue), Mistake.swappedDigits),
        ];
  return [
    for (final m in all)
      if (m.$1 != p.bValue) m,
  ];
}

/// Every wrong answer to "find b" that maps to a known mistake.
Map<int, Mistake> findBRoutes(ComparisonProblem p) => {
  for (final (n, m) in _mistakes(p)) n: m,
};

/// True when two mistakes give the same number: the app could not tell which
/// help to give, so the problem must not ship.
bool hasCollision(ComparisonProblem p) {
  final numbers = [for (final (n, _) in _mistakes(p)) n];
  return numbers.toSet().length != numbers.length;
}
