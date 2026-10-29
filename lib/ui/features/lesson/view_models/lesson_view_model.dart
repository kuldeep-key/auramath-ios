import 'dart:async';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/session_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../data/services/voice.dart';
import '../../../core/parts/standing_button.dart';
import 'sitting.dart';

/// Which answer sheet is open during "I know it".
enum KnowPrompt { answer, whatAsked, recheck, checkPart, checkTotal }

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
    int Function()? nowMs,
    Duration? tickEvery = const Duration(seconds: 1),
  }) : _pack = pack,
       _problem = pack.problems[problemId]!,
       _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch) {
    _lastMoveMs = _shownAt = _stepAt = _lastTickMs = _now();
    if (tickEvery != null) _ticker = Timer.periodic(tickEvery, (_) => tick());
    _sessions.online.addListener(_onlineChanged);
  }

  final Pack _pack;
  final Sitting _sitting;
  final SessionRepository _sessions;
  final Voice _voice;

  /// Asks the server for a new session (online-first).
  final Future<String> Function() _openSession;
  final int Function() _now;
  Timer? _ticker;

  ComparisonProblem _problem;

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

  /// The server opened this lesson's session; until then nothing is drawn.
  bool get ready => _sessionId != null;

  /// The session couldn't be opened: no connection, or the server said no.
  /// The lesson waits on a "need the internet" screen with Try again.
  ApiException? startError;
  LessonState get state => _state;
  Pack get pack => _pack;
  SessionRepository get sessions => _sessions;

  /// Events saved for the current session.
  int get recorded => _seq;

  /// Opens a new session on this problem: `session_started`, `problem_shown`.
  Future<void> start() async {
    startError = null;
    if (_sessionId == null) {
      try {
        _sessionId = await _openSession();
      } on ApiException catch (e) {
        startError = e;
        notifyListeners();
        return;
      }
      notifyListeners();
    }
    final events = [
      SpecEvent('session_started', {
        'launch_source': 'child_opened',
        'content_versions': {
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
    if (sessionId == null) return; // nothing happened yet to record
    final first = _seq;
    _seq += events.length;
    await _sessions.record(sessionId, first, events);
  }

  String coachText = '';
  Attention helpAttention = Attention.none;
  bool glowPiece = false;
  bool showHand = false;
  bool stillThere = false;
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
    await send(QuietFor(now - _lastMoveMs));
  }

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

  /// The child chose to go home: the drawing is kept for next time.
  Future<void> leave() async {
    askingBreak = false;
    await _record(const [
      SpecEvent('session_paused', {'reason': 'child'}),
    ]);
  }

  Future<void> send(LessonInput input) async {
    final sessionId = _sessionId;
    // no session yet, or paused for the connection: the board isn't live
    if (sessionId == null || !online) return;
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
    if (input is! QuietFor) {
      _lastMoveMs = now;
      glowPiece = showHand = stillThere = false;
      if (helpAttention == Attention.pulse) helpAttention = Attention.none;
    }
    final entering = r.state.step != _state.step ? r.state.step : null;
    if (entering != null) _stepAt = now;
    _state = r.state;
    final first = _seq;
    _seq += events.length;
    _apply(r.decisions);
    final stepLine = _stepLines[entering];
    if (stepLine != null && !r.decisions.any((d) => d is Coach)) {
      _coach(stepLine, const {});
    }
    notifyListeners();
    await _sessions.record(sessionId, first, events);
    // something easier: the easier problem gets its own session
    if (_sessionId == null) await start();
  }

  /// The grown-up's "Read aloud" (Settings): when off, nothing is spoken
  /// unless the child taps a speak button.
  bool readAloud = true;

  /// The grown-up's "Bigger number pad" (Settings).
  bool biggerPad = false;

  /// Tapped "Hear it again": always spoken.
  void readQuestion() => _voice.say(_problem.say);

  /// The question as it first shows: spoken if read-aloud is on.
  void autoReadQuestion() {
    if (readAloud) _voice.say(_problem.say);
  }

  /// A line the child asked to hear (a speak button).
  void say(String text) => _voice.say(text);

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

  void sayAgain() => _voice.say(coachText);

  void dismissStillThere() {
    stillThere = false;
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

  /// Starts the next problem the engine chose.
  void goTo(String problemId) {
    _problem = _pack.problems[problemId]!;
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
          nextProblemId = next;
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
    _ticker?.cancel();
    _voice.stop();
    super.dispose();
  }
}
