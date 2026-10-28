import 'package:auramath/ui/core/parts/standing_button.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  final pack = samplePack();
  var now = 0;

  Future<LessonViewModel> makeVm({String sessionId = 's1'}) async {
    final (sessions, _, _) = await memorySessions();
    return LessonViewModel(
      pack: pack,
      problemId: 'lemon',
      sessionId: sessionId,
      sessions: sessions,
      voice: FakeVoice(),
      nowMs: () => now,
      newSessionId: () => 's2',
      tickEvery: null,
    );
  }

  test('fillLine fills all slots', () {
    expect(
      fillLine('Is the {b} {d} {u} tall?', {
        'b': 'fig tree',
        'd': '107',
        'u': 'cm',
      }),
      'Is the fig tree 107 cm tall?',
    );
  });

  test('accepted input is recorded, ignored input is not', () async {
    final vm = await makeVm();
    await vm.send(const Started());
    await vm.send(const NumberEntered(79)); // not valid while drawing
    expect(vm.recorded, 1);
    expect(vm.state.step, LessonStep.drawA);
    expect(vm.coachText, 'Drag a bar up here.');
    vm.dispose();
  });

  test('each board step says its own line', () async {
    final vm = await makeVm();
    final lines = <String>[];
    for (final i in const [
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.shorter),
      PieceDropped(Piece.gap, Target.gapSlot),
      PieceDropped(Piece.total, Target.totalSlot),
      OpChosen(Op.subtract),
    ]) {
      await vm.send(i);
      lines.add(vm.coachText);
    }
    expect(lines, [
      'Drag a bar up here.',
      'Now drag a bar for the fig tree.',
      'Taller or shorter? Show it with the fig tree bar.',
      'Drag the gap onto the board.',
      'Drag total under both bars.',
      'Which sum finds the fig tree?',
      'How tall is the fig tree?',
    ]);
    vm.dispose();
  });

  test('quiet tick recorded only when it produces a decision', () async {
    final vm = await makeVm();
    now = 0;
    await vm.send(const Started());
    now = 5000;
    await vm.tick();
    expect(vm.recorded, 1);
    now = 16000;
    await vm.tick();
    expect(vm.recorded, 2);
    expect(vm.helpAttention, Attention.pulse);
    vm.dispose();
  });

  test('view model restores step from outbox', () async {
    final (sessions, _, _) = await memorySessions();
    LessonViewModel make() => LessonViewModel(
      pack: pack,
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      nowMs: () => 0,
      newSessionId: () => 's2',
      tickEvery: null,
    );
    final first = make();
    for (final i in const [
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.shorter),
    ]) {
      await first.send(i);
    }
    first.dispose();
    final second = make();
    await second.restore();
    expect(second.state.step, LessonStep.placeGap);
    expect(second.recorded, 4);
    second.dispose();
  });

  test('two wrong moves set helpAttention to shake', () async {
    final vm = await makeVm();
    for (final i in const [
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.taller),
      BarBSized(Relation.taller),
    ]) {
      await vm.send(i);
    }
    expect(vm.helpAttention, Attention.shake);
    expect(vm.coachText, 'Read it again. Is the fig tree taller or shorter?');
    vm.dispose();
  });

  test('easier switches problem and session', () async {
    final vm = await makeVm();
    await vm.send(const Started());
    await vm.send(const EasierTaken());
    expect(vm.problem.id, 'easier');
    expect(vm.sessionId, 's2');
    expect(vm.state.step, LessonStep.question);
    expect(vm.recorded, 0);
    vm.dispose();
  });

  test('reopening I know it mid-flow asks the same question again', () async {
    final vm = await makeVm();
    await vm.send(const Started());
    vm.openKnowIt();
    await vm.answer(300);
    vm.closeKnowIt();
    vm.openKnowIt();
    expect(vm.knowPrompt, KnowPrompt.checkPart);
    await vm.answer(79);
    vm.closeKnowIt();
    vm.openKnowIt();
    expect(vm.knowPrompt, KnowPrompt.checkTotal);
    await vm.answer(265);
    expect(vm.state.step, LessonStep.solved);
    expect(vm.state.wrong, 0);
    vm.dispose();
  });

  test('solving gives the badge and the next problem', () async {
    final vm = await makeVm();
    await vm.send(const Started());
    await vm.send(const KnowIt(265));
    expect(vm.badge?.name, 'Tree Detective');
    expect(vm.nextProblemId, 'shorter');
    vm.dispose();
  });

  test(
    'I know it opens the answer prompt, a near miss asks to recheck',
    () async {
      final vm = await makeVm();
      await vm.send(const Started());
      vm.openKnowIt();
      expect(vm.knowPrompt, KnowPrompt.answer);
      await vm.answer(268);
      expect(vm.knowPrompt, KnowPrompt.recheck);
      await vm.answer(300);
      expect(vm.knowPrompt, KnowPrompt.checkPart);
      await vm.answer(79);
      expect(vm.knowPrompt, KnowPrompt.checkTotal);
      await vm.answer(265);
      expect(vm.knowPrompt, isNull);
      expect(vm.state.step, LessonStep.solved);
      vm.dispose();
    },
  );
}
