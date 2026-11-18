import 'dart:convert';

import '../../../../data/services/key_store.dart';
import 'repeat_triggers.dart';

/// The child's active lesson time today, across problems and launches, for
/// the cap in app-config `session.cap_minutes` (SES-01). Never shown to the
/// child: there is no clock or countdown anywhere (SES-02).
class Sitting {
  /// [capMs] is the most a day may run (app-config); the grown-up's
  /// "Time each day" can only shorten it ([useMinutes]). With a [store],
  /// the day's time survives a new launch.
  Sitting({required int capMs, this.store, int Function()? nowMs})
    : maxCapMs = capMs,
      capMs = capMs,
      _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final int maxCapMs;

  /// Mistakes that come back across this sitting's problems (TUT-08).
  final repeats = RepeatTriggers();

  /// The Sound screen was shown this sitting (NFR-06, journey 20): once.
  bool soundAsked = false;
  int capMs;
  final KeyStore? store;
  final int Function() _now;

  /// One key per child: each child has their own day's time (SES-01).
  /// Before this, one key held the phone's time, so a second child on the
  /// same phone started where the first had stopped, already at the cap.
  static const _key = 'sitting';
  String get _childKey => child == null ? _key : '$_key:$child';

  /// Whose time this is: the child the lesson is for. [forChild] switches.
  String? child;

  /// The grown-up's time each day (PAR-05); null: no limit, so the cap.
  void useMinutes(int? minutes) {
    final ms = minutes == null ? maxCapMs : minutes * 60 * 1000;
    capMs = ms < maxCapMs ? ms : maxCapMs;
  }

  /// SES-01: the server's cap for the lesson opening now (`dailyTime.
  /// capMs`): the smaller of the session cap and what is left of the
  /// child's day on every family phone. It runs from today's time so far.
  void runFor(int ms) => capMs = activeMs + (ms < 0 ? 0 : ms);

  String _day = '';
  int _activeMs = 0;

  /// Today's active time; a new day starts again from nothing.
  int get activeMs {
    _rollOver();
    return _activeMs;
  }

  set activeMs(int ms) {
    _rollOver();
    _activeMs = ms;
  }

  void _rollOver() {
    final today = _today();
    if (_day == today) return;
    _day = today;
    _activeMs = 0;
    finishing = false;
  }

  String _today() {
    final d = DateTime.fromMillisecondsSinceEpoch(_now());
    return '${d.year}-${d.month}-${d.day}';
  }

  /// Time was up and the child chose to finish the problem they were on.
  /// A new lesson clears it ([newLesson]).
  bool finishing = false;

  bool get over => activeMs >= capMs;

  /// A lesson starts: "finish this one" was for the one before.
  void newLesson() => finishing = false;

  Future<void> load() async {
    _rollOver();
    _activeMs = 0;
    final saved = await store?.read(_childKey);
    if (saved == null) return;
    final j = jsonDecode(saved) as Map<String, Object?>;
    if (j['day'] == _day) _activeMs = j['ms']! as int;
  }

  /// A lesson for [childId] starts: their own day's time, from the store.
  /// The time of the child before is saved first.
  Future<void> forChild(String? childId) async {
    if (childId == child) return;
    if (child != null) await save();
    child = childId;
    finishing = false;
    await load();
  }

  Future<void> save() async =>
      store?.write(_childKey, jsonEncode({'day': _day, 'ms': activeMs}));
}
