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
  Set<String> prompts = const {},
}) {
  final c = committed.payload;
  final correct = c['correct'] == true;
  // swapped digits are only a recheck: nothing else is allowed (LES-09)
  final carryOn = correct || c['error_type'] == 'transposition';
  final shown = problemShown(problem).payload;
  final numbers = shown['numbers']! as Map<String, Object?>;
  return {
    'point': 'after_step',
    'allowed': carryOn
        ? ['continue']
        : [
            if (after.sideLessons < maxSideLessons) 'side_lesson',
            'hint',
            'continue',
            // the prompts this app shows: the server's rules give them
            // first when due (AI-09, AI-10)
            ...prompts,
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

/// Every `help.action` and `next.action` of a decision record
/// (`contracts/decision.schema.json`).
const helpActions = {
  'none',
  'hint',
  'show_me_how',
  'easier',
  'side_lesson',
  'check_again',
  'read_again',
  'seen_before',
};
const nextActions = {
  'continue',
  'same_level_new_numbers',
  'one_easier_then_back',
  'next_level',
  'end_case',
  'end_session',
};

/// The earlier case a `seen_before` decision links to (AI-10), from its
/// `help.seen_before`; it may be missing.
typedef SeenBefore = ({String problemId, int? solvedAt});

/// What the lesson acts on from a decision: its help and next action, the
/// side lesson's skill, and the case it links to.
typedef AiChoice = ({
  String help,
  String next,
  String? sideSkill,
  SeenBefore? seenBefore,
});

/// The server's choice in [reply] (`POST .../decisions`), or null when
/// the rules made it there too (the evaluator off, a fallback, a reply
/// this app can't read): then the phone's own choice stands. Pure.
AiChoice? aiChoice(Map<String, Object?> reply) {
  final d = reply['decision'];
  final help = d is Map ? d['help'] : null;
  // read again and seen before come from the rules, whoever decided
  if (const {'read_again', 'seen_before'}.contains(reply['action'])) {
    final seen = help is Map ? help['seen_before'] : null;
    final seenId = seen is Map ? seen['problem_id'] : null;
    return (
      help: reply['action']! as String,
      next: 'continue',
      sideSkill: null,
      seenBefore: seenId is String
          ? (problemId: seenId, solvedAt: _ms((seen as Map)['solved_at']))
          : null,
    );
  }
  if (reply['source'] != 'evaluator' || reply['fallbackUsed'] == true) {
    return null;
  }
  if (d is! Map) {
    // no record: the action itself, one of after_step's allowed
    final help = switch (reply['action']) {
      'side_lesson' => 'side_lesson',
      'hint' => 'hint',
      'continue' => 'none',
      _ => null,
    };
    return help == null
        ? null
        : (help: help, next: 'continue', sideSkill: null, seenBefore: null);
  }
  if (d['fallback_used'] == true) return null;
  final action = (help as Map?)?['action'];
  if (!helpActions.contains(action)) return null;
  final next = (d['next'] as Map?)?['action'];
  final seen = help!['seen_before'];
  final seenId = seen is Map ? seen['problem_id'] : null;
  return (
    help: action as String,
    next: nextActions.contains(next) ? next as String : 'continue',
    sideSkill: help['side_lesson_skill'] as String?,
    seenBefore: seenId is String
        ? (problemId: seenId, solvedAt: _ms((seen as Map)['solved_at']))
        : null,
  );
}

/// `solved_at` as epoch ms: the server sends an ISO time or a number.
int? _ms(Object? at) => switch (at) {
  final int ms => ms,
  final String iso => DateTime.tryParse(iso)?.millisecondsSinceEpoch,
  _ => null,
};
