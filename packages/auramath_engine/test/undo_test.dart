import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// @LES-15 and @LES-07: a wrong drop stays on the board and wobbles; an
/// undo before it's checked costs nothing.
const toGap = <LessonInput>[
  Started(),
  BarADrawn(),
  BarBPlaced(),
  BarBSized(Relation.shorter),
];

const t = (stepMs: 10, problemMs: 100, readingMs: 5);

/// Every input's events, in order, with the state they end in.
({LessonState state, List<SpecEvent> events, List<Decision> decisions}) run(
  List<LessonInput> inputs,
) {
  var s = initialState();
  final events = <SpecEvent>[];
  final decisions = <Decision>[];
  for (final i in inputs) {
    final r = step(pack, lemon, s, i);
    events.addAll(eventsFor(lemon, s, i, r, t));
    decisions.addAll(r.decisions);
    s = r.state;
  }
  return (state: s, events: events, decisions: decisions);
}

Iterable<SpecEvent> named(List<SpecEvent> e, String name) =>
    e.where((x) => x.name == name);

void main() {
  test('gap on the fig bar: it stays there, wobbling, not yet charged', () {
    final r = run([...toGap, const PieceDropped(Piece.gap, Target.barB)]);
    expect(r.state.step, LessonStep.placeGap);
    expect(r.state.misplaced, Target.barB);
    expect(r.state.wrong, 0);
    expect(r.decisions, contains(isA<Wobble>()));
    final placed = named(r.events, 'object_placed').last.payload;
    expect(placed['target'], 'bar_b');
    expect(placed['committed'], isFalse);
    expect(
      named(
        r.events,
        'step_committed',
      ).where((e) => e.payload['step_id'] == 'place_difference'),
      isEmpty,
    );
  });

  test('drag the gap onto the fig bar, undo, place it right: clean', () {
    final r = run([
      ...toGap,
      const PieceDropped(Piece.gap, Target.barB),
      const Undo(),
      const PieceDropped(Piece.gap, Target.gapSlot),
    ]);
    expect(r.state.step, LessonStep.placeTotal);
    expect(r.state.wrong, 0);
    expect(r.state.misplaced, isNull);
    expect(named(r.events, 'undo_used').single.payload, {
      'step_id': 'place_difference',
      'object': 'difference',
    });
    expect(
      named(r.events, 'step_committed').map((e) => e.payload['correct']),
      everyElement(isTrue),
    );
  });

  test('moved on from the fig bar to the gap: the slip is charged', () {
    final r = run([
      ...toGap,
      const PieceDropped(Piece.gap, Target.barB),
      const PieceDropped(Piece.gap, Target.gapSlot),
    ]);
    expect(r.state.step, LessonStep.placeTotal);
    expect(r.state.wrong, 1);
    final names = r.events.skipWhile((e) => e.name != 'object_moved');
    expect(names.map((e) => e.name), [
      'object_moved',
      'step_committed',
      'object_placed',
      'step_committed',
      'step_entered',
    ]);
    expect(
      named(r.events, 'step_committed')
          .toList()[r.events.where((e) => e.name == 'step_committed').length -
              2]
          .payload['error_type'],
      'difference_as_amount',
    );
  });

  test('replayed from its events, the board is as it was', () {
    final inputs = [...toGap, const PieceDropped(Piece.gap, Target.barB)];
    final r = run(inputs);
    final again = replay(pack, lemon, inputsFrom(pack, lemon, r.events));
    expect(again, r.state);
  });

  test('two wrong drops in a row: Help me shakes', () {
    final r = run([
      ...toGap,
      const PieceDropped(Piece.gap, Target.barB),
      const PieceDropped(Piece.gap, Target.barA),
    ]);
    expect(r.decisions, contains(isA<ShakeHelp>()));
    expect(r.state.misplaced, Target.barA);
  });
}
