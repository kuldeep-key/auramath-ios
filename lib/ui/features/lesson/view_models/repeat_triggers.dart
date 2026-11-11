import 'package:auramath_engine/auramath_engine.dart';

/// The side-lesson triggers that need more than one problem (TUT-08,
/// policy `side_lessons.trigger.on_repeat`): the same mistake type in two
/// problems, or the same operation wrong twice in a session. The skill
/// score and ledger triggers (below 40) wait on SKL-02 and SKL-03 (M3).
///
/// Kept for the sitting, across its problems; a new launch starts again.
/// Only the rules decide: this says when, the engine opens it within
/// `max_per_session`.
class RepeatTriggers {
  RepeatTriggers({this.sameErrorInProblems = 2, this.sameOpWrong = 2});

  /// Policy `same_error_type_in_problems`.
  final int sameErrorInProblems;

  /// Policy `same_operation_wrong_in_session`.
  final int sameOpWrong;

  final _problemsBy = <String, Set<String>>{};
  final _opWrong = <Op, int>{};

  /// One charged mistake on [problemId]: [errorType] (null when the rules
  /// name none), on a sum of [op] when it was an arithmetic step. The side
  /// lesson that is now due, if one is.
  SideLesson? charge(String problemId, String? errorType, {Op? op}) {
    final repeat = repeatSideLessons[errorType];
    if (repeat != null) {
      final seen = _problemsBy.putIfAbsent(errorType!, () => {})
        ..add(problemId);
      if (seen.length >= sameErrorInProblems) {
        seen.clear();
        return repeat;
      }
    }
    if (op != null) {
      final n = _opWrong[op] = (_opWrong[op] ?? 0) + 1;
      if (n >= sameOpWrong) {
        _opWrong[op] = 0;
        return op == Op.subtract
            ? SideLesson.takeAcrossTen
            : SideLesson.addWithCarry;
      }
    }
    return null;
  }

  /// A side lesson ran on [kind]'s skill: its count starts again.
  void ran(SideLesson kind) {
    if (kind == SideLesson.takeAcrossTen) _opWrong[Op.subtract] = 0;
    if (kind == SideLesson.addWithCarry) _opWrong[Op.add] = 0;
  }
}
