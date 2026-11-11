import 'dart:async';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/session_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../data/services/voice.dart';
import '../../../core/parts/standing_button.dart';
import 'line_library.dart';
import 'sitting.dart';
import 'step_decision.dart';

/// Which answer sheet is open during "I know it".
enum KnowPrompt { answer, whatAsked, recheck, checkPart, checkTotal }

/// A prompt the tutor's decision opens over the board: read the question
/// again (AI-09), or a case like this one solved before (AI-10).
enum TutorPrompt { readAgain, seenBefore }

/// Where a side lesson is once its blocks are worked: the child types the
/// sum, practises a few if it was wrong, then goes back.
enum SideStage { ownSum, practice, back }

/// Replaces each `{key}` in a pack line with its slot value.
/// The arithmetic level of a side lesson's practice sums: the kind of the
/// child's own sum, within 100 (policy `practice_if_unsure`: "smaller
/// numbers ... of the same type"). A carry or a borrow in any column, as
/// the server counts them, makes it a regrouping level.
String practiceLevel(({int left, int right, bool subtract}) sum) {
  var (a, b) = (sum.left, sum.right);
  var regroups = false;
  while ((a > 0 || b > 0) && !regroups) {
    regroups = sum.subtract ? a % 10 < b % 10 : a % 10 + b % 10 >= 10;
    a ~/= 10;
    b ~/= 10;
  }
  if (sum.subtract) return regroups ? 'A6' : 'A4';
  return regroups ? 'A5' : 'A3';
}

String fillLine(String template, Map<String, String> slots) => template
    .replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => slots[m[1]] ?? m[0]!);

/// Runs one lesson: hands each child input to the engine, saves it, and turns
/// the engine's decisions into what the screens show. Decides nothing itself.
class LessonViewModel extends ChangeNotifier {
  LessonViewModel({
    required Pack pack,
    required String problemId,
    required this._sessions,
    required this._voice,
    required this._openSession,
    required this._sitting,

    /// An already-open session: a resumed case.
    this._sessionId,

    /// Problems come from the server (`problems/next`): [problemId]
    /// [newProblem] waits for one, and "something easier" and the next
    /// case ask for them. Null: the bundled pack's own chain.
    this._nextProblem,
    int Function()? nowMs,
    Duration? tickEvery = const Duration(seconds: 1),
  }) : _pack = pack,
       _p = pack.problems[problemId],
       _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch) {
    assert(_p != null || _nextProblem != null, 'no problem $problemId');
    _lastMoveMs = _shownAt = _stepAt = _lastTickMs = _now();
    _sitting.newLesson();
    if (tickEvery != null) _ticker = Timer.periodic(tickEvery, (_) => tick());
    _sessions.online.addListener(_onlineChanged);
    _sessions.ended.addListener(_endedByServer);
    _voice.resting.addListener(_voiceResting);
  }

  final Pack _pack;
  final Sitting _sitting;
  final SessionRepository _sessions;
  final Voice _voice;

  /// Asks the server for a new session (online-first).
  final Future<String> Function() _openSession;
  final Future<ComparisonProblem> Function(String sessionId, {String? level})?
  _nextProblem;
  final int Function() _now;
  Timer? _ticker;

  /// Each committed step goes to the server's `decisions` (TUT-01, AI-04),
  /// so its evaluator can judge steps once it's on. Off for a server older
  /// than spec v0.4.1 (no such route).
  bool askDecisions = false;
  final _signals = StepSignals();

  /// The flag `ai_decisions`: after a wrong step its help waits for the
  /// server's decision and shows that instead of the rules' (AI-04). Off:
  /// the rules' choice shows at once and the decision is only logged.
  bool actOnDecisions = false;

  /// App-config `ai` (NFR-05): no decision after [cueAfterMs], a thinking
  /// cue; none after [fallbackAfterMs], the rules' choice. Each reply's
  /// own values are used from the next step on.
  int cueAfterMs = 1000;
  int fallbackAfterMs = 4000;

  /// The case partner's small thinking cue while a decision is late.
  /// Never a blocking spinner: the child can carry on meanwhile.
  bool thinking = false;

  /// Flags `read_again_prompt` (AI-09) and `seen_before_bridge` (AI-10):
  /// off, a decision for either shows the rules' help.
  bool readAgainPrompt = false;
  bool seenBeforeBridge = false;

  /// The tutor's prompt open now, if any.
  TutorPrompt? prompt;

  /// The solved case the seen-before prompt shows a peek of; null when the
  /// decision named none, or this phone doesn't have it.
  ComparisonProblem? seenCase;

  void closePrompt() {
    prompt = null;
    notifyListeners();
  }

  /// A wrong step whose help waits for the server's decision.
  _Held? _held;
  bool _disposed = false;

  /// The problem id that means "the server's next one".
  static const newProblem = 'new';

  /// Null while the server's next problem is on its way.
  ComparisonProblem? _p;
  ComparisonProblem get _problem => _p!;

  /// The level to ask for with the next problem ("something easier").
  String? _askLevel;

  /// Null until the server opened the session.
  String? _sessionId;
  LessonState _state = initialState();

  /// The seq the next saved event gets.
  int _seq = 0;
  late int _lastMoveMs;
  late int _shownAt;
  late int _stepAt;
  late int _lastTickMs;
  int? _startedAt;
  int? _pausedAt;

  ComparisonProblem get problem => _problem;
  String get sessionId => _sessionId ?? '';

  /// The server opened this lesson's session (and sent its problem); until
  /// then nothing is drawn.
  bool get ready => _sessionId != null && _p != null;

  /// The session couldn't be opened: no connection, or the server said no.
  /// The lesson waits on a "need the internet" screen with Try again.
  ApiException? startError;
  LessonState get state => _state;
  Pack get pack => _pack;
  SessionRepository get sessions => _sessions;

  /// Events saved for the current session.
  int get recorded => _seq;

  /// The case the child left last time, waiting for "try it again?".
  ComparisonProblem? offerLeft;

  /// The child's answer to [offerLeft]: that case, shown as it was, or
  /// the server's next one.
  Future<void> takeLeft({required bool again}) {
    if (again) {
      _p = offerLeft;
      // the child chose this case: a check due waits for the next session
      _sessions.checkShown(_sessionId!);
    }
    offerLeft = null;
    return start();
  }

  /// "Leave this one" (SES-06): the server keeps it to offer back another
  /// day, and this session ends.
  Future<void> leaveProblem() async {
    askingBreak = false;
    await _record([
      SpecEvent('problem_left', {
        'problem_id': _problem.id,
        'step_id': specStepId(_state.step),
      }),
      const SpecEvent('session_ended', {'reason': 'left'}),
    ]);
  }

  /// Opens a new session on this problem (asking the server for it, when
  /// problems are the server's): `session_started`, `problem_shown`.
  Future<void> start() async {
    startError = null;
    try {
      final sessionId = _sessionId ??= await _openSession();
      final next = _nextProblem;
      if (_p == null && next != null) {
        // a new child's four starting sums come first (SKL-07)
        if (await _startingCheck(sessionId)) return;
        // a case left last time: offered back first (SES-06)
        final left = _sessions.leftProblem(_pack, sessionId);
        if (left != null) {
          offerLeft = left;
          notifyListeners();
          return;
        }
        _p = await next(sessionId, level: _askLevel);
        _askLevel = null;
      } else if (next != null && _sessions.checkDue(sessionId)) {
        // a case fetched ahead last session: the check due here comes first
        _p = await next(sessionId);
      }
      // the session's first case is known: a fetch ahead isn't the check
      _sessions.checkShown(sessionId);
    } on ApiException catch (e) {
      startError = e;
      notifyListeners();
      return;
    }
    notifyListeners();
    _warmVoice(); // the problem is known now, from the pack or the server
    final events = [
      SpecEvent('session_started', {
        'launch_source': launchSource,
        'content_versions': {
          ..._sessions.identity.contentVersions,
          'template.${_problem.templateId}': _problem.templateVersion,
        },
        'is_demo': _sessions.identity.isDemo,
      }),
      problemShown(_problem),
    ];
    await _record(events);
  }

  /// The starting check's four sums (SKL-07), while a new child does them
  /// before the first case; empty once done, or when there's none.
  List<Sum> startingSums = const [];
  int startingAt = 0;
  int _startingRight = 0;
  bool _startingChecked = false;

  /// The child is on the starting sums: no case yet.
  bool get inStartingCheck =>
      startingSums.isNotEmpty && startingAt < startingSums.length;

  /// True while the child is on the starting sums. Loads them the first
  /// time; once all four are typed, sends the result, and the case is asked
  /// at the level the server places the child at.
  Future<bool> _startingCheck(String sessionId) async {
    final id = childId;
    if (id == null || _startingChecked) return false;
    if (!_sessions.startingCheckDue(sessionId)) return false;
    if (startingSums.isEmpty) {
      try {
        startingSums = await _sessions.startingSums(id);
      } on ApiException catch (e) {
        if (e.offline) rethrow;
        // no sums (throttled, a server error): the case starts at the age's
        // level, and we hear about it
        _sessions.failed(sessionId, 'starting sums not fetched: $e');
      }
      if (startingSums.isEmpty) {
        _startingChecked = true;
        return false;
      }
      startingAt = _startingRight = 0;
      _itemAt = _now();
    }
    if (inStartingCheck) {
      notifyListeners();
      return true;
    }
    try {
      _askLevel = await _sessions.sendStartingCheck(
        sessionId,
        id,
        correct: _startingRight,
      );
    } on ApiException catch (e) {
      if (e.offline) rethrow;
      // not placed: the case starts at the level the server already has,
      // the four answers are in the log, and we hear about it
      _sessions.failed(sessionId, 'starting check not sent: $e');
    }
    _startingChecked = true;
    startingSums = const [];
    return false;
  }

  /// One starting sum typed: logged as `placement_answered`, with its time
  /// (never shown). After the last one the lesson starts.
  Future<void> answerStarting(int value) async {
    final item = startingSums[startingAt];
    final correct = value == item.answer;
    if (correct) _startingRight++;
    final now = _now();
    final at = startingAt++;
    notifyListeners();
    // saved without waiting on the network, so the next sum is heard at
    // once; the last one is waited for before the case starts
    final saving = _record([
      SpecEvent('placement_answered', {
        'item_id': 'start-${at + 1}',
        'value': value,
        'correct': correct,
        'ms_from_item_start': now - _itemAt,
      }),
    ]);
    _itemAt = now;
    if (inStartingCheck) return unawaited(saving);
    await saving;
    await start();
  }

  Future<void> _record(List<SpecEvent> events) async {
    final sessionId = _sessionId;
    // nothing happened yet to record, or the server closed the log
    if (sessionId == null || endedByServer) return;
    final first = _seq;
    _seq += events.length;
    await _sessions.record(sessionId, first, events);
  }

  String coachText = '';
  Attention helpAttention = Attention.none;
  bool glowPiece = false;
  bool showHand = false;
  bool stillThere = false;

  /// [stillThere] is open because the child has been on one step for policy
  /// `no_progress_minutes`, moving or not: too hard, so offer a way out
  /// (TUT-10). Once per step.
  bool tooHard = false;
  bool _wayOutOffered = false;
  int wobbles = 0;
  KnowPrompt? knowPrompt;
  SideLesson? sideLesson;
  String? badgeId;
  BadgeInfo? get badge => _pack.badges[badgeId];
  String? nextProblemId;

  /// The sitting reached its cap: show "That's today's time!".
  bool timeUp = false;

  /// Home was tapped mid-lesson: ask "Take a break?" first.
  bool askingBreak = false;

  /// "Show me how" was chosen: the worked example covers the board until
  /// "Now you try" (Figma H2, H2-1 to H2-3).
  bool showingExample = false;

  void closeExample() {
    showingExample = false;
    notifyListeners();
  }

  /// "Now try a new one" after show me how (TUT-05): this problem closes,
  /// scored as solved with help, and a new one of the same kind opens.
  Future<void> exampleDone() async {
    showingExample = false;
    await send(const ExampleDone());
  }

  /// Rebuilds the lesson from its saved events: replayed through the engine,
  /// never from a snapshot.
  Future<void> restore() async {
    _warmVoice();
    final sessionId = _sessionId!;
    final (:events, :lastSeq) = await _sessions.resume(sessionId);
    _state = replay(_pack, _problem, inputsFrom(_pack, _problem, events));
    _seq = lastSeq + 2;
    await _sessions.record(sessionId, lastSeq + 1, const [
      SpecEvent('session_resumed', {}),
    ]);
    _coach('cmp.welcomeBack', const {});
    notifyListeners();
  }

  /// Counts the sitting's time, then sends a quiet-child tick; the engine
  /// decides whether that matters.
  Future<void> tick() async {
    final now = _now();
    // locked, or waiting for the internet (SES-04): the cap doesn't run
    if (_pausedAt == null && (online || !clockPausesOffline)) {
      _sitting.activeMs += now - _lastTickMs;
    }
    _lastTickMs = now;
    if (_sitting.over &&
        !_sitting.finishing &&
        !timeUp &&
        _state.step != LessonStep.solved) {
      timeUp = true;
      notifyListeners();
    }
    if (!_wayOutOffered &&
        _pausedAt == null &&
        _onBoard &&
        now - _stepAt >= _pack.noProgressMs) {
      _wayOutOffered = tooHard = stillThere = true;
      notifyListeners();
    }
    await send(QuietFor(now - _lastMoveMs));
  }

  bool get _onBoard => !const {
    LessonStep.question,
    LessonStep.sideLesson,
    LessonStep.solved,
  }.contains(_state.step);

  /// Time's up mid-problem: the child may finish it. A problem not begun
  /// yet waits for tomorrow.
  bool get canFinish => _state.step != LessonStep.question;

  /// Time's up, and the child keeps going until this problem is done.
  void finishThisOne() {
    timeUp = false;
    _sitting.finishing = true;
    notifyListeners();
  }

  /// Time's up, and the child stops; the work stays in the log (SES-01).
  Future<void> callItADay() async {
    timeUp = false;
    notifyListeners();
    await _sitting.save();
    await _record([
      SpecEvent('session_ended', {
        'reason': 'time_up',
        'active_ms': _sitting.activeMs,
      }),
    ]);
  }

  /// The phone locked or the app went to the background (SES-03).
  Future<void> paused() async {
    if (_pausedAt != null) return;
    _pausedAt = _now();
    _signals.backgrounded = true;
    await _sitting.save();
    await _record(const [
      SpecEvent('session_paused', {'reason': 'lock'}),
    ]);
  }

  /// Back from the background: the time away doesn't count.
  Future<void> resumed() async {
    final since = _pausedAt;
    if (since == null) return;
    _pausedAt = null;
    final now = _now();
    _lastTickMs = _lastMoveMs = now;
    await _record([
      SpecEvent('session_resumed', {'after_ms': now - since}),
    ]);
  }

  void askBreak() {
    askingBreak = true;
    notifyListeners();
  }

  void keepGoing() {
    askingBreak = false;
    notifyListeners();
  }

  /// App-config `session.clock_pauses_while_offline` (SES-04).
  bool clockPausesOffline = true;

  /// The server can't be reached (or can again). Online-first: the lesson
  /// pauses until it can; every tap so far is held and resent (SES-04).
  bool get online => _sessions.online.value;

  /// "Try again" on the paused lesson.
  Future<void> retryConnection() => _sessions.syncNow();

  void _onlineChanged() {
    notifyListeners();
    _record([
      SpecEvent('connectivity_changed', {'online': online}),
    ]);
  }

  /// The server ended this lesson (offline 10+ min, idle 30 min, or a full
  /// log): "we'll keep this for next time", and nothing more is recorded.
  bool endedByServer = false;

  /// [endedByServer] because the family withdrew consent: lessons are
  /// paused, nothing is kept for next time.
  bool pausedByConsent = false;

  void _endedByServer() {
    if (_sessionId == null || _sessions.ended.value != _sessionId) return;
    endedByServer = true;
    pausedByConsent = _sessions.endedWhy == 'consent';
    notifyListeners();
  }

  /// The child chose to go home: the drawing is kept for next time.
  Future<void> leave() async {
    askingBreak = false;
    await _record(const [
      SpecEvent('session_paused', {'reason': 'child'}),
    ]);
  }

  Future<void> send(LessonInput input) async {
    final sessionId = _sessionId;
    // no session yet, no case yet (the starting sums, a left case on
    // offer), paused for the connection, or over: the board isn't live
    if (sessionId == null || _p == null || !online || endedByServer) return;
    if (_held != null) {
      // the child moved on before the decision: the rules' help shows
      if (input is QuietFor) return;
      unawaited(_settle(null)); // shown at once: nothing awaited
    }
    final r = step(_pack, _problem, _state, input);
    if (identical(r.state, _state) && r.decisions.isEmpty) return;
    final now = _now();
    final events = eventsFor(_problem, _state, input, r, (
      stepMs: now - _stepAt,
      problemMs: now - _shownAt,
      readingMs: (_startedAt ?? now) - _shownAt,
    ));
    if (input is Started) _startedAt = now;
    if (input is ShowMeHowTaken) showingExample = true;
    if (input is Undo) _signals.undos++;
    if (input is HintTaken || input is ShowMeHowTaken || input is EasierTaken) {
      _signals.helpOpened = true;
    }
    if (input is! QuietFor) {
      _lastMoveMs = now;
      glowPiece = showHand = stillThere = tooHard = false;
      if (helpAttention == Attention.pulse) helpAttention = Attention.none;
    }
    final entering = r.state.step != _state.step ? r.state.step : null;
    if (entering != null) _stepAt = now;
    final first = _seq;
    final asks = [
      if (askDecisions)
        for (final (i, e) in events.indexed)
          if (e.name == 'step_committed')
            afterStepDecision(
              problem: _problem,
              after: r.state,
              input: input,
              decisions: r.decisions,
              committed: e,
              seq: first + i,
              signals: _signals,
              maxSideLessons: _pack.maxSideLessons,
              prompts: {
                if (actOnDecisions && readAgainPrompt) 'read_again',
                if (actOnDecisions && seenBeforeBridge) 'seen_before',
              },
            ),
    ];
    if (entering != null) {
      _signals.reset();
      _wayOutOffered = false;
      easierSentence = false;
      _newStepHelp();
    }
    // a wrong step the server may help with differently: its help waits
    final wait = actOnDecisions ? asks.where(_judged).lastOrNull : null;
    _seq += events.length;
    final solved = r.decisions.any((d) => d is Solved);
    final reads = _heldReads = [];
    final held = _Held(r, input, entering);
    if (wait != null) {
      // the phone's check shows now: the wobble, Help me shaking
      _apply([
        for (final d in r.decisions)
          if (d is Wobble || d is ShakeHelp) d,
      ]);
      _held = held..fedBack = true;
    } else {
      _present(held);
    }
    // lines read aloud on this step follow its events, in this session
    _heldReads = null;
    if (_sessionId == sessionId) _seq += reads.length;
    // solved: the session ends as finished (SES-01), after this step's
    // events and reads; its seq taken now so a tick meanwhile can't take it.
    // With faces to rate, after the rating instead (AI-08).
    final ending = solved && _sessionId == sessionId;
    if (ending && offerRating) _rated = Completer();
    final endAt = ending && _rated == null ? _seq++ : null;
    notifyListeners();
    await _sessions.record(sessionId, first, [...events, ...reads]);
    for (final ask in asks) {
      unawaited(
        identical(ask, wait)
            ? _decideThenShow(sessionId, ask, held)
            : _askServer(sessionId, ask),
      );
    }
    if (ending && _rated != null) {
      unawaited(_endFinished(sessionId, null));
    } else if (endAt != null) {
      await _endFinished(sessionId, endAt);
    }
    // something easier: the easier problem gets its own session
    if (_sessionId == null) await start();
  }

  /// The engine's result for one input, shown: its state, its decisions,
  /// and the line for a step just entered.
  void _present(_Held h, {bool help = true}) {
    _state = h.r.state;
    _apply([
      for (final d in h.r.decisions)
        if ((help || d is! Coach && d is! OpenSideLesson) &&
            (!h.fedBack || d is! Wobble && d is! ShakeHelp))
          d,
    ]);
    // back from a side lesson opened on "check one part": that sheet again
    if (h.input is SideLessonDone && _state.knowFlow == KnowFlow.checkingPart) {
      knowPrompt = KnowPrompt.checkPart;
    }
    final stepLine = _stepLines[h.entering];
    if (stepLine != null && !h.r.decisions.any((d) => d is Coach)) {
      _coach(stepLine, const {});
    }
  }

  /// A wrong step the server judges, with more than carrying on allowed.
  static bool _judged(Map<String, Object?> ask) =>
      (ask['step'] as Map?)?['phoneVerdict'] == 'incorrect' &&
      (ask['allowed']! as List).length > 1;

  /// Asks the server about a held wrong step and shows its help: the
  /// thinking cue after [cueAfterMs]; the rules' help after
  /// [fallbackAfterMs], on an error, or when the rules decided there too.
  Future<void> _decideThenShow(
    String sessionId,
    Map<String, Object?> ask,
    _Held held,
  ) async {
    held.cue = Timer(Duration(milliseconds: cueAfterMs), () {
      if (!identical(_held, held) || _disposed) return;
      thinking = true;
      notifyListeners();
    });
    Map<String, Object?>? reply;
    try {
      reply = await _sessions
          .decide(sessionId, ask)
          .timeout(Duration(milliseconds: fallbackAfterMs));
      cueAfterMs = reply['cueAfterMs'] as int? ?? cueAfterMs;
      fallbackAfterMs = reply['fallbackAfterMs'] as int? ?? fallbackAfterMs;
    } on TimeoutException {
      debugPrint('decision: none in $fallbackAfterMs ms; the rules\' help');
    } on ApiException catch (e) {
      debugPrint('decision not asked: $e');
    }
    // the child moved on meanwhile: the rules' help already showed
    if (!identical(_held, held) || _disposed) return;
    await _settle(reply == null ? null : aiChoice(reply));
  }

  /// Shows the held step's help: the server's [ai] choice where it differs
  /// from the rules' and this app can show it, else the rules' own.
  Future<void> _settle(AiChoice? ai) async {
    final held = _held!;
    _held = null;
    held.cue?.cancel();
    thinking = false;
    final rules = held.r.decisions.any((d) => d is OpenSideLesson)
        ? 'side_lesson'
        : 'none';
    final help = ai?.help;
    // paused for the connection or ended: the engine takes no input now
    if (help == null ||
        help == rules ||
        !_canShow(help, held) ||
        !online ||
        endedByServer) {
      _present(held);
      notifyListeners();
      if (ai != null) _nextAction(ai.next);
      return;
    }
    // the server's help, not the rules': a side lesson the rules opened
    // closes unrun, and the rules' line isn't said
    _present(held, help: false);
    if (_state.step == LessonStep.sideLesson) {
      await send(const SideLessonDone(completed: false));
    }
    switch (help) {
      case 'hint':
        await send(const HintTaken(afterWrong: true));
      case 'show_me_how':
        await send(const ShowMeHowTaken(afterWrong: true));
      case 'easier':
        await send(const EasierTaken(afterWrong: true));
        return; // a new problem: nothing next on this one
      case 'side_lesson':
        await send(SideLessonChosen(_sideFor(ai!.sideSkill)));
      case 'check_again':
        _coach('cmp.recheck', const {});
      case 'read_again':
        // the question again, aloud, before any other help (AI-09)
        prompt = TutorPrompt.readAgain;
        _speak(_problem.say, 'question');
        await _record(const [
          SpecEvent('prompt_offered', {'kind': 'read_again'}),
        ]);
      case 'seen_before':
        final id = ai!.seenBefore?.problemId;
        seenCase = id == null || id == _problem.id ? null : _pack.problems[id];
        prompt = TutorPrompt.seenBefore;
        await _record([
          SpecEvent('prompt_offered', {
            'kind': 'seen_before',
            'linked_problem_id': ?seenCase?.id,
          }),
        ]);
      default: // none: only the step's own line
        _coach('cmp.tryAgain', const {});
    }
    notifyListeners();
    _nextAction(ai!.next);
  }

  /// Whether this app can show [help] for the held step.
  bool _canShow(String help, _Held held) => switch (help) {
    'side_lesson' =>
      held.r.state.step != LessonStep.sideLesson &&
          held.r.state.sideLessons < _pack.maxSideLessons &&
          const {
            LessonStep.findB,
            LessonStep.findTotal,
          }.contains(held.r.state.step),
    'read_again' => readAgainPrompt,
    'seen_before' => seenBeforeBridge,
    _ => helpActions.contains(help),
  };

  /// The side lesson for the server's skill; with none named, the one the
  /// step's sum needs.
  SideLesson _sideFor(String? skill) => switch (skill) {
    'arith.add-3d-regroup' => SideLesson.addWithCarry,
    'arith.sub-3d-regroup' => SideLesson.takeAcrossTen,
    _ =>
      _state.step == LessonStep.findB && _problem.big == BigSide.a
          ? SideLesson.takeAcrossTen
          : SideLesson.addWithCarry,
  };

  /// A decision's `next.action`, shown with what the lesson already has.
  /// The child chooses: nothing switches the case on its own.
  void _nextAction(String next) {
    if (!_onBoard) return;
    switch (next) {
      case 'same_level_new_numbers' || 'one_easier_then_back':
        // the way-out offer: Help me, something easier, still thinking
        tooHard = stillThere = _wayOutOffered = true;
      case 'end_case' || 'end_session':
        askingBreak = true;
      default: // continue; next_level moves at the end of the case (SKL-04)
        return;
    }
    notifyListeners();
  }

  /// Sends one decision and only logs the answer: the rules' choice
  /// already showed (a correct step, or `ai_decisions` off).
  Future<void> _askServer(String sessionId, Map<String, Object?> ask) async {
    try {
      final reply = await _sessions.decide(sessionId, ask);
      if (reply['action'] != ask['rulesDefault']) {
        debugPrint(
          'decision: the server chose ${reply['action']}, '
          'the rules ${ask['rulesDefault']} (kept)',
        );
      }
    } on ApiException catch (e) {
      debugPrint('decision not asked: $e');
    }
  }

  Voice get voice => _voice;

  /// The voice just stopped working: tell the child once (NoVoice).
  bool askVoiceResting = false;
  bool _toldVoiceResting = false;

  void _voiceResting() {
    if (!_voice.resting.value || _toldVoiceResting) return;
    _toldVoiceResting = askVoiceResting = true;
    notifyListeners();
  }

  /// NoVoice was shown.
  void toldVoiceResting() {
    askVoiceResting = false;
    notifyListeners();
  }

  /// The grown-up's "Read aloud" (Settings): when off, nothing is spoken
  /// unless the child taps a speak button.
  bool readAloud = true;

  /// The grown-up's "Bigger number pad" (Settings).
  bool biggerPad = false;

  /// Tapped "Hear it again": always spoken.
  void readQuestion() {
    _signals.readAloudUsed = true;
    _speak(_problem.say, 'question');
  }

  /// The flag `read_question_aloud`: the question speaks itself as it shows.
  bool readQuestionAloud = true;

  /// The flag `mastery_badges`: the badge after "case cracked".
  bool showBadges = true;

  /// The flag `self_rating` and the child's age (AI-08): three faces after
  /// a solved case from `self_rating_min_age` (7) up, never younger. The
  /// rating is only logged: it changes no level, score or next case.
  bool selfRating = false;
  int selfRatingMinAge = 7;
  int? childAge;
  bool get offerRating =>
      selfRating && childAge != null && childAge! >= selfRatingMinAge;

  /// The face the child tapped for this case: `easy`, `ok` or `tricky`.
  String? rating;

  /// Set while the faces wait: the session ends once they're answered.
  Completer<void>? _rated;

  /// A face tapped: `self_rating_given`, then the session can end.
  Future<void> rate(String face) async {
    if (rating != null) return;
    rating = face;
    notifyListeners();
    await _record([
      SpecEvent('self_rating_given', {
        'problem_id': _problem.id,
        'rating': face,
      }),
    ]);
    _doneRating();
  }

  /// Next without a face: no rating, and the session ends.
  void _doneRating() {
    final rated = _rated;
    if (rated != null && !rated.isCompleted) rated.complete();
  }

  void skipRating() => _doneRating();

  /// Why the lesson opened (`session_started`, DAT-05): the child on their
  /// own phone, or a grown-up's phone handed over.
  String launchSource = 'child_opened';

  /// The question as it first shows: spoken if read-aloud is on.
  void autoReadQuestion() {
    if (readAloud && readQuestionAloud) _speak(_problem.say, 'question');
  }

  /// A line the child asked to hear (a speak button). [target] is what
  /// `read_aloud_played` says was read: the question, else a helping line.
  void say(String text, {String target = 'hint'}) {
    _signals.readAloudUsed = true;
    _speak(text, target);
  }

  /// A line a screen shows on its own (the board's steps, the example):
  /// spoken if read-aloud is on.
  void autoSay(String text, {String target = 'hint'}) {
    if (readAloud) _speak(text, target);
  }

  /// Set while [send] works out a step: lines read then are saved after
  /// its events, so the seqs stay in order.
  List<SpecEvent>? _heldReads;

  /// Reads [text] aloud and logs `read_aloud_played` (NFR-08): its target
  /// only, never the words, so no name or child text is in the log.
  void _speak(String text, String target) {
    _voice.say(text);
    // nothing to hear: an empty line, or the phone's voice isn't working
    if (text.isEmpty || _voice.resting.value) return;
    final played = SpecEvent('read_aloud_played', {'target': target});
    final held = _heldReads;
    if (held != null) {
      held.add(played);
    } else {
      unawaited(_record([played]));
    }
  }

  /// The sum the side lesson works through: the one the child was on.
  /// Finding B subtracts the gap when A is bigger, else adds it; the
  /// total adds A and B.
  ({int left, int right, bool subtract}) get sideSum {
    final p = _problem;
    if (_state.returnStep == LessonStep.findTotal) {
      return (left: p.aValue, right: p.bValue, subtract: false);
    }
    return (left: p.aValue, right: p.diff, subtract: p.big == BigSide.a);
  }

  /// The sum step's number sentence shows each number's name under it,
  /// beside the bars (TUT-09). Until the step changes.
  bool easierSentence = false;

  /// Help me's "Show the sum in words": on the sum steps only.
  bool get canEaseSentence =>
      _p != null &&
      const {LessonStep.findB, LessonStep.findTotal}.contains(_state.step);

  void showEasierSentence() {
    if (easierSentence || !canEaseSentence) return;
    easierSentence = true;
    notifyListeners();
    unawaited(
      _record([
        SpecEvent('easier_number_sentence_shown', {
          'step_id': specStepId(_state.step),
        }),
      ]),
    );
  }

  /// The flag `child_questions` (TUT-13): tap-to-ask buttons on the board.
  bool childQuestions = false;

  /// The current step's question buttons (policy `question_buttons`), the
  /// step's own first, then every step's; at most three. Each answer is
  /// Julia's library line: it never gives the step's answer away.
  List<({String id, String question, String answer})> get questions {
    if (!childQuestions || !_onBoard || _p == null) return const [];
    final buttons = _pack.questionButtons;
    final slots = {...lineSlots(_problem), 'kind': _kind};
    return [
      for (final id in [...?buttons[specStepId(_state.step)], ...?buttons['*']])
        // "What does taller mean? | Taller means ..."
        if (_pack.policyLines[id]?.split(' | ') case [final q, final a])
          (id: id, question: fillLine(q, slots), answer: fillLine(a, slots)),
    ].take(3).toList();
  }

  /// The thing both are, for a line's `{kind}`: "tree" for the lemon tree
  /// and the fig tree, else "one".
  String get _kind {
    final a = _problem.a.name.toLowerCase().split(' ').last;
    return a == _problem.b.name.toLowerCase().split(' ').last ? a : 'one';
  }

  /// A question button tapped: its answer is the coach's line, read aloud
  /// if read-aloud is on, and `question_chip_tapped` is logged.
  void ask(({String id, String question, String answer}) q) {
    coachText = q.answer;
    autoSay(q.answer);
    notifyListeners();
    unawaited(
      _record([
        SpecEvent('question_chip_tapped', {
          'chip_id': q.id,
          'step_id': ?specStepId(_state.step),
          'line_id': q.id,
        }),
      ]),
    );
  }

  /// The child, for the practice sums' `/arithmetic` (set by the route).
  String? childId;

  /// After the walk-through the child types its sum. Wrong: [practice]
  /// smaller sums of the same kind (policy `practice_if_unsure`, TUT-08),
  /// then back to the case.
  SideStage sideStage = SideStage.ownSum;
  bool ownSumRight = false;
  List<Sum> practice = const [];
  int practiceAt = 0;
  int practiceRight = 0;
  int _itemAt = 0;

  /// Every practice sum was wrong: a kind ending, then back (TUT-18).
  bool get practiceAllWrong => practice.isNotEmpty && practiceRight == 0;

  /// Practice sums answered wrong in this side lesson.
  int get practiceWrong => practiceAt - practiceRight;

  /// The side lesson can't be finished (TUT-18): policy
  /// `abandon_after_wrong_practice` sums wrong, or every one there was.
  /// It ends kindly, logs `completed: false`, and the step it paused shows
  /// its first hint.
  bool get sideAbandoned =>
      practice.isNotEmpty &&
      (practiceWrong >= _pack.abandonAfterWrongPractice ||
          practiceAt == practice.length && practiceRight == 0);

  /// "Back to the problem" from a side lesson: finished, or not (TUT-18).
  Future<void> endSideLesson() => send(
    sideAbandoned ? const SideLessonAbandoned() : const SideLessonDone(),
  );

  Future<void> checkOwnSum(int value) async {
    final s = sideSum;
    ownSumRight = value == (s.subtract ? s.left - s.right : s.left + s.right);
    final id = childId;
    if (!ownSumRight && id != null) {
      try {
        practice = (await _sessions.practiceSums(
          id,
          level: practiceLevel(s),
        )).take(_pack.practiceSums).toList();
      } on ApiException catch (e) {
        // no sums to practise: the answer, then back to the case
        debugPrint('practice sums not fetched: $e');
      }
    }
    sideStage = practice.isEmpty ? SideStage.back : SideStage.practice;
    _itemAt = _now();
    notifyListeners();
  }

  /// One practice sum typed: logged as `quick_sum_answered` (context
  /// `side_lesson`).
  Future<void> answerPractice(int value) async {
    final item = practice[practiceAt];
    final correct = value == item.answer;
    if (correct) practiceRight++;
    final now = _now();
    final at = practiceAt++;
    if (practiceAt == practice.length || sideAbandoned) {
      sideStage = SideStage.back;
    }
    notifyListeners();
    await _record([
      SpecEvent('quick_sum_answered', {
        'context': 'side_lesson',
        'item_id': 'practice-${at + 1}',
        'level': item.level,
        'value': value,
        'correct': correct,
        'ms_from_item_start': now - _itemAt,
      }),
    ]);
    _itemAt = now;
  }

  void sayAgain() {
    _signals.readAloudUsed = true;
    _speak(coachText, 'hint');
  }

  void dismissStillThere() {
    stillThere = tooHard = false;
    notifyListeners();
  }

  /// The hint rung shown last on this step (TUT-04); null on a new step.
  HintRung? hintRung;
  bool _itAnswered = false;

  /// Wrong picks on "Which tree does 'it' mean?", for the buttons' wobble.
  int itWrongPicks = 0;

  /// H1-4a or H1-4b is asking which thing "it" means (TUT-16), and the
  /// child hasn't picked the right one yet.
  bool get asksWhichIt {
    final r = hintRung;
    if (r == null ||
        _itAnswered ||
        _state.step != LessonStep.sizeB && _state.step != LessonStep.placeB) {
      return false;
    }
    return r.choice.contains('a') && r.choice.contains('b') ||
        r.highlight != null;
  }

  /// H1-4b: "it" and the thing it means in one colour, underlined. Shown
  /// only after a request for help, and never on the next problem.
  bool get highlightIt => hintRung?.highlight != null;

  /// The child's pick on "Which tree does 'it' mean?". A wrong one
  /// wobbles and leads to the highlight; it is logged, not charged.
  Future<void> pickIt(String option) async {
    if (option == 'a') {
      _itAnswered = true;
    } else {
      itWrongPicks++;
    }
    await send(ItPicked(option));
  }

  void _newStepHelp() {
    hintRung = null;
    _itAnswered = false;
  }

  /// The quiet child's "Want a hand?" (policy `quiet.still_there_line`,
  /// TUT-07); null without one, and the sheet says its own.
  String? get stillThereLine => switch (_pack.quietLines.still) {
    final id? when _p != null => _lineText(id, const {}),
    _ => null,
  };

  /// "I'm still thinking" on the quiet child's sheet: it closes, and the
  /// step's first hint follows (policy `quiet.then: first_hint`, TUT-07).
  /// On the too-hard sheet (TUT-10) it only closes.
  Future<void> stillThinking() async {
    final quiet = stillThere && !tooHard;
    dismissStillThere();
    if (quiet) await send(const HintTaken(afterQuiet: true));
  }

  /// Opens the sheet that matches where an "I know it" answer is up to, so a
  /// dismissed "check one part" reopens as itself.
  void openKnowIt() {
    knowPrompt = switch (_state.knowFlow) {
      KnowFlow.askingWhat => KnowPrompt.whatAsked,
      KnowFlow.checkingPart => KnowPrompt.checkPart,
      KnowFlow.checkingTotal => KnowPrompt.checkTotal,
      KnowFlow.none => KnowPrompt.answer,
    };
    notifyListeners();
  }

  void closeKnowIt() {
    knowPrompt = null;
    notifyListeners();
  }

  /// A number typed in an "I know it" sheet, routed by where that flow is.
  Future<void> answer(int value) => send(switch (_state.knowFlow) {
    KnowFlow.checkingPart => PartChecked(value),
    KnowFlow.checkingTotal => KnowTotalChecked(value),
    _ => KnowIt(value),
  });

  /// Starts the next problem the engine chose; with the server's problems,
  /// one a level easier than this one, from the server.
  void goTo(String problemId, {bool sameLevel = false}) {
    if (_nextProblem != null) {
      _askLevel = sameLevel ? _problem.level : easierLevel(_problem.level);
      _p = null;
    } else {
      _p = _pack.problems[problemId]!;
    }
    _sessionId = null; // the next start() asks the server for one
    _state = initialState();
    _seq = 0;
    _lastMoveMs = _shownAt = _stepAt = _now();
    _startedAt = null;
    coachText = '';
    helpAttention = Attention.none;
    glowPiece = showHand = stillThere = false;
    knowPrompt = sideLesson = badgeId = nextProblemId = null;
    prompt = null;
    seenCase = null;
    easierSentence = false;
    rating = null;
    _newStepHelp(); // the next problem opens with no highlight (TUT-16)
    notifyListeners();
  }

  /// Solved: `session_ended {finished}`, so the server writes the note and
  /// moves the level now rather than at the idle sweep. After the next case
  /// is fetched: problems/next refuses an ended session (409).
  Future<void> _endFinished(String sessionId, int? seq) async {
    await _fetching;
    await _rated?.future;
    if (endedByServer) return;
    await _sessions.record(sessionId, seq ?? _seq++, [
      SpecEvent('session_ended', {
        'reason': 'finished',
        'active_ms': _sitting.activeMs,
      }),
    ]);
  }

  Future<void>? _fetching;

  /// Solved, with the server's problems: the next case is asked for now,
  /// in this session, while "case cracked" shows. Unreachable, it is
  /// [newProblem]: the next lesson asks again.
  Future<void> _fetchNext() async {
    try {
      nextProblemId = (await _nextProblem!(_sessionId!)).id;
    } on ApiException catch (e) {
      debugPrint('next problem not fetched: $e');
      nextProblemId = newProblem;
    }
    notifyListeners();
  }

  void _apply(List<Decision> decisions) {
    for (final d in decisions) {
      switch (d) {
        case Coach(:final lineId, :final slots):
          _coach(lineId, slots);
        case ShowHint(:final lineId, :final rung):
          _coach(lineId, const {});
          hintRung = rung ?? hintRung;
        case Wobble():
          wobbles++;
        case ShakeHelp():
          helpAttention = Attention.shake;
        case PulseHelp():
          helpAttention = Attention.pulse;
        case GlowPiece():
          glowPiece = true;
        case ShowHand():
          showHand = true;
        case AskStillThere():
          stillThere = true;
        case OpenSideLesson(:final kind):
          sideLesson = kind;
          knowPrompt = null;
          sideStage = SideStage.ownSum;
          ownSumRight = false;
          practice = const [];
          practiceAt = practiceRight = 0;
        case AskWhatQuestionAsks():
          knowPrompt = KnowPrompt.whatAsked;
        case OpenRecheck():
          knowPrompt = KnowPrompt.recheck;
        case CheckOnePart():
          knowPrompt = KnowPrompt.checkPart;
        case DrawIt():
          knowPrompt = null;
        case SuggestShowMeHow():
          _coach('cmp.showMeHow', const {});
        case SwitchProblem(:final problemId):
          goTo(problemId);
        case NextVariant(:final problemId):
          goTo(problemId, sameLevel: true);
        case Solved(:final badgeId, nextProblemId: final next):
          knowPrompt = null;
          this.badgeId = badgeId;
          if (_nextProblem == null) {
            nextProblemId = next;
          } else {
            _fetching = _fetchNext();
          }
      }
    }
    if (_state.knowFlow == KnowFlow.checkingTotal) {
      knowPrompt = KnowPrompt.checkTotal;
    }
  }

  /// The lines this problem may read, made ahead in the case partner's
  /// voice so they play at once. A line still missing a slot is skipped.
  void _warmVoice() {
    final slots = lineSlots(_problem);
    unawaited(
      _voice.warm([
        _problem.say,
        if (readAloud)
          for (final line in _pack.lines.values)
            if (fillLine(line, slots) case final text when !text.contains('{'))
              text,
      ]),
    );
  }

  void _coach(String lineId, Map<String, String> slots) {
    // the line's next version: never the same one twice in a row (TUT-14)
    coachText = lines.next(lineId, _problem, slots);
    autoSay(coachText);
  }

  /// Every line's words: Julia's library first (TUT-11).
  late final LineLibrary lines = LineLibrary(_pack);

  /// A line's text for this problem, from the library ([lines]).
  String _lineText(String lineId, Map<String, String> slots) =>
      lines.line(lineId, _problem, slots);

  /// The finish screen's praise (TUT-12): "You solved the Tree Word
  /// Problem!" (`line.praise.solved`), else the short one; null without
  /// either, and the screen keeps its own.
  String? get praise =>
      libraryLine('line.praise.solved') ??
      libraryLine('line.praise.solved-short');

  /// Julia's library line [id] for this problem, or null when the library
  /// doesn't hold it (the screen keeps its own words).
  String? libraryLine(String id) =>
      _p != null && lines.fromLibrary(id) ? _lineText(id, const {}) : null;

  /// Help me offers a hint on this step: false on a step with no rung on
  /// the policy ladder (TUT-04), where it offers show me how and easier.
  bool get canHint => _p == null || hasHint(_pack, _state.step);

  /// The line said on entering a board step, unless the engine said one.
  /// Prototype: STEPLINE.
  static const _stepLines = {
    LessonStep.drawA: 'cmp.drawA',
    LessonStep.placeB: 'cmp.placeB',
    LessonStep.sizeB: 'cmp.sizeB',
    LessonStep.placeGap: 'cmp.placeGap',
    LessonStep.placeTotal: 'cmp.placeTotal',
    LessonStep.chooseOp: 'cmp.chooseOp',
    LessonStep.findB: 'cmp.findB',
    LessonStep.findTotal: 'cmp.findTotal',
  };

  @override
  void dispose() {
    _disposed = true;
    _held?.cue?.cancel();
    _doneRating();
    _sessions.online.removeListener(_onlineChanged);
    _sessions.ended.removeListener(_endedByServer);
    _voice.resting.removeListener(_voiceResting);
    _ticker?.cancel();
    unawaited(_sitting.save());
    _voice.stop();
    super.dispose();
  }
}

/// One level down the ladder (`L4` → `L3`), never below `L1`; null leaves
/// it to the server.
String? easierLevel(String? level) {
  final n = int.tryParse(level?.substring(1) ?? '');
  return n == null ? null : 'L${n > 1 ? n - 1 : 1}';
}

/// One input's engine result whose help waits for the server's decision.
class _Held {
  _Held(this.r, this.input, this.entering);

  final StepResult r;
  final LessonInput input;
  final LessonStep? entering;
  Timer? cue;

  /// The wobble and Help me's shake already showed, while it waited.
  bool fedBack = false;
}
