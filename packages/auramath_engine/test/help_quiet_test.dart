import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

({LessonState state, List<Decision> decisions}) run(
  ComparisonProblem p,
  List<LessonInput> inputs,
) {
  var s = initialState();
  final all = <Decision>[];
  for (final i in inputs) {
    final r = step(pack, p, s, i);
    s = r.state;
    all.addAll(r.decisions);
  }
  return (state: s, decisions: all);
}

void main() {
  test('hints come in pack order then suggest show me how', () {
    final r = run(lemon, [
      const Started(),
      const HintTaken(),
      const HintTaken(),
      const HintTaken(),
      const HintTaken(),
    ]);
    expect(r.decisions.whereType<ShowHint>().map((h) => h.lineId), [
      'cmp.hint1',
      'cmp.hint2',
      'cmp.hint3',
    ]);
    expect(r.decisions.last, isA<SuggestShowMeHow>());
    expect(r.state.hintsUsed, 4);
  });

  test('a hint makes the badge Brave Asker', () {
    final r = run(easier, [
      const Started(),
      const HintTaken(),
      const KnowIt(122),
    ]);
    expect(r.decisions.whereType<Solved>().single.badgeId, 'asker');
  });

  test('show me how counts as help and coaches', () {
    final r = run(lemon, [const Started(), const ShowMeHowTaken()]);
    expect(r.state.hintsUsed, 1);
    expect(r.decisions.whereType<Coach>().single.lineId, 'cmp.showMeHow');
  });

  test('easier switches to easier problem', () {
    final r = run(lemon, [const Started(), const EasierTaken()]);
    expect(r.decisions.single, isA<SwitchProblem>());
    expect((r.decisions.single as SwitchProblem).problemId, 'easier');
  });

  test('quiet 15s pulses, 25s glows, 40s hand, 60s still, each once', () {
    final r = run(lemon, [
      const Started(),
      const QuietFor(14999),
      const QuietFor(15000),
      const QuietFor(16000),
      const QuietFor(25000),
      const QuietFor(40000),
      const QuietFor(61000),
      const QuietFor(70000),
    ]);
    expect(r.decisions.map((d) => d.runtimeType), [
      PulseHelp,
      GlowPiece,
      Coach,
      ShowHand,
      AskStillThere,
    ]);
    expect(r.state.quietLevel, 4);
  });

  test('a long quiet crosses every threshold at once', () {
    final r = run(lemon, [const Started(), const QuietFor(60000)]);
    expect(r.decisions.whereType<AskStillThere>(), hasLength(1));
    expect(r.decisions.whereType<PulseHelp>(), hasLength(1));
  });

  test('a quiet tick that crosses nothing returns the same state', () {
    final s = run(lemon, [const Started()]).state;
    expect(step(pack, lemon, s, const QuietFor(1000)).state, same(s));
  });

  test('a move resets quiet', () {
    final r = run(lemon, [
      const Started(),
      const QuietFor(16000),
      const BarADrawn(),
      const QuietFor(16000),
    ]);
    expect(r.decisions.whereType<PulseHelp>(), hasLength(2));
  });

  test('no quiet nudges on the question screen or when solved', () {
    final r = run(easier, [const QuietFor(60000)]);
    expect(r.decisions, isEmpty);
  });

  test('replay equals stepping one by one', () {
    const inputs = [
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.taller),
      HintTaken(),
      BarBSized(Relation.shorter),
      PieceDropped(Piece.gap, Target.gapSlot),
      QuietFor(26000),
    ];
    expect(replay(pack, lemon, inputs), run(lemon, inputs).state);
  });
}
