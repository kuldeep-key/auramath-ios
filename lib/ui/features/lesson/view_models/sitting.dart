/// One sitting of lessons: the child's active time across problems, for the
/// cap in app-config `session.cap_minutes` (SES-01). Never shown to the
/// child: there is no clock or countdown anywhere (SES-02).
// ponytail: lives as long as the app process; a new launch is a new sitting.
class Sitting {
  /// [capMs] is the most a sitting may run (app-config); the grown-up's
  /// "Time each day" can only shorten it ([useMinutes]).
  Sitting({required int capMs}) : maxCapMs = capMs, capMs = capMs;

  final int maxCapMs;
  int capMs;

  void useMinutes(int minutes) {
    final ms = minutes * 60 * 1000;
    capMs = ms < maxCapMs ? ms : maxCapMs;
  }

  int activeMs = 0;

  /// Time was up and the child chose to finish the problem they were on.
  bool finishing = false;

  bool get over => activeMs >= capMs;
}
