/// One sitting of lessons: the child's active time across problems, for the
/// cap in app-config `session.cap_minutes` (SES-01). Never shown to the
/// child: there is no clock or countdown anywhere (SES-02).
// ponytail: lives as long as the app process; a new launch is a new sitting.
class Sitting {
  Sitting({required this.capMs});

  final int capMs;
  int activeMs = 0;

  /// Time was up and the child chose to finish the problem they were on.
  bool finishing = false;

  bool get over => activeMs >= capMs;
}
