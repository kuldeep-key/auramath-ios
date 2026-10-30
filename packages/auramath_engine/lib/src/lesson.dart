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

/// "I know it": the child types the answer without finishing the drawing.
final class KnowIt extends LessonInput {
  const KnowIt(this.value);
  final int value;
}

/// The answer to "let's check one part": the value of b.
final class PartChecked extends LessonInput {
  const PartChecked(this.value);
  final int value;
}

/// The total, after a right part.
final class KnowTotalChecked extends LessonInput {
  const KnowTotalChecked(this.value);
  final int value;
}

final class HintTaken extends LessonInput {
  const HintTaken();
}

final class ShowMeHowTaken extends LessonInput {
  const ShowMeHowTaken();
}

final class EasierTaken extends LessonInput {
  const EasierTaken();
}

/// How long the child has gone without a move. The app sends it on a timer;
/// the engine has no clock of its own.
final class QuietFor extends LessonInput {
  const QuietFor(this.ms);
  final int ms;
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

/// The child gave b when the question asks for both together.
final class AskWhatQuestionAsks extends Decision {
  const AskWhatQuestionAsks();
}

/// A near miss: check the sum again, not a re-teach (Figma J17).
final class OpenRecheck extends Decision {
  const OpenRecheck();
}

/// "Let's check one part": ask for b on its own.
final class CheckOnePart extends Decision {
  const CheckOnePart();
}

/// Not yet: start drawing it out.
final class DrawIt extends Decision {
  const DrawIt();
}

final class ShowHint extends Decision {
  const ShowHint(this.lineId);
  final String lineId;
}

/// Every hint is used: offer the worked example.
final class SuggestShowMeHow extends Decision {
  const SuggestShowMeHow();
}

final class SwitchProblem extends Decision {
  const SwitchProblem(this.problemId);
  final String problemId;
}

/// Quiet child, first nudge: Help me pulses.
final class PulseHelp extends Decision {
  const PulseHelp();
}

/// Quiet child: the next piece glows.
final class GlowPiece extends Decision {
  const GlowPiece();
}

/// Quiet child: a hand shows the move once.
final class ShowHand extends Decision {
  const ShowHand();
}

/// Quiet child: "Still there?"
final class AskStillThere extends Decision {
  const AskStillThere();
}

final class Solved extends Decision {
  const Solved(this.by, this.badgeId, this.nextProblemId);
  final SolvedBy by;
  final String badgeId;
  final String nextProblemId;
}

// ----------------------------------------------------------------- state

/// Where an "I know it" answer is up to.
enum KnowFlow { none, askingWhat, checkingPart, checkingTotal }

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
    this.sideLessons = 0,
    this.returnStep,
    this.sideLesson,
    this.knowFlow = KnowFlow.none,
    this.quietLevel = 0,
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

  /// Side lessons run this session; tutor policy allows [maxSideLessons].
  final int sideLessons;
  bool get sideLessonRan => sideLessons > 0;
  final LessonStep? returnStep;

  /// The side lesson open now, or the last one run.
  final SideLesson? sideLesson;
  final KnowFlow knowFlow;

  /// How many quiet-child thresholds have fired since the last move (0–4).
  final int quietLevel;

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
    int? sideLessons,
    LessonStep? returnStep,
    SideLesson? sideLesson,
    KnowFlow? knowFlow,
    int? quietLevel,
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
    sideLessons: sideLessons ?? this.sideLessons,
    returnStep: returnStep ?? this.returnStep,
    sideLesson: sideLesson ?? this.sideLesson,
    knowFlow: knowFlow ?? this.knowFlow,
    quietLevel: quietLevel ?? this.quietLevel,
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
    sideLessons,
    returnStep,
    sideLesson,
    knowFlow,
    quietLevel,
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
  if (input is QuietFor) return _quiet(pack, p, s, input.ms);
  final r = _boardSteps.contains(s.step) ? _help(pack, p, s, input) : null;
  final moved = r ?? _move(p, s, input);
  final accepted = !identical(moved.state, s) || moved.decisions.isNotEmpty;
  if (!accepted || moved.state.quietLevel == 0) return moved;
  return (
    state: moved.state.copyWith(quietLevel: 0),
    decisions: moved.decisions,
  );
}

/// Replays saved inputs from the start: how a lesson resumes.
LessonState replay(
  Pack pack,
  ComparisonProblem p,
  Iterable<LessonInput> inputs,
) => inputs.fold(initialState(), (s, i) => step(pack, p, s, i).state);

StepResult? _help(
  Pack pack,
  ComparisonProblem p,
  LessonState s,
  LessonInput input,
) {
  switch (input) {
    case HintTaken():
      final used = s.hintsUsed + 1;
      final hints = pack.hintLineIds;
      return (
        state: s.copyWith(hintsUsed: used),
        decisions: [
          if (used <= hints.length)
            ShowHint(hints[used - 1])
          else
            const SuggestShowMeHow(),
        ],
      );
    case ShowMeHowTaken():
      return (
        state: s.copyWith(hintsUsed: s.hintsUsed + 1),
        decisions: [Coach('cmp.showMeHow', lineSlots(p))],
      );
    case EasierTaken():
      return (state: s, decisions: [SwitchProblem(p.next.easier)]);
    default:
      return null;
  }
}

StepResult _quiet(Pack pack, ComparisonProblem p, LessonState s, int ms) {
  if (!_boardSteps.contains(s.step)) return (state: s, decisions: const []);
  final t = pack.timers;
  final level = [
    t.pulseMs,
    t.glowMs,
    t.handMs,
    t.stillMs,
  ].where((threshold) => ms >= threshold).length;
  if (level <= s.quietLevel) return (state: s, decisions: const []);
  final decisions = <Decision>[
    for (var l = s.quietLevel + 1; l <= level; l++)
      ...switch (l) {
        1 => const [PulseHelp()],
        2 => [const GlowPiece(), Coach('cmp.takeYourTime', lineSlots(p))],
        3 => const [ShowHand()],
        _ => const [AskStillThere()],
      },
  ];
  return (state: s.copyWith(quietLevel: level), decisions: decisions);
}

StepResult _move(ComparisonProblem p, LessonState s, LessonInput input) {
  final slots = lineSlots(p);
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
      if (value == dropCarry(p.aValue, p.bValue) && _canSide(s)) {
        return to(
          _sideLesson(s, LessonStep.findTotal, SideLesson.addWithCarry),
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

    case (_, KnowIt(:final value))
        when _boardSteps.contains(s.step) &&
            (s.knowFlow == KnowFlow.none || s.knowFlow == KnowFlow.askingWhat):
      return _knowIt(p, s, value);

    case (_, PartChecked(:final value))
        when s.knowFlow == KnowFlow.checkingPart:
      return _partChecked(p, s, value, slots);

    case (_, KnowTotalChecked(:final value))
        when s.knowFlow == KnowFlow.checkingTotal:
      if (value == p.total) {
        return to(
          s.copyWith(step: LessonStep.solved, knowFlow: KnowFlow.none),
          [_solved(p, s, s.barA ? SolvedBy.partway : SolvedBy.know)],
        );
      }
      if (value == dropCarry(p.aValue, p.bValue) && _canSide(s)) {
        return to(_sideLesson(s, s.step, SideLesson.addWithCarry), [
          const OpenSideLesson(SideLesson.addWithCarry),
        ]);
      }
      return to(s, [Coach('cmp.recheck', slots)]);

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

  final route = findBRoutes(p)[value];
  switch (_canSide(s) || route == Mistake.oppositeOp ? route : null) {
    case Mistake.regrouping:
      return (
        state: _sideLesson(counted, LessonStep.findB, side),
        decisions: [Coach('cmp.regrouping', slots), OpenSideLesson(side)],
      );
    case Mistake.carry:
      return (
        state: _sideLesson(counted, LessonStep.findB, SideLesson.addWithCarry),
        decisions: [
          Coach('cmp.carry', slots),
          const OpenSideLesson(SideLesson.addWithCarry),
        ],
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
      if (misses == 2 && _canSide(s)) {
        return (
          state: _sideLesson(next, LessonStep.findB, side),
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

/// The values a pack line's {slots} are filled with for problem [p].
Map<String, String> lineSlots(ComparisonProblem p) => {
  'a': p.a.name.toLowerCase(),
  'b': p.b.name.toLowerCase(),
  'B': p.b.name,
  'av': '${p.aValue}',
  'd': '${p.diff}',
  'u': p.unit,
  'rel': p.big == BigSide.a ? 'shorter' : 'taller',
};

const _boardSteps = {
  LessonStep.drawA,
  LessonStep.placeB,
  LessonStep.sizeB,
  LessonStep.placeGap,
  LessonStep.placeTotal,
  LessonStep.chooseOp,
  LessonStep.findB,
  LessonStep.findTotal,
};

/// Tutor policy `side_lessons.max_per_session`; past it the child gets the
/// step's usual help instead.
const maxSideLessons = 2;

bool _canSide(LessonState s) => s.sideLessons < maxSideLessons;

LessonState _sideLesson(LessonState s, LessonStep back, SideLesson kind) =>
    s.copyWith(
      step: LessonStep.sideLesson,
      returnStep: back,
      sideLesson: kind,
      sideLessons: s.sideLessons + 1,
      knowFlow: KnowFlow.none,
    );

/// Back to an empty board to draw it out.
LessonState _drawIt(LessonState s) => LessonState(
  step: LessonStep.drawA,
  wrong: s.wrong + 1,
  findBWrong: s.findBWrong,
  hintsUsed: s.hintsUsed,
  sideLessons: s.sideLessons,
);

StepResult _knowIt(ComparisonProblem p, LessonState s, int value) {
  if (p.ask == Ask.b) {
    if (value == p.bValue) {
      return (
        state: s.copyWith(step: LessonStep.solved, knowFlow: KnowFlow.none),
        decisions: [_solved(p, s, s.barA ? SolvedBy.partway : SolvedBy.know)],
      );
    }
    return (state: _drawIt(s), decisions: const [DrawIt()]);
  }
  if (value == p.total) {
    return (
      state: s.copyWith(step: LessonStep.solved, knowFlow: KnowFlow.none),
      decisions: [_solved(p, s, s.barA ? SolvedBy.partway : SolvedBy.know)],
    );
  }
  if (value == p.bValue) {
    return (
      state: s.copyWith(knowFlow: KnowFlow.askingWhat),
      decisions: const [AskWhatQuestionAsks()],
    );
  }
  if ((value - p.total).abs() <= 10 && value != dropCarry(p.aValue, p.bValue)) {
    return (
      state: s.copyWith(knowFlow: KnowFlow.none),
      decisions: const [OpenRecheck()],
    );
  }
  return (
    state: s.copyWith(knowFlow: KnowFlow.checkingPart),
    decisions: const [CheckOnePart()],
  );
}

StepResult _partChecked(
  ComparisonProblem p,
  LessonState s,
  int value,
  Map<String, String> slots,
) {
  if (value == p.bValue) {
    return (
      state: s.copyWith(knowFlow: KnowFlow.checkingTotal),
      decisions: [Coach('cmp.partRight', slots)],
    );
  }
  final a = p.aValue, d = p.diff;
  final counted = s.copyWith(wrong: s.wrong + 1);
  if (p.big == BigSide.a && value == noBorrow(a, d) && _canSide(s)) {
    return (
      state: _sideLesson(counted, s.step, SideLesson.takeAcrossTen),
      decisions: const [OpenSideLesson(SideLesson.takeAcrossTen)],
    );
  }
  if (p.big == BigSide.a && value == a + d) {
    return (
      state: _drawIt(s),
      decisions: [Coach('cmp.drawIt', slots), const DrawIt()],
    );
  }
  if (value == d) {
    return (
      state: _drawIt(s),
      decisions: [Coach('cmp.twoBars', slots), const DrawIt()],
    );
  }
  if (value == reverseDigits(p.bValue)) {
    return (state: counted, decisions: const [OpenRecheck()]);
  }
  return (state: _drawIt(s), decisions: const [DrawIt()]);
}
