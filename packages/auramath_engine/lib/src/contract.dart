import 'lesson.dart';
import 'mistakes.dart';
import 'pack.dart';
import 'problem.dart';

/// One event in the backend's contract (spec pack
/// `contracts/events.schema.json`), before the app adds its envelope
/// (event id, session, seq, time, child and device).
class SpecEvent {
  const SpecEvent(this.name, this.payload);

  final String name;
  final Map<String, Object?> payload;
}

/// Times only the app knows: since the step was entered, since the problem
/// was shown, and how long the child read before starting.
typedef Timing = ({int stepMs, int problemMs, int readingMs});

/// The spec's id for a step; null for screens that aren't drawing steps.
String? specStepId(LessonStep s) => switch (s) {
  LessonStep.drawA => 'draw_known_bar',
  LessonStep.placeB || LessonStep.sizeB => 'size_second_bar',
  LessonStep.placeGap => 'place_difference',
  LessonStep.placeTotal => 'place_total',
  LessonStep.chooseOp => 'choose_operation',
  LessonStep.findB => 'find_unknown',
  LessonStep.findTotal => 'find_total',
  _ => null,
};

/// The skill each mistake points to (spec `content/skill-map.yaml`).
const errorSkill = <String, String?>{
  'difference_as_amount': 'cmp.read-difference',
  'relation_reversed': 'cmp.read-relation',
  'keyword_strategy': 'cmp.inconsistent-wording',
  'operation_reversed': 'cmp.choose-operation',
  'sub_smaller_from_larger': 'arith.sub-3d-regroup',
  'carry_dropped': 'arith.add-3d-regroup',
  'answered_wrong_question': 'prob.read-question',
  'transposition': null,
};

const _sideSkill = {
  SideLesson.takeAcrossTen: 'arith.sub-3d-regroup',
  SideLesson.addWithCarry: 'arith.add-3d-regroup',
};

const _sideError = {
  SideLesson.takeAcrossTen: 'sub_smaller_from_larger',
  SideLesson.addWithCarry: 'carry_dropped',
};

SpecEvent problemShown(ComparisonProblem p) => SpecEvent('problem_shown', {
  'problem_id': p.id,
  'template_id': p.templateId,
  'template_version': p.templateVersion,
  'story_id': p.storyId,
  'relation': p.big == BigSide.a ? 'taller' : 'shorter',
  'level': ?p.level,
  'variant': p.variant,
  'numbers': {'A': p.aValue, 'D': p.diff},
});

/// The spec events one child input writes, given the state [before] it and
/// the engine's [result]. Pure: the same arguments give the same events.
List<SpecEvent> eventsFor(
  ComparisonProblem p,
  LessonState before,
  LessonInput input,
  StepResult result,
  Timing t,
) {
  final after = result.state;
  final decisions = result.decisions;
  final stepId = specStepId(before.step);
  final moved = after.step != before.step;
  final out = <SpecEvent>[];

  void committed(bool correct, [String? error]) => out.add(
    SpecEvent('step_committed', {
      'step_id': stepId,
      'correct': correct,
      'error_type': error,
      'skill_charged': correct ? null : errorSkill[error],
      'ms_from_step_start': t.stepMs,
    }),
  );

  void placed(
    String object,
    String target,
    bool done, [
    Map<String, Object?>? more,
  ]) => out.add(
    SpecEvent('object_placed', {
      'step_id': stepId,
      'object': object,
      'target': target,
      'committed': done,
      'ms_from_step_start': t.stepMs,
      ...?more,
    }),
  );

  void helpOpened() => out.add(
    SpecEvent('help_opened', {'step_id': stepId, 'trigger': 'child'}),
  );

  void answered(
    String field,
    String stage,
    int value,
    bool correct,
    String? error,
  ) => out.add(
    SpecEvent('i_know_it_answered', {
      'field': field,
      'value': value,
      'correct': correct,
      'error_type': error,
      'stage': stage,
      'route': _route(decisions, correct),
      'ms_from_problem_start': t.problemMs,
    }),
  );

  switch (input) {
    case Started():
      break;
    case BarADrawn():
      placed('bar_a', 'board', true);
      committed(true);
    case BarBPlaced():
      placed('bar_b', 'board', false);
    case BarBSized(:final rel):
      placed('bar_b', 'board', rel != Relation.same, {
        'relative_to_bar_a': switch (rel) {
          Relation.taller => 'longer',
          Relation.shorter => 'shorter',
          Relation.same => 'equal',
        },
      });
      if (rel != Relation.same) {
        committed(moved, moved ? null : 'relation_reversed');
      }
    case PieceDropped(:final piece, :final target):
      placed(
        piece == Piece.gap ? 'difference' : 'total',
        switch (target) {
          Target.gapSlot => 'gap',
          Target.totalSlot => 'across_both',
          Target.barA => 'bar_a',
          Target.barB => 'bar_b',
        },
        true,
        {if (piece == Piece.gap) 'value': p.diff},
      );
      committed(
        moved,
        !moved && piece == Piece.gap && target == Target.barB
            ? 'difference_as_amount'
            : null,
      );
    case OpChosen(:final op):
      out.add(
        SpecEvent('choice_selected', {
          'step_id': stepId,
          'option_id': op == Op.add ? 'a_plus_d' : 'a_minus_d',
          'ms_from_step_start': t.stepMs,
        }),
      );
      committed(
        moved,
        moved
            ? null
            : (op == Op.add ? 'operation_reversed' : 'keyword_strategy'),
      );
    case NumberEntered(:final value):
      out.add(
        SpecEvent('value_entered', {
          'step_id': stepId,
          'value': value,
          'submitted': true,
          'ms_from_step_start': t.stepMs,
        }),
      );
      final right = before.step == LessonStep.findB
          ? value == p.bValue
          : value == p.total;
      committed(
        right,
        right
            ? null
            : before.step == LessonStep.findB
            ? _unknownError(p, value, answerSheet: false)
            : _totalError(p, value),
      );
    case KnowIt(:final value):
      final total = p.ask == Ask.total;
      final right = value == (total ? p.total : p.bValue);
      answered(
        total ? 'total' : 'unknown',
        total ? 'total' : 'unknown',
        value,
        right,
        right
            ? null
            : total
            ? (value == p.bValue
                  ? 'answered_wrong_question'
                  : value == reverseDigits(p.total)
                  ? 'transposition'
                  : null)
            : _unknownError(p, value, answerSheet: true),
      );
    case PartChecked(:final value):
      final right = value == p.bValue;
      answered(
        'unknown',
        'unknown',
        value,
        right,
        right ? null : _unknownError(p, value, answerSheet: true),
      );
    case KnowTotalChecked(:final value):
      final right = value == p.total;
      answered(
        'total',
        'total_after_unknown',
        value,
        right,
        right ? null : _totalError(p, value),
      );
    case SideLessonDone():
      out.add(
        SpecEvent('side_lesson_ended', {
          'skill_id': _sideSkill[before.sideLesson],
          'completed': true,
        }),
      );
    case Undo():
      out.add(
        SpecEvent('undo_used', {
          'step_id': stepId,
          'object': switch (before.step) {
            LessonStep.sizeB || LessonStep.placeGap => 'bar_b',
            LessonStep.placeTotal => 'difference',
            _ => p.ask == Ask.total ? 'total' : 'difference',
          },
        }),
      );
    case HintTaken():
      helpOpened();
      out.add(
        SpecEvent('hint_shown', {
          'step_id': stepId,
          'rung_id': 'H${after.hintsUsed}',
          'line_id': switch (decisions.firstOrNull) {
            ShowHint(:final lineId) => lineId,
            _ => 'cmp.showMeHow',
          },
          'model_used': false,
        }),
      );
    case ShowMeHowTaken():
      helpOpened();
      out.add(
        const SpecEvent('worked_example_shown', {
          'example_story_id': 'building-a-b',
        }),
      );
    case EasierTaken():
      helpOpened();
      out.add(
        SpecEvent('easier_chosen', {
          'from_problem_id': p.id,
          'trigger': 'child',
        }),
      );
    case QuietFor(:final ms):
      final level = switch (decisions) {
        _ when decisions.any((d) => d is AskStillThere) => 'still_there',
        _ when decisions.any((d) => d is ShowHand) => 'demo',
        _ when decisions.any((d) => d is GlowPiece) => 'glow',
        _ when decisions.any((d) => d is PulseHelp) => 'help_pulse',
        _ => null,
      };
      if (level != null) {
        out.add(
          SpecEvent('idle_prompt_shown', {
            'level': level,
            'after_ms': ms,
            'step_id': ?stepId,
          }),
        );
      }
  }

  for (final d in decisions) {
    if (d is OpenSideLesson) {
      final error = out.lastWhereOrNull((e) => e.payload['error_type'] != null);
      out.add(
        SpecEvent('side_lesson_started', {
          'skill_id': _sideSkill[d.kind],
          'error_type': error?.payload['error_type'] ?? _sideError[d.kind],
        }),
      );
    }
  }

  final entered = specStepId(after.step);
  if (moved && entered != null && entered != specStepId(before.step)) {
    out.add(SpecEvent('step_entered', {'step_id': entered}));
  }

  for (final d in decisions) {
    if (d is Solved) {
      final helped = after.hintsUsed > 0 || after.sideLessonRan;
      out
        ..add(
          SpecEvent('problem_completed', {
            'problem_id': p.id,
            'outcome': helped
                ? 'with_hints'
                : switch (after.wrong) {
                    0 => 'solved_alone',
                    1 => 'one_wrong',
                    _ => 'two_or_more_wrong',
                  },
            'working_ms': t.problemMs - t.readingMs,
            'reading_ms': t.readingMs,
            'wrong_count': after.wrong,
            'hints_used': after.hintsUsed,
            'drew_model': before.barA,
            'via_i_know_it': d.by != SolvedBy.draw,
          }),
        )
        ..add(SpecEvent('badge_awarded', {'badge_id': d.badgeId}));
    }
  }
  return out;
}

/// Turns saved spec events back into the inputs that wrote them, so a lesson
/// resumes by replaying its own log through the engine.
List<LessonInput> inputsFrom(
  Pack pack,
  ComparisonProblem p,
  Iterable<SpecEvent> events,
) {
  var s = initialState();
  final inputs = <LessonInput>[];
  for (final e in events) {
    final j = e.payload;
    final LessonInput? input = switch (e.name) {
      'step_entered' when s.step == LessonStep.question => const Started(),
      'object_placed' => switch (j['object']) {
        'bar_a' => const BarADrawn(),
        'bar_b' => switch (j['relative_to_bar_a']) {
          'longer' => const BarBSized(Relation.taller),
          'shorter' => const BarBSized(Relation.shorter),
          'equal' => const BarBSized(Relation.same),
          _ => const BarBPlaced(),
        },
        final object => PieceDropped(
          object == 'difference' ? Piece.gap : Piece.total,
          switch (j['target']) {
            'gap' => Target.gapSlot,
            'across_both' => Target.totalSlot,
            'bar_a' => Target.barA,
            _ => Target.barB,
          },
        ),
      },
      'choice_selected' => OpChosen(
        j['option_id'] == 'a_plus_d' ? Op.add : Op.subtract,
      ),
      'value_entered' => NumberEntered(j['value']! as int),
      'i_know_it_answered' => switch (j['stage']) {
        'total_after_unknown' => KnowTotalChecked(j['value']! as int),
        'unknown' when s.knowFlow == KnowFlow.checkingPart => PartChecked(
          j['value']! as int,
        ),
        _ => KnowIt(j['value']! as int),
      },
      'side_lesson_ended' => const SideLessonDone(),
      'undo_used' => const Undo(),
      'hint_shown' => const HintTaken(),
      'worked_example_shown' => const ShowMeHowTaken(),
      'easier_chosen' => const EasierTaken(),
      'idle_prompt_shown' => QuietFor(j['after_ms']! as int),
      _ => null,
    };
    if (input == null) continue;
    inputs.add(input);
    s = step(pack, p, s, input).state;
  }
  return inputs;
}

/// Template `error_rules` / `answer_sheet_rules` for a wrong unknown. On the
/// answer sheet nothing is drawn, so A + D reads as "thought it was taller".
String? _unknownError(ComparisonProblem p, int v, {required bool answerSheet}) {
  final a = p.aValue, d = p.diff;
  if (v == d) return 'difference_as_amount';
  if (p.big == BigSide.a) {
    if (v == a + d) {
      return answerSheet ? 'relation_reversed' : 'difference_as_amount';
    }
    if (v == noBorrow(a, d)) return 'sub_smaller_from_larger';
  } else {
    if (v == a - d) return 'keyword_strategy';
    if (v == dropCarry(a, d)) return 'carry_dropped';
  }
  if (v == reverseDigits(p.bValue)) return 'transposition';
  return null;
}

String? _totalError(ComparisonProblem p, int v) {
  if (v == p.bValue) return 'answered_wrong_question';
  if (v == dropCarry(p.aValue, p.bValue)) return 'carry_dropped';
  if (v == reverseDigits(p.total)) return 'transposition';
  return null;
}

/// Tutor policy `answer_sheet.routes`, read from what the engine decided.
String? _route(List<Decision> decisions, bool correct) {
  if (correct && decisions.any((d) => d is Solved)) return null;
  for (final d in decisions) {
    switch (d) {
      case OpenSideLesson():
        return 'side_lesson_then_answer';
      case DrawIt():
        return 'draw_it';
      case AskWhatQuestionAsks():
        return 'ask_question_again';
      case OpenRecheck():
        return 'check_again';
      case CheckOnePart():
        return 'check_unknown_first';
      default:
    }
  }
  return null;
}

extension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
