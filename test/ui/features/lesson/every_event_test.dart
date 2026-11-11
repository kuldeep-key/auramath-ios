import 'dart:convert';
import 'dart:io';

import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// @DAT-03: a full problem produces an event for every interaction in
/// contracts/events.schema.json. The few no one problem can write are
/// named, with why, so a new contract event fails here until it's emitted
/// or listed.
const notInOneProblem = {
  'placement_answered': 'the starting check, before the first case',
  'quick_sum_answered': 'Quick sums, and practice after a side lesson',
  'problem_left': 'leaving a case ends it',
  'easier_chosen': 'something easier switches the case',
  'self_rating_given': 'the self_rating flag, after a solved case',
  'prompt_offered': 'the server\'s decision (ai_decisions)',
  'number_sentence_entered': 'the optional number_sentence step (LES-06)',
  'word_meaning_opened': 'tap a word (LES-10), behind its flag',
  'badge_shared': 'the grown-up\'s screens',
  'streak_moment_shown': 'Home, after a case',
  'avatar_chosen': 'set-up (ACC-12)',
};

void main() {
  test('a full problem emits every interaction event', () async {
    final policy = Policy.fromYaml(
      File('assets/spec/policy.yaml').readAsStringSync(),
    );
    final (sessions, db, _) = await memorySessions();
    var now = 1000;
    final vm = LessonViewModel(
      pack: samplePack().copyWith(
        questionButtons: policy.questionButtons,
        policyLines: policy.lines,
      ),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      nowMs: () => now += 700,
      tickEvery: null,
    )..childQuestions = true;
    await vm.start();
    vm.readQuestion();
    await vm.send(const Started());
    vm
      ..seeQuestion()
      ..closeQuestion()
      ..ask(vm.questions.first);
    // I know it, then back to drawing
    vm.openKnowIt();
    await vm.answer(256); // swapped digits: check again
    vm.closeKnowIt();
    await vm.send(const QuietFor(16000));
    vm.promptAnswered('still_there', 'still_thinking');
    await vm.send(const HintTaken());
    await vm.send(const BarADrawn());
    await vm.send(const BarBPlaced());
    await vm.send(const BarBSized(Relation.shorter));
    // the gap on the fig bar, taken back; again, and moved on
    await vm.send(const PieceDropped(Piece.gap, Target.barB));
    await vm.send(const Undo());
    await vm.send(const PieceDropped(Piece.gap, Target.barB));
    await vm.send(const PieceDropped(Piece.gap, Target.gapSlot));
    await vm.send(const PieceDropped(Piece.total, Target.totalSlot));
    await vm.send(const OpChosen(Op.subtract));
    vm.showEasierSentence();
    await vm.send(const NumberEntered(81)); // the take-away side lesson
    await vm.send(const SideLessonDone());
    await vm.send(const ShowMeHowTaken());
    vm.closeExample();
    await vm.paused();
    await vm.resumed();
    sessions.online.value = false;
    sessions.online.value = true;
    await vm.send(const NumberEntered(79));
    await vm.send(const NumberEntered(265));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(vm.state.step, LessonStep.solved);

    final events = await db.forSession('s1');
    expectContract(events);
    final schema =
        jsonDecode(
              File(
                'packages/auramath_engine/test/contract/events.schema.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final contract = ((schema[r'$defs']! as Map).keys).cast<String>().toSet();
    final emitted = events.map((e) => e.name).toSet();
    expect(
      contract.difference(emitted).difference(notInOneProblem.keys.toSet()),
      isEmpty,
      reason: 'contract events this problem never wrote',
    );
    // every ms_from_step_start is a time since its step began
    expect([
      for (final e in events)
        if (e.payload['ms_from_step_start'] case final int ms) ms,
    ], everyElement(isNonNegative));
    vm.dispose();
  });
}
