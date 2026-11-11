import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'tutor_harness.dart';

/// TUT-12: after a solved problem the child sees Julia's
/// line.praise.solved, naming the problem in plain words, and no step.
void main() {
  const solve = [...toFindB, NumberEntered(79), NumberEntered(265)];

  testWidgets('the finish screen says "You solved the Tree Word Problem!"', (
    tester,
  ) async {
    final t = await pumpLesson(tester);
    await t.send(solve);
    expect(find.text('Case cracked!'), findsOneWidget);
    expect(find.text('You solved the Tree Word Problem!'), findsOneWidget);
    expect(find.text('You solved the case!'), findsNothing);
  });

  testWidgets("the content bundle's praise wins over the bundled policy", (
    tester,
  ) async {
    final t = await pumpLesson(
      tester,
      pack: samplePack().withPraise({
        'line.praise.solved': 'You solved the {problem_name}, detective!',
      }),
    );
    await t.send(solve);
    expect(
      find.text('You solved the Tree Word Problem, detective!'),
      findsOneWidget,
    );
  });
}
