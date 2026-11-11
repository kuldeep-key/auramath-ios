part of 'lesson_view_model.dart';

/// The lesson's board and session parts closed after the PRD v4.1 audit,
/// kept apart from the tutor's help so each can change on its own: the
/// whole question on any working screen (LES-02).
mixin _LessonGaps on ChangeNotifier {
  LessonViewModel get _vm => this as LessonViewModel;

  /// "See the question" is open: the whole question over the work, which
  /// stays as it was underneath (LES-02).
  bool questionOpen = false;

  /// Opens the whole question and logs `question_reopened` with the step
  /// the child is on (a side lesson's: the step it was opened from).
  void seeQuestion() {
    if (questionOpen || _vm._p == null) return;
    questionOpen = true;
    notifyListeners();
    final s = _vm.state;
    unawaited(
      _vm._record([
        SpecEvent('question_reopened', {
          'step_id':
              specStepId(s.step) ??
              (s.returnStep == null ? null : specStepId(s.returnStep!)) ??
              'question',
        }),
      ]),
    );
  }

  void closeQuestion() {
    questionOpen = false;
    notifyListeners();
  }
}
