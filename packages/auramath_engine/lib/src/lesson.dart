import 'mistakes.dart';
import 'pack.dart';
import 'problem.dart';

/// Where the child is in a comparison lesson. The UI maps each step to its
/// Figma screen.
enum LessonStep {
  question,
  drawA,
  placeB,
  sizeB,
  placeGap,
  placeTotal,
  chooseOp,
  findB,
  findTotal,
  sideLesson,
  solved,
}

enum Relation { taller, shorter, same }

enum Piece { gap, total }

enum Target { gapSlot, totalSlot, barA, barB }

enum Op { add, subtract }

enum SideLesson { takeAcrossTen, addWithCarry }

enum SolvedBy { draw, know, partway }

// ---------------------------------------------------------------- inputs

/// Something the child did. Every accepted input is saved as an event.
sealed class LessonInput {
  const LessonInput();
}

final class Started extends LessonInput {
  const Started();
}

final class BarADrawn extends LessonInput {
  const BarADrawn();
}

final class BarBPlaced extends LessonInput {
  const BarBPlaced();
}

final class BarBSized extends LessonInput {
  const BarBSized(this.rel);
  final Relation rel;
}

final class PieceDropped extends LessonInput {
  const PieceDropped(this.piece, this.target);
  final Piece piece;
  final Target target;
}

final class OpChosen extends LessonInput {
  const OpChosen(this.op);
  final Op op;
}

final class NumberEntered extends LessonInput {
  const NumberEntered(this.value);
  final int value;
}

final class SideLessonDone extends LessonInput {
  const SideLessonDone();
}

final class Undo extends LessonInput {
  const Undo();
}

// ------------------------------------------------------------- decisions

/// What the engine decided. The app shows it; it never decides itself.
sealed class Decision {
  const Decision();
}

final class Coach extends Decision {
  const Coach(this.lineId, this.slots);
  final String lineId;
  final Map<String, String> slots;
}

/// A wrong move: the piece or number wobbles. No red, no cross.
final class Wobble extends Decision {
  const Wobble();
}

/// Two wrong moves in a row: Help me shakes.
final class ShakeHelp extends Decision {
  const ShakeHelp();
}

final class OpenSideLesson extends Decision {
  const OpenSideLesson(this.kind);
  final SideLesson kind;
}

final class Solved extends Decision {
  const Solved(this.by, this.badgeId, this.nextProblemId);
  final SolvedBy by;
  final String badgeId;
  final String nextProblemId;
}

// ----------------------------------------------------------------- state

class LessonState {
  const LessonState({
    this.step = LessonStep.question,
    this.barA = false,
    this.barB = false,
    this.gapPlaced = false,
    this.totalPlaced = false,
    this.op,
    this.wrong = 0,
    this.wrongRow = 0,
    this.findBWrong = 0,
    this.hintsUsed = 0,
    this.sideLessonRan = false,
    this.returnStep,
  });

  final LessonStep step;
  final bool barA;
  final bool barB;
  final bool gapPlaced;
  final bool totalPlaced;
  final Op? op;
  final int wrong;
  final int wrongRow;
  final int findBWrong;
  final int hintsUsed;
  final bool sideLessonRan;
  final LessonStep? returnStep;

  LessonState copyWith({
    LessonStep? step,
    bool? barA,
    bool? barB,
    bool? gapPlaced,
    bool? totalPlaced,
    Op? op,
    int? wrong,
    int? wrongRow,
    int? findBWrong,
    int? hintsUsed,
    bool? sideLessonRan,
    LessonStep? returnStep,
  }) => LessonState(
    step: step ?? this.step,
    barA: barA ?? this.barA,
    barB: barB ?? this.barB,
    gapPlaced: gapPlaced ?? this.gapPlaced,
    totalPlaced: totalPlaced ?? this.totalPlaced,
    op: op ?? this.op,
    wrong: wrong ?? this.wrong,
    wrongRow: wrongRow ?? this.wrongRow,
    findBWrong: findBWrong ?? this.findBWrong,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    sideLessonRan: sideLessonRan ?? this.sideLessonRan,
    returnStep: returnStep ?? this.returnStep,
  );

  List<Object?> get _fields => [
    step,
    barA,
    barB,
    gapPlaced,
    totalPlaced,
    op,
    wrong,
    wrongRow,
    findBWrong,
    hintsUsed,
    sideLessonRan,
    returnStep,
  ];

  @override
  bool operator ==(Object other) {
    if (other is! LessonState) return false;
    final a = _fields, b = other._fields;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_fields);
}

LessonState initialState() => const LessonState();

typedef StepResult = ({LessonState state, List<Decision> decisions});

// ------------------------------------------------------------------ step

/// The one place a teaching decision is made. Pure: the same [s] and [input]
/// always give the same result. An input that does not fit the current step
/// returns [s] itself and no decisions.
StepResult step(
  Pack pack,
  ComparisonProblem p,
  LessonState s,
  LessonInput input,
) {
  final slots = _slots(p);
  StepResult to(LessonState next, [List<Decision> d = const []]) =>
      (state: next, decisions: d);
  StepResult right(LessonState next, [List<Decision> d = const []]) =>
      to(next.copyWith(wrongRow: 0), d);
  StepResult wrongMove(String lineId) {
    final next = s.copyWith(wrong: s.wrong + 1, wrongRow: s.wrongRow + 1);
    return to(next, [
      const Wobble(),
      if (next.wrongRow >= 2) const ShakeHelp(),
      Coach(lineId, slots),
    ]);
  }

  final bigA = p.big == BigSide.a;

  switch ((s.step, input)) {
    case (LessonStep.question, Started()):
      return to(s.copyWith(step: LessonStep.drawA));

    case (LessonStep.drawA, BarADrawn()):
      return right(s.copyWith(step: LessonStep.placeB, barA: true));

    case (LessonStep.placeB, BarBPlaced()):
      return right(s.copyWith(step: LessonStep.sizeB, barB: true));

    case (LessonStep.sizeB, BarBSized(:final rel)):
      if (rel == Relation.same) return to(s, [Coach('cmp.sizeB', slots)]);
      final ok = rel == (bigA ? Relation.shorter : Relation.taller);
      if (!ok) return wrongMove('cmp.sizeBWrong');
      return right(s.copyWith(step: LessonStep.placeGap));

    case (LessonStep.placeGap, PieceDropped(piece: Piece.gap, :final target)):
      if (target != Target.gapSlot) return wrongMove('cmp.gapWrong');
      return right(
        s.copyWith(
          step: p.ask == Ask.total
              ? LessonStep.placeTotal
              : LessonStep.chooseOp,
          gapPlaced: true,
        ),
      );

    case (
      LessonStep.placeTotal,
      PieceDropped(piece: Piece.total, :final target),
    ):
      if (target != Target.totalSlot) return wrongMove('cmp.totalWrong');
      return right(s.copyWith(step: LessonStep.chooseOp, totalPlaced: true));

    case (LessonStep.chooseOp, OpChosen(:final op)):
      if (op != (bigA ? Op.subtract : Op.add)) return wrongMove('cmp.opWrong');
      return right(s.copyWith(step: LessonStep.findB, op: op));

    case (LessonStep.findB, NumberEntered(:final value)):
      return _findB(p, s, value, slots, right, wrongMove);

    case (LessonStep.findTotal, NumberEntered(:final value)):
      if (value == p.total) {
        return right(s.copyWith(step: LessonStep.solved), [
          _solved(p, s, SolvedBy.draw),
        ]);
      }
      if (value == dropCarry(p.aValue, p.bValue)) {
        return to(
          s.copyWith(
            step: LessonStep.sideLesson,
            returnStep: LessonStep.findTotal,
            sideLessonRan: true,
          ),
          [
            Coach('cmp.carry', slots),
            const OpenSideLesson(SideLesson.addWithCarry),
          ],
        );
      }
      if ((value - p.total).abs() <= 10) return wrongMove('cmp.recheck');
      return wrongMove('cmp.addBoth');

    case (LessonStep.sideLesson, SideLessonDone()):
      return to(s.copyWith(step: s.returnStep));

    case (_, Undo()):
      return _undo(p, s);

    default:
      return to(s);
  }
}

StepResult _findB(
  ComparisonProblem p,
  LessonState s,
  int value,
  Map<String, String> slots,
  StepResult Function(LessonState, [List<Decision>]) right,
  StepResult Function(String) wrongMove,
) {
  if (value == p.bValue) {
    final v = {...slots, 'v': '$value'};
    if (p.ask == Ask.b) {
      return right(s.copyWith(step: LessonStep.solved), [
        Coach('cmp.right', v),
        _solved(p, s, SolvedBy.draw),
      ]);
    }
    return right(s.copyWith(step: LessonStep.findTotal), [
      Coach('cmp.right', v),
    ]);
  }

  final misses = s.findBWrong + 1;
  final counted = s.copyWith(findBWrong: misses);
  // Adding finds b when b is the bigger one, so its side lesson is the carry.
  final side = p.big == BigSide.a
      ? SideLesson.takeAcrossTen
      : SideLesson.addWithCarry;
  LessonState toSide(LessonState from) => from.copyWith(
    step: LessonStep.sideLesson,
    returnStep: LessonStep.findB,
    sideLessonRan: true,
  );

  switch (findBRoutes(p)[value]) {
    case Mistake.regrouping:
      return (
        state: toSide(counted),
        decisions: [Coach('cmp.regrouping', slots), OpenSideLesson(side)],
      );
    case Mistake.oppositeOp:
      final r = wrongMove('cmp.opposite');
      return (
        state: r.state.copyWith(findBWrong: misses),
        decisions: r.decisions,
      );
    default:
      final r = wrongMove('cmp.tryAgain');
      final next = r.state.copyWith(findBWrong: misses);
      if (misses >= 2) {
        return (
          state: toSide(next),
          decisions: [...r.decisions, OpenSideLesson(side)],
        );
      }
      return (state: next, decisions: r.decisions);
  }
}

StepResult _undo(ComparisonProblem p, LessonState s) {
  final LessonState? back = switch (s.step) {
    LessonStep.sizeB => s.copyWith(step: LessonStep.placeB, barB: false),
    LessonStep.placeGap => s.copyWith(step: LessonStep.sizeB),
    LessonStep.placeTotal => s.copyWith(
      step: LessonStep.placeGap,
      gapPlaced: false,
    ),
    LessonStep.chooseOp when p.ask == Ask.total => s.copyWith(
      step: LessonStep.placeTotal,
      totalPlaced: false,
    ),
    LessonStep.chooseOp => s.copyWith(
      step: LessonStep.placeGap,
      gapPlaced: false,
    ),
    _ => null,
  };
  return (state: back ?? s, decisions: const []);
}

Solved _solved(ComparisonProblem p, LessonState s, SolvedBy by) {
  final helped = s.hintsUsed > 0 || s.sideLessonRan;
  return Solved(
    by,
    helped ? 'asker' : 'tree',
    !helped && s.wrong == 0 ? p.next.fast : p.next.helped,
  );
}

Map<String, String> _slots(ComparisonProblem p) => {
  'a': p.a.name.toLowerCase(),
  'b': p.b.name.toLowerCase(),
  'B': p.b.name,
  'av': '${p.aValue}',
  'd': '${p.diff}',
  'u': p.unit,
  'rel': p.big == BigSide.a ? 'shorter' : 'taller',
};
