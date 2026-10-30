import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

void main() {
  const inputs = <LessonInput>[
    Started(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.shorter),
    PieceDropped(Piece.gap, Target.barB),
    OpChosen(Op.subtract),
    NumberEntered(79),
    SideLessonDone(),
    Undo(),
    KnowIt(265),
    PartChecked(81),
    KnowTotalChecked(255),
    HintTaken(),
    ShowMeHowTaken(),
    EasierTaken(),
    QuietFor(15000),
  ];

  test('every input type round-trips through JSON', () {
    for (final i in inputs) {
      final back = inputFromJson(inputToJson(i));
      expect(inputToJson(back), inputToJson(i), reason: '${i.runtimeType}');
      expect(back.runtimeType, i.runtimeType);
    }
  });

  test('input JSON is flat with a camelCase type', () {
    expect(inputToJson(const PieceDropped(Piece.gap, Target.barB)), {
      'type': 'pieceDropped',
      'piece': 'gap',
      'target': 'barB',
    });
    expect(inputToJson(const NumberEntered(79)), {
      'type': 'numberEntered',
      'value': 79,
    });
  });

  test('unknown input type is an error', () {
    expect(() => inputFromJson({'type': 'nope'}), throwsFormatException);
  });

  test('decisions encode with their fields', () {
    expect(decisionToJson(const Coach('cmp.right', {'v': '79'})), {
      'type': 'coach',
      'lineId': 'cmp.right',
      'slots': {'v': '79'},
    });
    expect(decisionToJson(const Solved(SolvedBy.draw, 'tree', 'shorter')), {
      'type': 'solved',
      'by': 'draw',
      'badgeId': 'tree',
      'nextProblemId': 'shorter',
    });
    expect(decisionToJson(const Wobble()), {'type': 'wobble'});
    expect(decisionToJson(const OpenSideLesson(SideLesson.addWithCarry)), {
      'type': 'openSideLesson',
      'kind': 'addWithCarry',
    });
  });
}
