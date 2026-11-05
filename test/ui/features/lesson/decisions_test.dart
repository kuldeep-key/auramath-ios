import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Each committed step asks the server's `decisions` (TUT-01, AI-04).
void main() {
  test('a committed step asks after_step with the rules\' own choice and the '
      'step to judge; a correct one defaults to continue', () async {
    final (sessions, _, api) = await memorySessions();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    )..askDecisions = true;
    addTearDown(vm.dispose);
    for (final i in const <LessonInput>[
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.shorter),
      PieceDropped(Piece.gap, Target.gapSlot),
      PieceDropped(Piece.total, Target.totalSlot),
      OpChosen(Op.subtract),
      NumberEntered(81), // forgot to break a ten: the rules open a side lesson
    ]) {
      await vm.send(i);
    }
    await pumpEventQueue();

    expect(api.decisions, isNotEmpty);
    final asks = [for (final (_, body) in api.decisions) body];
    for (final a in asks.take(asks.length - 1)) {
      expect(a['rulesDefault'], 'continue');
      expect(a['allowed'], ['continue']);
    }
    final wrong = asks.last;
    expect(wrong['point'], 'after_step');
    expect(wrong['rulesDefault'], 'side_lesson');
    expect(wrong['allowed'], ['side_lesson', 'hint', 'continue']);
    final step = wrong['step']! as Map<String, Object?>;
    expect(step['value'], 81);
    expect(step['phoneVerdict'], 'incorrect');
    expect(step['A'], 186);
    expect(step['D'], 107);
    // the step it judges is the step_committed event the server holds
    final committed = api.received.lastWhere((e) => e.name == 'step_committed');
    expect(step['eventSeq'], committed.seq);
    expect(vm.state.step, LessonStep.sideLesson); // ours, without waiting
  });
}
