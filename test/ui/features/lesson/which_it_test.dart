import 'package:auramath/ui/features/lesson/views/which_it.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'tutor_harness.dart';

/// TUT-16: on size_second_bar the ladder asks which tree "it" means
/// (H1-4a); a wrong pick wobbles and leads to the highlight (H1-4b).
void main() {
  test('the question splits at "it" and the thing it means', () {
    final parts = itParts(
      'The lemon tree is 186 cm tall. It is 107 cm taller than the fig tree.',
      'lemon tree',
    );
    expect(
      [
        for (final (t, lit) in parts)
          if (lit) t,
      ],
      ['lemon tree', 'It'],
    );
    expect(parts.map((p) => p.$1).join(), contains('fig tree'));
  });

  testWidgets('H1-4a asks with a pick; a wrong pick shows H1-4b, the '
      'highlight; the right one closes it', (tester) async {
    final t = await pumpLesson(tester);
    await t.send([...toSizeB, const HintTaken(), const HintTaken()]);
    expect(find.byKey(const Key('whichIt')), findsNothing);
    await t.send([const HintTaken()]);
    expect(
      find.text("Which tree does 'it' mean: the lemon tree or the fig tree?"),
      findsOneWidget,
    );
    expect(find.byKey(const Key('whichIt')), findsOneWidget);
    expect(t.vm.highlightIt, isFalse);
    final buttons = find.text('The fig tree');
    expect(tester.getSize(buttons.first).height, greaterThan(0));
    await t.tap(buttons);
    expect(t.vm.wobbles, 1);
    expect(t.vm.state.wrong, 0, reason: 'not charged');
    expect(t.vm.highlightIt, isTrue);
    expect(
      find.text("Look at the words in colour. Which tree is 'it'?"),
      findsOneWidget,
    );
    final shown = [
      for (final e in t.api.received)
        if (e.name == 'hint_shown') e.payload['rung_id'],
    ];
    expect(shown, ['H1-3', 'H1-4', 'H1-4a', 'H1-4b']);
    await t.tap(find.text('The lemon tree'));
    expect(find.byKey(const Key('whichIt')), findsNothing);
    expect(find.textContaining("'It' is the lemon tree"), findsOneWidget);
    expectContract(t.api.received);
  });

  testWidgets('the pick buttons are 56 pt or more (NFR-02)', (tester) async {
    final t = await pumpLesson(tester);
    await t.send([...toSizeB, for (var i = 0; i < 3; i++) const HintTaken()]);
    for (final name in ['The lemon tree', 'The fig tree']) {
      final button = find.ancestor(
        of: find.text(name),
        matching: find.byType(Semantics),
      );
      expect(tester.getSize(button.first).height, greaterThanOrEqualTo(56));
    }
  });
}
