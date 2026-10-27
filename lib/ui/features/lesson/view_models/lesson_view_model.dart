import 'dart:async';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/session_repository.dart';
import '../../../../data/services/voice.dart';
import '../../../core/parts/standing_button.dart';

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
    required this._sessionId,
    required this._sessions,
    required this._voice,
    required this._newSessionId,
    int Function()? nowMs,
    Duration? tickEvery = const Duration(seconds: 1),
  }) : _pack = pack,
       _problem = pack.problems[problemId]!,
       _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch) {
    _lastMoveMs = _now();
    if (tickEvery != null) _ticker = Timer.periodic(tickEvery, (_) => tick());
  }

  final Pack _pack;
  final SessionRepository _sessions;
  final Voice _voice;
  final String Function() _newSessionId;
  final int Function() _now;
  Timer? _ticker;

  ComparisonProblem _problem;
  String _sessionId;
  LessonState _state = initialState();
  int _seq = 0;
  late int _lastMoveMs;

  ComparisonProblem get problem => _problem;
  String get sessionId => _sessionId;
  LessonState get state => _state;
  Pack get pack => _pack;

  /// Events saved for the current session.
  int get recorded => _seq;

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

  Future<void> restore() async {
    final inputs = await _sessions.resume(_sessionId);
    _state = replay(_pack, _problem, inputs);
    _seq = inputs.length;
    notifyListeners();
  }

  /// Sends a quiet-child tick; the engine decides whether it matters.
  Future<void> tick() => send(QuietFor(_now() - _lastMoveMs));

  Future<void> send(LessonInput input) async {
    final r = step(_pack, _problem, _state, input);
    if (identical(r.state, _state) && r.decisions.isEmpty) return;
    if (input is! QuietFor) {
      _lastMoveMs = _now();
      glowPiece = showHand = stillThere = false;
      if (helpAttention == Attention.pulse) helpAttention = Attention.none;
    }
    final entering = r.state.step != _state.step ? r.state.step : null;
    _state = r.state;
    final seq = ++_seq;
    final sessionId = _sessionId, problemId = _problem.id;
    _apply(r.decisions);
    if (entering == LessonStep.drawA && !r.decisions.any((d) => d is Coach)) {
      _coach('cmp.drawA', const {});
    }
    notifyListeners();
    await _sessions.record(sessionId, seq, _pack.version, problemId, input);
  }

  void readQuestion() => _voice.say(_problem.say);

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
    _sessionId = _newSessionId();
    _state = initialState();
    _seq = 0;
    _lastMoveMs = _now();
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
    final all = {..._slots(), ...slots};
    coachText = fillLine(_pack.lines[lineId] ?? '', all);
    _voice.say(coachText);
  }

  Map<String, String> _slots() => {
    'a': _problem.a.name.toLowerCase(),
    'b': _problem.b.name.toLowerCase(),
    'B': _problem.b.name,
    'av': '${_problem.aValue}',
    'd': '${_problem.diff}',
    'u': _problem.unit,
  };

  @override
  void dispose() {
    _ticker?.cancel();
    _voice.stop();
    super.dispose();
  }
}
