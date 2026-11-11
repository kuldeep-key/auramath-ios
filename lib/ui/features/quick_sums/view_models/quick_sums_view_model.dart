import 'dart:async';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/session_repository.dart';
import '../../../../data/services/api.dart';

/// Where a Quick sums answer is up to.
enum QuickStage { loading, sum, secondTry, done }

/// Quick sums (LES-16): a run of five sums from the server's arithmetic
/// generator at the child's level, typed on the keypad, in a session of
/// their own. A wrong answer wobbles and gets one more try; a regrouping
/// slip says where to look first. No score, timer or count is shown.
/// Every answer and its time are logged as `quick_sum_answered`.
class QuickSumsViewModel extends ChangeNotifier {
  QuickSumsViewModel({
    required this._sessions,
    required this.childId,
    this.launchSource = 'child_opened',
    this.chosenToday,
    int Function()? nowMs,
  }) : _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SessionRepository _sessions;
  final String? childId;
  final String launchSource;

  /// How the child got here from Choose today (LES-14): logged first, as
  /// `choice_selected` and `prompt_answered`, with its time on A3.
  final ({String optionId, int ms})? chosenToday;
  final int Function() _now;

  /// How many sums a run has (LES-16).
  static const runLength = 5;

  QuickStage stage = QuickStage.loading;
  List<Sum> sums = const [];
  int at = 0;

  /// Goes up on each wrong answer: the answer box wobbles.
  int wobbles = 0;

  /// The last wrong answer was a regrouping slip (a carry dropped, or the
  /// smaller digit taken from the larger).
  bool regroupSlip = false;

  /// Couldn't start: no connection, or the server said no.
  ApiException? startError;

  String? _sessionId;
  int _seq = 0;
  int _itemAt = 0;
  int _startedAt = 0;

  Sum get sum => sums[at];

  Future<void> start() async {
    startError = null;
    stage = QuickStage.loading;
    notifyListeners();
    try {
      _sessionId ??= await _sessions.open(childId: childId);
      if (_seq == 0) {
        _startedAt = _now();
        await _record([
          SpecEvent('session_started', {
            'launch_source': launchSource,
            'content_versions': _sessions.identity.contentVersions,
            'is_demo': _sessions.identity.isDemo,
          }),
          if (chosenToday case final c?) ...[
            SpecEvent('choice_selected', {
              'step_id': 'choose_today',
              'option_id': c.optionId,
              'ms_from_step_start': c.ms,
            }),
            SpecEvent('prompt_answered', {
              'prompt': 'choose_today',
              'choice': c.optionId,
            }),
          ],
        ]);
      }
      sums = (await _sessions.quickSums(
        childId ?? '',
      )).take(runLength).toList();
    } on ApiException catch (e) {
      startError = e;
      notifyListeners();
      return;
    }
    at = 0;
    stage = sums.isEmpty ? QuickStage.done : QuickStage.sum;
    _itemAt = _now();
    notifyListeners();
    if (sums.isEmpty) await _end();
  }

  /// One answer typed: right, the next sum; wrong, one more try; wrong
  /// again, on to the next.
  Future<void> answer(int value) async {
    if (stage != QuickStage.sum && stage != QuickStage.secondTry) return;
    final s = sum;
    final correct = value == s.answer;
    final attempt = stage == QuickStage.secondTry ? 2 : 1;
    final now = _now();
    final saving = _record([
      SpecEvent('quick_sum_answered', {
        'context': 'quick_sums',
        'item_id': 'quick-${at + 1}',
        'level': s.level,
        'value': value,
        'correct': correct,
        'attempt': attempt,
        'ms_from_item_start': now - _itemAt,
      }),
    ]);
    if (!correct && attempt == 1) {
      wobbles++;
      regroupSlip = isRegroupSlip(s.text, value);
      stage = QuickStage.secondTry;
      notifyListeners();
      return saving;
    }
    regroupSlip = false;
    at++;
    _itemAt = now;
    stage = at < sums.length ? QuickStage.sum : QuickStage.done;
    notifyListeners();
    await saving;
    if (stage == QuickStage.done) await _end();
  }

  Future<void> _end() => _record([
    SpecEvent('session_ended', {
      'reason': 'finished',
      'active_ms': _now() - _startedAt,
    }),
  ]);

  /// Leaving part way: the run is over (no case to keep).
  Future<void> leave() async {
    if (_sessionId == null || stage == QuickStage.done) return;
    stage = QuickStage.done;
    await _end();
  }

  Future<void> _record(List<SpecEvent> events) async {
    final id = _sessionId;
    if (id == null) return;
    final first = _seq;
    _seq += events.length;
    await _sessions.record(id, first, events);
  }
}

/// [value] for the sum in [text] ("56 - 19 = ?") is the regrouping slip:
/// the carry dropped when adding, or each column's smaller digit taken
/// from its larger when taking away (the same rules as the lesson's).
bool isRegroupSlip(String text, int value) {
  final m = RegExp(r'(\d+)\s*([+\-−])\s*(\d+)').firstMatch(text);
  if (m == null) return false;
  final a = int.parse(m[1]!), b = int.parse(m[3]!);
  return m[2] == '+' ? value == dropCarry(a, b) : value == noBorrow(a, b);
}
