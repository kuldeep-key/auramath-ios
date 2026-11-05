import 'dart:convert';

import '../../../../data/services/key_store.dart';

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
  int capMs;
  final KeyStore? store;
  final int Function() _now;

  static const _key = 'sitting';

  void useMinutes(int minutes) {
    final ms = minutes * 60 * 1000;
    capMs = ms < maxCapMs ? ms : maxCapMs;
  }

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
    final saved = await store?.read(_key);
    if (saved == null) return;
    final j = jsonDecode(saved) as Map<String, Object?>;
    _rollOver();
    if (j['day'] == _day) _activeMs = j['ms']! as int;
  }

  Future<void> save() async =>
      store?.write(_key, jsonEncode({'day': _day, 'ms': activeMs}));
}
