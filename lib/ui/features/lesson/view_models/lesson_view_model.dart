import 'dart:async';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/session_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../data/services/voice.dart';
import '../../../core/parts/standing_button.dart';
import 'sitting.dart';
import 'step_decision.dart';

/// Which answer sheet is open during "I know it".
enum KnowPrompt { answer, whatAsked, recheck, checkPart, checkTotal }

/// Where a side lesson is once its blocks are worked: the child types the
/// sum, practises a few if it was wrong, then goes back.
enum SideStage { ownSum, practice, back }

/// Replaces each `{key}` in a pack line with its slot value.
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
    if (again) _p = offerLeft;
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
        // a case left last time: offered back first (SES-06)
        final left = _sessions.leftProblem(_pack, sessionId);
        if (left != null) {
          offerLeft = left;
          notifyListeners();
          return;
        }
        _p = await next(sessionId, level: _askLevel);
        _askLevel = null;
      }
    } on ApiException catch (e) {
      startError = e;
      notifyListeners();
      return;
    }
    notifyListeners();
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

  /// Rebuilds the lesson from its saved events: replayed through the engine,
  /// never from a snapshot.
  Future<void> restore() async {
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
    if (_pausedAt == null) _sitting.activeMs += now - _lastTickMs;
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

  void _endedByServer() {
    if (_sessionId == null || _sessions.ended.value != _sessionId) return;
    endedByServer = true;
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
    // no session yet, paused for the connection, or over: the board isn't
    // live
    if (sessionId == null || !online || endedByServer) return;
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
            ),
    ];
    if (entering != null) {
      _signals.reset();
      _wayOutOffered = false;
    }
    _state = r.state;
    _seq += events.length;
    _apply(r.decisions);
    // back from a side lesson opened on "check one part": that sheet again
    if (input is SideLessonDone && _state.knowFlow == KnowFlow.checkingPart) {
      knowPrompt = KnowPrompt.checkPart;
    }
    final stepLine = _stepLines[entering];
    if (stepLine != null && !r.decisions.any((d) => d is Coach)) {
      _coach(stepLine, const {});
    }
    notifyListeners();
    await _sessions.record(sessionId, first, events);
    for (final ask in asks) {
      unawaited(_askServer(sessionId, ask));
    }
    // something easier: the easier problem gets its own session
    if (_sessionId == null) await start();
  }

  /// Sends one decision. The rules' choice already happened on the phone.
  // ponytail: the server's answer isn't acted on: with the AI off (dev,
  // R1) it is our own default anyway, and nothing waits for it, so there's
  // no thinking cue yet. Acting on a different answer needs an event that
  // a resume can replay; add it, the 1 s cue and the 4 s fallback when the
  // evaluator is switched on (M3).
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
    _voice.say(_problem.say);
  }

  /// The flag `read_question_aloud`: the question speaks itself as it shows.
  bool readQuestionAloud = true;

  /// The flag `mastery_badges`: the badge after "case cracked".
  bool showBadges = true;

  /// Why the lesson opened (`session_started`, DAT-05): the child on their
  /// own phone, or a grown-up's phone handed over.
  String launchSource = 'child_opened';

  /// The question as it first shows: spoken if read-aloud is on.
  void autoReadQuestion() {
    if (readAloud && readQuestionAloud) _voice.say(_problem.say);
  }

  /// A line the child asked to hear (a speak button).
  void say(String text) {
    _signals.readAloudUsed = true;
    _voice.say(text);
  }

  /// A line a screen shows on its own (the board's steps, the example):
  /// spoken if read-aloud is on.
  void autoSay(String text) {
    if (readAloud) _voice.say(text);
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

  /// The child, for the practice sums' `/arithmetic` (set by the route).
  String? childId;

  /// After the walk-through the child types its sum. Wrong: [practice]
  /// smaller sums of the same kind (policy `practice_if_unsure`, TUT-08),
  /// then back to the case.
  SideStage sideStage = SideStage.ownSum;
  bool ownSumRight = false;
  List<({String text, int answer, String level})> practice = const [];
  int practiceAt = 0;
  int practiceRight = 0;
  int _itemAt = 0;

  /// Every practice sum was wrong: a kind ending, then back (TUT-18).
  bool get practiceAllWrong => practice.isNotEmpty && practiceRight == 0;

  Future<void> checkOwnSum(int value) async {
    final s = sideSum;
    ownSumRight = value == (s.subtract ? s.left - s.right : s.left + s.right);
    final id = childId;
    if (!ownSumRight && id != null) {
      try {
        practice = (await _sessions.practiceSums(
          id,
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
    if (practiceAt == practice.length) sideStage = SideStage.back;
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
    _voice.say(coachText);
  }

  void dismissStillThere() {
    stillThere = tooHard = false;
    notifyListeners();
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
  void goTo(String problemId) {
    if (_nextProblem != null) {
      _askLevel = easierLevel(_problem.level);
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
    notifyListeners();
  }

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
        case ShowHint(:final lineId):
          _coach(lineId, const {});
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
        case Solved(:final badgeId, nextProblemId: final next):
          knowPrompt = null;
          this.badgeId = badgeId;
          if (_nextProblem == null) {
            nextProblemId = next;
          } else {
            _fetchNext();
          }
      }
    }
    if (_state.knowFlow == KnowFlow.checkingTotal) {
      knowPrompt = KnowPrompt.checkTotal;
    }
  }

  void _coach(String lineId, Map<String, String> slots) {
    // Every Coach carries the problem's own slots; hints and fallbacks don't.
    final all = {...lineSlots(_problem), ...slots};
    coachText = fillLine(_pack.lines[lineId] ?? '', all);
    autoSay(coachText);
  }

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
