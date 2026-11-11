import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

/// @NFR-02: every target on the lesson's screens is 56 pt or more, at
/// every size (shotAllSizes checks the 56 pt guideline on child screens).
void main() {
  const toFindB = <LessonInput>[
    Started(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.shorter),
    PieceDropped(Piece.gap, Target.gapSlot),
    PieceDropped(Piece.total, Target.totalSlot),
    OpChosen(Op.subtract),
  ];

  void none(LessonViewModel vm) {}
  for (final (name, inputs, then) in [
    ('lesson_question', const <LessonInput>[], none),
    ('lesson_board_draw', const [Started()], none),
    ('lesson_board_size', toFindB.take(3).toList(), none),
    (
      'lesson_board_misplaced',
      [...toFindB.take(4), const PieceDropped(Piece.gap, Target.barB)],
      none,
    ),
    ('lesson_board_choose', toFindB.take(6).toList(), none),
    ('lesson_board_find', toFindB, none),
    ('lesson_see_question', const [Started()], (vm) => vm.seeQuestion()),
    ('lesson_answer_sheet', const [Started()], (vm) => vm.openKnowIt()),
    ('lesson_side_lesson', [...toFindB, const NumberEntered(81)], none),
    ('lesson_time_up', const [Started()], (vm) => vm.timeUp = true),
  ]) {
    testWidgets('$name: child targets are 56 pt', (tester) async {
      final vm = (await tester.runAsync(() async {
        final (sessions, _, _) = await memorySessions();
        final vm = LessonViewModel(
          pack: samplePack(),
          problemId: 'lemon',
          sessionId: 's1',
          sessions: sessions,
          voice: FakeVoice(),
          openSession: sessions.open,
          sitting: Sitting(capMs: 30 * 60 * 1000),
          tickEvery: null,
        );
        await vm.start();
        for (final i in inputs) {
          await vm.send(i);
        }
        then(vm);
        return vm;
      }))!;
      addTearDown(vm.dispose);
      await shotAllSizes(
        tester,
        name,
        LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {}),
      );
    });
  }

  test('the 56 pt check covers the lesson and the child\'s home', () {
    expect(isChildShot('lesson_board_draw'), isTrue);
    expect(isChildShot('child_home_home'), isTrue);
    expect(isChildShot('grown_ups_home'), isFalse);
  });
}
