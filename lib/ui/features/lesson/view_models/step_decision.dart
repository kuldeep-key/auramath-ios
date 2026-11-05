import 'package:auramath_engine/auramath_engine.dart';

/// What the child did during one board step, beyond what the engine keeps:
/// the `step` body of a decision asks for it.
class StepSignals {
  int undos = 0;
  bool helpOpened = false;
  bool backgrounded = false;
  bool readAloudUsed = false;

  void reset() {
    undos = 0;
    helpOpened = backgrounded = readAloudUsed = false;
  }
}

/// The `after_step` decision for one `step_committed` event ([committed],
/// saved as [seq]): the actions the rules allow there, the one our engine
/// took ([decisions]), and the step for the server to judge. Pure.
Map<String, Object?> afterStepDecision({
  required ComparisonProblem problem,
  required LessonState after,
  required LessonInput input,
  required List<Decision> decisions,
  required SpecEvent committed,
  required int seq,
  required StepSignals signals,
  required int maxSideLessons,
}) {
  final c = committed.payload;
  final correct = c['correct'] == true;
  final shown = problemShown(problem).payload;
  final numbers = shown['numbers']! as Map<String, Object?>;
  return {
    'point': 'after_step',
    'allowed': correct
        ? ['continue']
        : [
            if (after.sideLessons < maxSideLessons) 'side_lesson',
            'hint',
            'continue',
          ],
    // a correct step always carries on (backend, 5 Nov)
    'rulesDefault': correct
        ? 'continue'
        : decisions.any((d) => d is OpenSideLesson)
        ? 'side_lesson'
        : decisions.any((d) => d is ShowHint || d is SuggestShowMeHow)
        ? 'hint'
        : 'continue',
    'facts': {'step_id': c['step_id'], 'wrong_count': after.wrongRow},
    'step': {
      'problemId': problem.id,
      'level': ?problem.level,
      'relation': shown['relation'],
      'A': numbers['A'],
      'D': numbers['D'],
      'stepId': c['step_id'],
      if (input case NumberEntered(:final value)) 'value': value,
      'phoneVerdict': correct ? 'correct' : 'incorrect',
      'phoneErrorType': c['error_type'],
      'eventSeq': seq,
      'msFromStepStart': c['ms_from_step_start'],
      'wrongAttempts': after.wrongRow,
      'undos': signals.undos,
      'hintsUsed': after.hintsUsed,
      'rung': null,
      'helpOpened': signals.helpOpened,
      'sideLessonsSoFar': after.sideLessons,
      'detoursSoFar': after.sideLessons,
      'backgrounded': signals.backgrounded,
      'readAloudUsed': signals.readAloudUsed,
    },
  };
}
