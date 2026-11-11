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
  const SideLessonDone({this.completed = true});

  /// False: closed before it ran, because the server chose other help
  /// (AI-04). It doesn't count toward the session's side lessons.
  final bool completed;
}

/// The server chose a side lesson the rules didn't open (AI-04): it opens
/// on the step the child is on.
final class SideLessonChosen extends LessonInput {
  const SideLessonChosen(this.kind);
  final SideLesson kind;
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
  const HintTaken({this.afterWrong = false});

  /// Given by the tutor after a wrong step (the server's decision), not
  /// asked for from Help me.
  final bool afterWrong;
}

final class ShowMeHowTaken extends LessonInput {
  const ShowMeHowTaken({this.afterWrong = false});
  final bool afterWrong;
}

final class EasierTaken extends LessonInput {
  const EasierTaken({this.noProgress = false, this.afterWrong = false});
  final bool afterWrong;

  /// Offered because the child made no progress for a while (TUT-10),
  /// not chosen from Help me.
  final bool noProgress;
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
    this.returnFlow = KnowFlow.none,
    this.quietLevel = 0,
    this.knowMisses = 0,
    this.bSized = false,
    this.bFound = false,
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

  /// Side lessons run this session; tutor policy allows [Pack.maxSideLessons].
  final int sideLessons;
  bool get sideLessonRan => sideLessons > 0;
  final LessonStep? returnStep;

  /// The side lesson open now, or the last one run.
  final SideLesson? sideLesson;
  final KnowFlow knowFlow;

  /// The answer sheet a side lesson was opened from, reopened after it
  /// (policy `side_lessons.return_to: same_step`).
  final KnowFlow returnFlow;

  /// How many quiet-child thresholds have fired since the last move (0–4).
  final int quietLevel;

  /// Wrong answers at the answer sheet's current stage (policy
  /// `answer_sheet`: a second wrong answer at any one stage draws it).
  final int knowMisses;

  /// Bar B is sized against bar A (the board draws it at its height).
  final bool bSized;

  /// B's value is found (the board writes it in bar B).
  final bool bFound;

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
    KnowFlow? returnFlow,
    int? quietLevel,
    int? knowMisses,
    bool? bSized,
    bool? bFound,
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
    returnFlow: returnFlow ?? this.returnFlow,
    quietLevel: quietLevel ?? this.quietLevel,
    knowMisses: knowMisses ?? this.knowMisses,
    bSized: bSized ?? this.bSized,
    bFound: bFound ?? this.bFound,
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
    returnFlow,
    quietLevel,
    knowMisses,
    bSized,
    bFound,
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
  final moved = r ?? _move(pack, p, s, input);
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

StepResult _move(
  Pack pack,
  ComparisonProblem p,
  LessonState s,
  LessonInput input,
) {
  final maxSide = pack.maxSideLessons;
  final slots = lineSlots(p);
  // the step after [from] in the template's order; solved after the last
  LessonStep after(LessonStep from) => nextStep(pack, p, from);
  StepResult to(LessonState next, [List<Decision> d = const []]) =>
      (state: next, decisions: d);
  StepResult right(LessonState next, [List<Decision> d = const []]) =>
      to(next.copyWith(wrongRow: 0), d);
  // a right move: on to the next step in order, or solved after the last
  StepResult advance(LessonState next, [List<Decision> d = const []]) {
    final upNext = after(s.step);
    return right(next.copyWith(step: upNext), [
      ...d,
      if (upNext == LessonStep.solved) _solved(p, next, SolvedBy.draw),
    ]);
  }

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
      return to(s.copyWith(step: after(LessonStep.question)));

    case (LessonStep.drawA, BarADrawn()):
      return advance(s.copyWith(barA: true));

    case (LessonStep.placeB, BarBPlaced()):
      return advance(s.copyWith(barB: true));

    case (LessonStep.sizeB, BarBSized(:final rel)):
      if (rel == Relation.same) return to(s, [Coach('cmp.sizeB', slots)]);
      final ok = rel == (bigA ? Relation.shorter : Relation.taller);
      if (!ok) return wrongMove('cmp.sizeBWrong');
      return advance(s.copyWith(bSized: true));

    case (LessonStep.placeGap, PieceDropped(piece: Piece.gap, :final target)):
      if (target != Target.gapSlot) return wrongMove('cmp.gapWrong');
      return advance(s.copyWith(gapPlaced: true));

    case (
      LessonStep.placeTotal,
      PieceDropped(piece: Piece.total, :final target),
    ):
      if (target != Target.totalSlot) return wrongMove('cmp.totalWrong');
      return advance(s.copyWith(totalPlaced: true));

    case (LessonStep.chooseOp, OpChosen(:final op)):
      if (op != (bigA ? Op.subtract : Op.add)) return wrongMove('cmp.opWrong');
      return advance(s.copyWith(op: op));

    case (LessonStep.findB, NumberEntered(:final value)):
      return _findB(p, s, value, slots, advance, wrongMove, maxSide);

    case (LessonStep.findTotal, NumberEntered(:final value)):
      if (value == p.total) return advance(s);
      if (value == dropCarry(p.aValue, p.bValue) && _canSide(s, maxSide)) {
        return to(
          _sideLesson(s, LessonStep.findTotal, SideLesson.addWithCarry),
          [
            Coach('cmp.carry', slots),
            const OpenSideLesson(SideLesson.addWithCarry),
          ],
        );
      }
      // swapped digits: check the sum again, with no penalty (LES-09)
      if (value != dropCarry(p.aValue, p.bValue) &&
          isDigitPermutation(value, p.total)) {
        return to(s, [Coach('cmp.recheck', slots)]);
      }
      return wrongMove('cmp.addBoth');

    case (LessonStep.sideLesson, SideLessonDone(completed: false)):
      // closed unrun: back where it opened, and it doesn't count
      return to(
        s.copyWith(
          step: s.returnStep,
          knowFlow: s.returnFlow,
          returnFlow: KnowFlow.none,
          sideLessons: s.sideLessons - 1,
        ),
      );

    case (_, SideLessonChosen(:final kind))
        when _boardSteps.contains(s.step) && _canSide(s, maxSide):
      return to(_sideLesson(s, s.step, kind), [OpenSideLesson(kind)]);

    case (LessonStep.sideLesson, SideLessonDone()):
      // back to the step, or the answer sheet, it was opened from (TUT-18)
      return to(
        s.copyWith(
          step: s.returnStep,
          knowFlow: s.returnFlow,
          returnFlow: KnowFlow.none,
        ),
        [Coach('cmp.sideBack', slots)],
      );

    case (_, KnowIt(:final value))
        when _boardSteps.contains(s.step) &&
            (s.knowFlow == KnowFlow.none || s.knowFlow == KnowFlow.askingWhat):
      return _knowIt(p, s, value, maxSide);

    case (_, PartChecked(:final value))
        when s.knowFlow == KnowFlow.checkingPart:
      return _partChecked(p, s, value, slots, maxSide);

    case (_, KnowTotalChecked(:final value))
        when s.knowFlow == KnowFlow.checkingTotal ||
            s.knowFlow == KnowFlow.askingWhat:
      return _totalAfterUnknown(p, s, value, maxSide);

    case (_, Undo()):
      return _undo(pack, p, s);

    default:
      return to(s);
  }
}

StepResult _findB(
  ComparisonProblem p,
  LessonState s,
  int value,
  Map<String, String> slots,
  StepResult Function(LessonState, [List<Decision>]) advance,
  StepResult Function(String) wrongMove,
  int maxSide,
) {
  if (value == p.bValue) {
    return advance(s.copyWith(bFound: true), [
      Coach('cmp.right', {...slots, 'v': '$value'}),
    ]);
  }

  final misses = s.findBWrong + 1;
  final counted = s.copyWith(findBWrong: misses);
  // Adding finds b when b is the bigger one, so its side lesson is the carry.
  final side = p.big == BigSide.a
      ? SideLesson.takeAcrossTen
      : SideLesson.addWithCarry;

  final route = findBRoutes(p)[value];
  // swapped digits: check the sum again; not a wrong move, no side lesson,
  // and the next problem doesn't change (LES-09)
  if (route == Mistake.swappedDigits ||
      route == null && isDigitPermutation(value, p.bValue)) {
    return (state: s, decisions: [Coach('cmp.recheck', slots)]);
  }
  switch (_canSide(s, maxSide) || route == Mistake.oppositeOp ? route : null) {
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
      if (misses == 2 && _canSide(s, maxSide)) {
        return (
          state: _sideLesson(next, LessonStep.findB, side),
          decisions: [...r.decisions, OpenSideLesson(side)],
        );
      }
      return (state: next, decisions: r.decisions);
  }
}

StepResult _undo(Pack pack, ComparisonProblem p, LessonState s) {
  final back = undoneStep(pack, p, s);
  return (
    state: back == null
        ? s
        : switch (back) {
            LessonStep.placeB => s.copyWith(step: back, barB: false),
            LessonStep.sizeB => s.copyWith(step: back, bSized: false),
            LessonStep.placeGap => s.copyWith(step: back, gapPlaced: false),
            _ => s.copyWith(step: back, totalPlaced: false),
          },
    decisions: const [],
  );
}

/// The placement an Undo now takes back: the step before this one, when it
/// put something on the board (bar B, its size, the gap or the total).
LessonStep? undoneStep(Pack pack, ComparisonProblem p, LessonState s) {
  const undoable = {
    LessonStep.sizeB,
    LessonStep.placeGap,
    LessonStep.placeTotal,
    LessonStep.chooseOp,
  };
  const placements = {
    LessonStep.placeB,
    LessonStep.sizeB,
    LessonStep.placeGap,
    LessonStep.placeTotal,
  };
  if (!undoable.contains(s.step)) return null;
  final steps = lessonSteps(pack, p);
  final i = steps.indexOf(s.step);
  final back = i > 0 ? steps[i - 1] : null;
  return placements.contains(back) ? back : null;
}

/// The steps problem [p] runs, in its template's order (LES-03): the
/// pack's template's `steps` for the problem's level, else the engine's own
/// order. A problem that asks only for b never places or finds the total.
List<LessonStep> lessonSteps(Pack pack, ComparisonProblem p) {
  final t = pack.template;
  final ids = t == null || t.steps.isEmpty
      ? knownSteps
      : t.stepsFor(p.level, optionalOn: pack.optionalSteps);
  return [
    for (final id in ids)
      if (p.ask == Ask.total || (id != 'place_total' && id != 'find_total'))
        ...switch (id) {
          'draw_known_bar' => const [LessonStep.drawA],
          'size_second_bar' => const [LessonStep.placeB, LessonStep.sizeB],
          'place_difference' => const [LessonStep.placeGap],
          'place_total' => const [LessonStep.placeTotal],
          'choose_operation' => const [LessonStep.chooseOp],
          'find_unknown' => const [LessonStep.findB],
          'find_total' => const [LessonStep.findTotal],
          _ => const <LessonStep>[],
        },
  ];
}

/// The step after [from] for problem [p]; [LessonStep.solved] after the
/// last one.
LessonStep nextStep(Pack pack, ComparisonProblem p, LessonStep from) {
  final steps = lessonSteps(pack, p);
  if (from == LessonStep.question) return steps.first;
  final i = steps.indexOf(from);
  return i >= 0 && i + 1 < steps.length ? steps[i + 1] : LessonStep.solved;
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

bool _canSide(LessonState s, int max) => s.sideLessons < max;

LessonState _sideLesson(LessonState s, LessonStep back, SideLesson kind) =>
    s.copyWith(
      step: LessonStep.sideLesson,
      returnStep: back,
      sideLesson: kind,
      sideLessons: s.sideLessons + 1,
      knowFlow: KnowFlow.none,
      returnFlow: s.knowFlow,
    );

/// Back to an empty board to draw it out.
LessonState _drawIt(LessonState s) => LessonState(
  step: LessonStep.drawA,
  wrong: s.wrong + 1,
  findBWrong: s.findBWrong,
  hintsUsed: s.hintsUsed,
  sideLessons: s.sideLessons,
);

StepResult _knowIt(ComparisonProblem p, LessonState s, int value, int maxSide) {
  final slots = lineSlots(p);
  // levels 1 and 2 ask for the unknown: its stage's rules from the start
  if (p.ask == Ask.b) return _unknownStage(p, s, value, slots, maxSide);
  // the total asked again: "a wrong total after that uses the adding rules"
  if (s.knowFlow == KnowFlow.askingWhat) {
    return _totalAfterUnknown(p, s, value, maxSide);
  }
  if (value == p.total) {
    return (
      state: s.copyWith(
        step: LessonStep.solved,
        knowFlow: KnowFlow.none,
        knowMisses: 0,
      ),
      decisions: [_solved(p, s, s.barA ? SolvedBy.partway : SolvedBy.know)],
    );
  }
  // a second wrong total: draw it (policy answer_sheet)
  if (s.knowMisses > 0) return _drawItFor(p, s, null);
  if (value == p.bValue) {
    return (
      state: s.copyWith(knowFlow: KnowFlow.askingWhat, knowMisses: 0),
      decisions: const [AskWhatQuestionAsks()],
    );
  }
  // swapped digits: check the sum again, then the same answer once more
  if (isDigitPermutation(value, p.total)) {
    return (
      state: s.copyWith(knowFlow: KnowFlow.none, knowMisses: 1),
      decisions: const [OpenRecheck()],
    );
  }
  return (
    state: s.copyWith(knowFlow: KnowFlow.checkingPart, knowMisses: 0),
    decisions: const [CheckOnePart()],
  );
}

/// The total once the unknown is known right, or asked again after the
/// unknown was given for it (template `total_after_unknown`).
StepResult _totalAfterUnknown(
  ComparisonProblem p,
  LessonState s,
  int value,
  int maxSide,
) {
  if (value == p.total) {
    return (
      state: s.copyWith(
        step: LessonStep.solved,
        knowFlow: KnowFlow.none,
        knowMisses: 0,
      ),
      decisions: [_solved(p, s, s.barA ? SolvedBy.partway : SolvedBy.know)],
    );
  }
  if (s.knowMisses > 0) return _drawItFor(p, s, null);
  if (value == dropCarry(p.aValue, p.bValue) && _canSide(s, maxSide)) {
    final back = s.copyWith(knowFlow: KnowFlow.checkingTotal, knowMisses: 1);
    return (
      state: _sideLesson(back, s.step, SideLesson.addWithCarry),
      decisions: const [OpenSideLesson(SideLesson.addWithCarry)],
    );
  }
  if (isDigitPermutation(value, p.total)) {
    return (
      state: s.copyWith(knowFlow: KnowFlow.checkingTotal, knowMisses: 1),
      decisions: const [OpenRecheck()],
    );
  }
  return _drawItFor(p, s, null);
}

/// "Not yet: let's draw it", with the opening line policy
/// `answer_sheet.opening_line` gives for [lineId]'s error, if any.
StepResult _drawItFor(ComparisonProblem p, LessonState s, String? lineId) => (
  state: _drawIt(s),
  decisions: [if (lineId != null) Coach(lineId, lineSlots(p)), const DrawIt()],
);

StepResult _partChecked(
  ComparisonProblem p,
  LessonState s,
  int value,
  Map<String, String> slots,
  int maxSide,
) => _unknownStage(p, s, value, slots, maxSide);

/// The answer sheet's unknown stage (template `answer_sheet_rules`, policy
/// `answer_sheet.route_by_error_type`): a take-away slip goes to its side
/// lesson and back, swapped digits are checked again, a mix-up in the story
/// draws it with its first hint, and a second wrong answer draws it.
StepResult _unknownStage(
  ComparisonProblem p,
  LessonState s,
  int value,
  Map<String, String> slots,
  int maxSide,
) {
  if (value == p.bValue) {
    if (p.ask == Ask.b) {
      return (
        state: s.copyWith(
          step: LessonStep.solved,
          knowFlow: KnowFlow.none,
          knowMisses: 0,
        ),
        decisions: [_solved(p, s, s.barA ? SolvedBy.partway : SolvedBy.know)],
      );
    }
    return (
      state: s.copyWith(knowFlow: KnowFlow.checkingTotal, knowMisses: 0),
      decisions: [Coach('cmp.partRight', slots)],
    );
  }
  final a = p.aValue, d = p.diff;
  final flow = p.ask == Ask.b ? KnowFlow.none : KnowFlow.checkingPart;
  if (s.knowMisses > 0) return _drawItFor(p, s, null);
  if (p.big == BigSide.a && value == noBorrow(a, d) && _canSide(s, maxSide)) {
    final counted = s.copyWith(
      wrong: s.wrong + 1,
      knowFlow: flow,
      knowMisses: 1,
    );
    return (
      state: _sideLesson(counted, s.step, SideLesson.takeAcrossTen),
      decisions: const [OpenSideLesson(SideLesson.takeAcrossTen)],
    );
  }
  // a mix-up in the story: thought the other one was taller
  final reversed = p.big == BigSide.a ? a + d : a - d;
  if (value == reversed) return _drawItFor(p, s, 'cmp.drawIt');
  if (value == d) return _drawItFor(p, s, 'cmp.twoBars');
  if (isDigitPermutation(value, p.bValue)) {
    return (
      state: s.copyWith(knowFlow: flow, knowMisses: 1),
      decisions: const [OpenRecheck()],
    );
  }
  return _drawItFor(p, s, null);
}
