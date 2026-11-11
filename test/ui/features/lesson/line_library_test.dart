import 'package:auramath/ui/features/lesson/view_models/line_library.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// TUT-11: the lines come from Julia's policy library wherever it holds
/// them; the pack's own text is only for lines it doesn't hold yet.
void main() {
  final pack = samplePack();
  final lines = LineLibrary(pack);
  final lemon = pack.problems['lemon']!;

  test('every pack line the library maps is a policy line', () {
    expect(pack.libraryIds, isNotEmpty);
    for (final MapEntry(:key, :value) in pack.libraryIds.entries) {
      expect(pack.policyLines, contains(value), reason: key);
      expect(lines.fromLibrary(key), isTrue, reason: key);
    }
    expect(lines.line('cmp.drawIt', lemon), 'Do we know which tree is taller?');
    expect(
      lines.line('cmp.gapWrong', lemon),
      'Is the fig tree 107 cm tall, or 107 cm shorter than the lemon tree?',
    );
  });

  test('a weight story takes the policy mass words', () {
    const bowl = ComparisonProblem(
      id: 'bowl',
      a: Item(name: 'Bowl', pic: '🥣'),
      b: Item(name: 'Mug', pic: '☕'),
      aValue: 320,
      diff: 140,
      big: BigSide.a,
      unit: 'g',
      ask: Ask.total,
      text: '',
      say: '',
      next: NextProblems(fast: 'f', helped: 'h', easier: 'e'),
      templateId: 'cmp.comparison',
      templateVersion: '0.3.0',
      storyId: 'bowl-mug',
      variant: 'standard',
    );
    expect(
      lines.line('line.hint.taller-or-shorter', bowl),
      'Is the mug heavier or lighter than the bowl?',
    );
    expect(policySlots(bowl)['problem_name'], 'Bowl and Mug Word Problem');
  });

  test('the lines the library does not hold yet, for Julia (CON-09)', () {
    final gaps = [
      for (final id in pack.lines.keys)
        if (!lines.fromLibrary(id)) id,
    ];
    // step lines, wrong-move lines and side-lesson lines drafted by Key
    expect(gaps, containsAll(['cmp.drawA', 'cmp.tryAgain', 'cmp.sideBack']));
    expect(gaps, isNot(contains('cmp.recheck')));
  });
}
