import 'contract.dart' show specStepId;
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

/// The side lesson ended unfinished (TUT-18): the child got policy
/// `side_lessons.abandon_after_wrong_practice` practice sums wrong. It
/// ends kindly, counts as run, and the step shows its first hint.
final class SideLessonAbandoned extends LessonInput {
  const SideLessonAbandoned();
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
  const HintTaken({this.afterWrong = false, this.afterQuiet = false});

  /// Given by the tutor after a wrong step (the server's decision), not
  /// asked for from Help me.
  final bool afterWrong;

  /// Given after the quiet child's "Want a hand?" (policy `quiet.then:
  /// first_hint`, TUT-07).
  final bool afterQuiet;
}

final class ShowMeHowTaken extends LessonInput {
  const ShowMeHowTaken({this.afterWrong = false});
  final bool afterWrong;
}

/// The child's pick on "Which tree does 'it' mean?" (TUT-16, H1-4a and
/// H1-4b): `a` or `b`.
final class ItPicked extends LessonInput {
  const ItPicked(this.option);
  final String option;
}

/// "Now try a new one" at the end of show me how (TUT-05): the problem is
/// closed, scored as solved with help, and a new one of the same kind
/// follows.
final class ExampleDone extends LessonInput {
  const ExampleDone();
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
  const ShowHint(this.lineId, {this.rung});
  final String lineId;

  /// The policy rung shown (TUT-04); null for a pack's flat hint list.
  final HintRung? rung;
}

/// Every hint is used: offer the worked example.
final class SuggestShowMeHow extends Decision {
  const SuggestShowMeHow();
}

/// Show me how ran to its end (TUT-05): this problem is closed with help,
/// and [problemId] (the same pattern, new numbers) follows.
final class NextVariant extends Decision {
  const NextVariant(this.problemId);
  final String problemId;
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
    this.stepHints = 0,
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

  /// Rungs of the hint ladder shown on the current step (TUT-04); a new
  /// step starts its own ladder again.
  final int stepHints;

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
    int? stepHints,
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
    stepHints: stepHints ?? this.stepHints,
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
    stepHints,
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
  var moved = r ?? _move(pack, p, s, input);
  final after = moved.state;
  if (after.stepHints != 0 &&
      _boardSteps.contains(s.step) &&
      _boardSteps.contains(after.step) &&
      specStepId(after.step) != specStepId(s.step)) {
    // a new step: its own hint ladder, from its start rung
    moved = (state: after.copyWith(stepHints: 0), decisions: moved.decisions);
  }
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
    case HintTaken() when pack.hintLadder.isNotEmpty:
      return _nextRung(pack, s);
    case ItPicked(:final option) when _asksWhichIt(pack, s):
      // "it" is the first thing named (the template's frame: "The {a} is
      // ... It is ... than the {b}"). A wrong pick wobbles, isn't charged,
      // and leads to the next rung, the highlight (H1-4b)
      if (option == 'a') {
        return (state: s, decisions: [Coach('cmp.itRight', lineSlots(p))]);
      }
      final next = _nextRung(pack, s);
      return (
        state: next.state,
        decisions: [const Wobble(), ...next.decisions],
      );
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
    case ExampleDone():
      // scoring outcome_rules.show_me_how: with_hints, then a new variant
      return (
        state: s.copyWith(
          step: LessonStep.solved,
          knowFlow: KnowFlow.none,
          hintsUsed: s.hintsUsed == 0 ? 1 : s.hintsUsed,
        ),
        decisions: [NextVariant(p.next.helped)],
      );
    default:
      return null;
  }
}

/// The step's next rung on the policy ladder (TUT-04). Past the last, or
/// on a step with no rung, show me how is offered and no hint is charged.
StepResult _nextRung(Pack pack, LessonState s) {
  final rungs = pack.rungsFor(specStepId(s.step));
  if (s.stepHints >= rungs.length) {
    return (state: s, decisions: const [SuggestShowMeHow()]);
  }
  final rung = rungs[s.stepHints];
  return (
    state: s.copyWith(hintsUsed: s.hintsUsed + 1, stepHints: s.stepHints + 1),
    decisions: [ShowHint(rung.lineId, rung: rung)],
  );
}

/// Back from an unfinished side lesson to the step it paused, with a kind
/// word and that step's first hint (TUT-18). A step with no rung on the
/// policy ladder gets its drafted first hint (pack `cmp.firstHint.<step>`,
/// policy `steps_without_rung`: "Key drafts hint lines for these steps").
StepResult _abandoned(Pack pack, ComparisonProblem p, LessonState s) {
  final back = s.copyWith(
    step: s.returnStep,
    knowFlow: s.returnFlow,
    returnFlow: KnowFlow.none,
    stepHints: 0,
  );
  final stepId = specStepId(back.step);
  final rungs = pack.rungsFor(stepId);
  final rung = rungs.isNotEmpty
      ? rungs.first
      : HintRung(
          id: 'draft.$stepId',
          step: '$stepId',
          lineId: 'cmp.firstHint.$stepId',
        );
  return (
    state: back.copyWith(
      hintsUsed: s.hintsUsed + 1,
      stepHints: rungs.isNotEmpty ? 1 : 0,
    ),
    decisions: [
      Coach('cmp.sideKindBack', lineSlots(p)),
      ShowHint(rung.lineId, rung: rung),
    ],
  );
}

/// The rung shown last on this step asks which thing "it" means (H1-4a,
/// or the highlight H1-4b, which asks again).
bool _asksWhichIt(Pack pack, LessonState s) {
  if (s.stepHints == 0) return false;
  final rungs = pack.rungsFor(specStepId(s.step));
  if (s.stepHints > rungs.length) return false;
  final r = rungs[s.stepHints - 1];
  return r.choice.contains('a') && r.choice.contains('b') ||
      r.highlight != null;
}

/// Whether a hint request on [step] gives a hint: false on a step with no
/// rung (policy `steps_without_rung`), where Help me offers show me how
/// and something easier instead.
bool hasHint(Pack pack, LessonStep step) =>
    pack.hintLadder.isEmpty || pack.rungsFor(specStepId(step)).isNotEmpty;

StepResult _quiet(Pack pack, ComparisonProblem p, LessonState s, int ms) {
  if (!_boardSteps.contains(s.step)) return (state: s, decisions: const []);
  final t = pack.timers;
  final lines = pack.quietLines;
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
        2 => [const GlowPiece(), Coach(lines.glow, lineSlots(p))],
        3 => [
          const ShowHand(),
          if (lines.demo case final demo?) Coach(demo, lineSlots(p)),
        ],
        _ => [
          const AskStillThere(),
          if (lines.still case final still?) Coach(still, lineSlots(p)),
        ],
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
      return _findB(p, s, value, slots, right, wrongMove, maxSide);

    case (LessonStep.findTotal, NumberEntered(:final value)):
      if (value == p.total) {
        return right(s.copyWith(step: LessonStep.solved), [
          _solved(p, s, SolvedBy.draw),
        ]);
      }
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
      if ((value - p.total).abs() <= 10) return wrongMove('cmp.recheck');
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

    case (LessonStep.sideLesson, SideLessonAbandoned()):
      return _abandoned(pack, p, s);

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
        when s.knowFlow == KnowFlow.checkingTotal:
      if (value == p.total) {
        return to(
          s.copyWith(step: LessonStep.solved, knowFlow: KnowFlow.none),
          [_solved(p, s, s.barA ? SolvedBy.partway : SolvedBy.know)],
        );
      }
      if (value == dropCarry(p.aValue, p.bValue) && _canSide(s, maxSide)) {
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
  int maxSide,
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

/// The slots Julia's policy lines use (`{A}`, `{D}`, `{unit}`, `{kind}`,
/// `{b_word}`, `{problem_name}`), for problem [p]. Kept apart from
/// [lineSlots], which the engine's decisions carry.
Map<String, String> policySlots(ComparisonProblem p) {
  final a = p.a.name.toLowerCase(), b = p.b.name.toLowerCase();
  final kind = a.split(' ').last == b.split(' ').last
      ? a.split(' ').last
      : 'one';
  String title(String s) => [
    for (final w in s.split(' '))
      if (w.isNotEmpty) w[0].toUpperCase() + w.substring(1),
  ].join(' ');
  return {
    'A': '${p.aValue}',
    'D': '${p.diff}',
    'unit': p.unit,
    'kind': kind,
    'b_word': p.big == BigSide.a ? 'shorter' : 'taller',
    // the template's problem_name: "Tree Word Problem", "Bowl and Mug ..."
    'problem_name':
        '${kind == 'one' ? '${title(a)} and ${title(b)}' : title(kind)} '
        'Word Problem',
  };
}

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
  if (p.ask == Ask.b) {
    if (value == p.bValue) {
      return (
        state: s.copyWith(step: LessonStep.solved, knowFlow: KnowFlow.none),
        decisions: [_solved(p, s, s.barA ? SolvedBy.partway : SolvedBy.know)],
      );
    }
    if (isDigitPermutation(value, p.bValue)) {
      return (
        state: s.copyWith(knowFlow: KnowFlow.none),
        decisions: const [OpenRecheck()],
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
  final nearMiss =
      (value - p.total).abs() <= 10 && value != dropCarry(p.aValue, p.bValue);
  if (nearMiss || isDigitPermutation(value, p.total)) {
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
  int maxSide,
) {
  if (value == p.bValue) {
    return (
      state: s.copyWith(knowFlow: KnowFlow.checkingTotal),
      decisions: [Coach('cmp.partRight', slots)],
    );
  }
  final a = p.aValue, d = p.diff;
  final counted = s.copyWith(wrong: s.wrong + 1);
  if (p.big == BigSide.a && value == noBorrow(a, d) && _canSide(s, maxSide)) {
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
  if (isDigitPermutation(value, p.bValue)) {
    return (state: s, decisions: const [OpenRecheck()]);
  }
  return (state: _drawIt(s), decisions: const [DrawIt()]);
}
