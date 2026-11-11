part of 'lesson_view_model.dart';

/// The lesson's board and session parts closed after the PRD v4.1 audit,
/// kept apart from the tutor's help so each can change on its own: the
/// whole question on any working screen (LES-02); a case whose session
/// ended carrying on in a new one (SES-01, SES-04).
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

  /// The story problem was picked on Choose today (LES-14), this many ms
  /// after it showed: logged once the case shows.
  int? chosenToday;

  /// After the new session's `problem_shown`: Choose today's choice, then
  /// a case carried on from an ended session.
  Future<void> _afterShown() async {
    if (chosenToday case final ms?) {
      chosenToday = null;
      await _vm._record([
        SpecEvent('choice_selected', {
          'step_id': 'choose_today',
          'option_id': 'story_problem',
          'ms_from_step_start': ms,
        }),
        const SpecEvent('prompt_answered', {
          'prompt': 'choose_today',
          'choice': 'story_problem',
        }),
      ]);
    }
    await _carryOn();
  }

  /// The ended session (time up, or ended by the server) whose case this
  /// lesson carries on: set by the route before [LessonViewModel.start].
  String? carryFrom;

  /// SES-01: a case whose session the app ended at time's up goes on in
  /// the continuation the server opens for that session (`continuedIn`,
  /// `resumedFrom`), its seqs following on; null for any other case, which
  /// gets a new session.
  Future<String?> _continueAfterTimeUp() async {
    final from = carryFrom;
    if (from == null) return null;
    final to = await _vm._sessions.continueAfterTimeUp(from);
    if (to != null) _vm._seq = _vm._sessions.firstSeq(to);
    return to;
  }

  /// After the new session's `problem_shown`: links it to the ended one
  /// and rebuilds the board from that session's events, through the
  /// engine, so the child carries on at the same step (SES-01, SES-04).
  Future<void> _carryOn() async {
    final from = carryFrom;
    final vm = _vm;
    final sessionId = vm._sessionId;
    if (from == null || sessionId == null || from == sessionId) return;
    carryFrom = null;
    await vm._sessions.carry(sessionId, from);
    final (:events, lastSeq: _) = await vm._sessions.resume(sessionId);
    vm._state = replay(
      vm._pack,
      vm._problem,
      inputsFrom(vm._pack, vm._problem, events),
    );
    // the question was read last time: no reading time on this one
    if (vm._state.step != LessonStep.question) vm._startedAt = vm._now();
    vm._coach('cmp.welcomeBack', const {});
    notifyListeners();
  }

  /// The child's answer to a prompt over the lesson (DAT-03): `still_there`,
  /// `too_hard`, `time_up`, `paused` or `offline`, and the choice tapped.
  void promptAnswered(String prompt, String choice) => unawaited(
    _vm._record([
      SpecEvent('prompt_answered', {'prompt': prompt, 'choice': choice}),
    ]),
  );

  /// "I know it" tapped (DAT-03): `i_know_it_opened` with the step the
  /// child is on.
  void _knowItOpened() => unawaited(
    _vm._record([
      SpecEvent('i_know_it_opened', {'step_id': specStepId(_vm.state.step)}),
    ]),
  );

  /// The flag `word_meanings` (LES-10): the question's maths words can be
  /// tapped for what they mean.
  bool wordMeanings = false;

  /// The word whose meaning is open (`taller`), if any.
  String? wordOpen;

  /// Opens [word]'s meaning and logs `word_meaning_opened`.
  void openWord(String word) {
    if (!wordMeanings) return;
    wordOpen = word;
    notifyListeners();
    unawaited(
      _vm._record([
        SpecEvent('word_meaning_opened', {'word_id': word}),
      ]),
    );
  }

  void closeWord() {
    wordOpen = null;
    notifyListeners();
  }

  /// Turns on the template's optional steps by flag (LES-03): today
  /// `name_quantities` (LES-12) and `number_sentence` (LES-06). Set
  /// before the lesson starts or resumes, so a replay runs the same steps.
  /// [addingUp] also offers "D + ? = A" at choose_operation (LES-06).
  void enableSteps(Set<String> steps, {bool addingUp = false}) =>
      _vm._pack = _vm._pack.copyWith(optionalSteps: steps, addingUp: addingUp);

  /// The flag `weight_stories` (CON-11): a weight story's bars are drawn
  /// across (LES-04). Off, the server sends no weight stories.
  bool weightStories = false;
}
