import 'dart:async';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/session_repository.dart';
import '../../../../data/services/api.dart';

/// Where a Quick sums answer is up to.
enum QuickStage { loading, sum, sideLesson, secondTry, done }

/// Quick sums (LES-16): a run of five sums from the server's arithmetic
/// generator at the child's level, typed on the keypad, in a session of
/// their own. A wrong answer wobbles and gets one more try; a regrouping
/// slip opens the regrouping side lesson first, by the lesson's rule
/// (policy `side_lessons.trigger`: regrouping slips are immediate, at most
/// `max_per_session`), then the one more try. No score, timer or count is
/// shown. Every answer and its time are logged as `quick_sum_answered`.
class QuickSumsViewModel extends ChangeNotifier {
  QuickSumsViewModel({
    required this._sessions,
    required this.childId,
    this.launchSource = 'child_opened',
    this.chosenToday,
    this.maxSideLessons = 2,
    int Function()? nowMs,
  }) : _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Policy `side_lessons.max_per_session`: past it, a regrouping slip
  /// only says where to look.
  final int maxSideLessons;
  int _sideLessons = 0;

  /// The sum the side lesson works on blocks: the slipped one.
  ({int left, int right, bool subtract})? side;

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
      final parts = sumParts(s.text);
      if (regroupSlip && parts != null && _sideLessons < maxSideLessons) {
        // the regrouping side lesson straight away (LES-16, TUT-08)
        _sideLessons++;
        side = parts;
        stage = QuickStage.sideLesson;
        notifyListeners();
        await saving;
        return _record([
          SpecEvent('side_lesson_started', {
            'skill_id': _sideSkill(parts),
            'error_type': parts.subtract
                ? 'sub_smaller_from_larger'
                : 'carry_dropped',
          }),
        ]);
      }
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

  /// "Back to my sums": the side lesson is done, and the slipped sum gets
  /// its one more try.
  Future<void> backFromSide() async {
    final parts = side;
    if (stage != QuickStage.sideLesson || parts == null) return;
    side = null;
    stage = QuickStage.secondTry;
    _itemAt = _now();
    notifyListeners();
    await _record([
      SpecEvent('side_lesson_ended', {
        'skill_id': _sideSkill(parts),
        'completed': true,
      }),
    ]);
  }

  /// The side lesson's skill, as the lesson's (skill map ids).
  static String _sideSkill(({int left, int right, bool subtract}) parts) =>
      errorSkill[parts.subtract ? 'sub_smaller_from_larger' : 'carry_dropped']!;

  Future<void> _end() => _record([
    SpecEvent('session_ended', {
      'reason': 'finished',
      'active_ms': _now() - _startedAt,
    }),
  ]);

  /// Leaving part way: the run is over (no case to keep).
  Future<void> leave() async {
    if (_sessionId == null || stage == QuickStage.done) return;
    final parts = side;
    stage = QuickStage.done;
    if (parts != null) {
      side = null;
      // left part way: an unfinished side lesson (TUT-18)
      await _record([
        SpecEvent('side_lesson_ended', {
          'skill_id': _sideSkill(parts),
          'completed': false,
        }),
      ]);
    }
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
  final p = sumParts(text);
  if (p == null) return false;
  return p.subtract
      ? value == noBorrow(p.left, p.right)
      : value == dropCarry(p.left, p.right);
}

/// The two numbers of the sum in [text] ("56 - 19 = ?") and whether it
/// takes away; null for anything else (a missing-number bond).
({int left, int right, bool subtract})? sumParts(String text) {
  final m = RegExp(r'(\d+)\s*([+\-−])\s*(\d+)').firstMatch(text);
  if (m == null) return null;
  return (
    left: int.parse(m[1]!),
    right: int.parse(m[3]!),
    subtract: m[2] != '+',
  );
}
