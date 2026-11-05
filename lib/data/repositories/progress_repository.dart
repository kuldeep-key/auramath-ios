import 'package:auramath_engine/auramath_engine.dart';

import '../models/lesson_event.dart';
import '../services/api.dart';
import 'account_repository.dart';
import 'family_repository.dart';
import 'session_repository.dart';

/// A stop on the child's trail: a skill from the spec's skill map
/// (`assets/spec/skill-map.yaml`), in the order the child meets them.
///
/// The map has no trail order and no names a child reads, so both are
/// here: the arithmetic the comparison skill rests on, comparison itself,
/// its "shorter" wording (level L5, SKL-10), then question type 2. The
/// test checks every id is still in the map.
enum TrailStop {
  addBig('arith.add-3d-regroup', '➕'),
  takeAwayBig('arith.sub-3d-regroup', '➖'),
  trees('cmp.compare-bars', '🌳'),
  trickyWords('cmp.inconsistent-wording', '🔀'),
  totalAndDifference('td.total-and-difference', '🍔');

  const TrailStop(this.skillId, this.art);

  final String skillId;
  final String art;

  /// The stop a problem practises. Level L5 is the "shorter" wording that
  /// needs adding (SKL-10, `cmp.inconsistent-wording`); the rest of the
  /// comparison template is `cmp.compare-bars` (its `skill:`).
  // ponytail: one template this term; map templateId when a second arrives
  static TrailStop of(ComparisonProblem p) =>
      p.level == 'L5' ? trickyWords : trees;
}

/// Where the child is on the trail, as far as this phone knows.
typedef Trail = ({TrailStop here, bool atTop});

/// What shows after a solved case, before X1 (Case closed).
typedef AfterCase = ({
  ComparisonProblem? solved,
  ComparisonProblem next,

  /// The badge this case earned, for Y4 (Sent to your grown-up); null
  /// when Y4 doesn't show.
  String? sentBadge,

  /// Streak (On a roll).
  bool streak,

  /// Up (Something new to crack): the stop that just opened.
  TrailStop? opened,
});

/// The child's badges, trail and after-case moments, read from the lesson
/// events saved on this phone (the backend has no child-readable progress
/// yet, and a child's own phone can't read the family's record, DEV-04).
class ProgressRepository {
  ProgressRepository({
    required this._pack,
    required this._events,
    required this._sessions,
    required this._family,
    required this._account,
  });

  final Pack _pack;

  /// Every saved event, oldest first.
  final Future<List<LessonEvent>> Function() _events;
  final SessionRepository _sessions;
  final FamilyRepository _family;
  final AccountRepository _account;

  /// Two solved cases further apart than a sitting's cap (30 min, SES-01)
  /// are not "in a row".
  static const sittingMs = 30 * 60 * 1000;

  /// Streak shows on this many cases in a row: once, as a surprise, never
  /// as a count (Figma 23.2).
  static const streakAt = 3;

  /// Badge ids earned on this phone, first earned first.
  Future<List<String>> earnedBadges() async => {
    for (final e in await _events())
      if (e.name == 'badge_awarded') e.payload['badge_id']! as String,
  }.toList();

  /// The furthest stop with a solved case; the first problem stop before
  /// any. The top is reached once the last stop has a solved case: the
  /// most this phone can know until the server says what is mastered.
  Future<Trail> trail() async {
    final here = _furthest(await _events()) ?? TrailStop.trees;
    return (here: here, atTop: here == TrailStop.values.last);
  }

  /// The after-case rules, from what this phone can know:
  ///
  /// - **Y4** when the family can see the badge: a signed-in family
  ///   ([familyHears]: a grown-up's or paired phone, and the last send
  ///   reached the server). Never claimed offline or with no account.
  /// - **Streak** when this is the [streakAt]th case solved in a row:
  ///   one session after another, each solved, none further apart than
  ///   [sittingMs] (a case left for something easier breaks the run).
  /// - **Up** when the next case is on a stop the child hasn't solved a
  ///   case on before, further along than any they have.
  Future<AfterCase> afterCase(String next, {required bool familyHears}) async {
    final events = await _events();
    final solvedId = events
        .where((e) => e.name == 'problem_completed')
        .lastOrNull
        ?.payload['problem_id'];
    final badge = events
        .where((e) => e.name == 'badge_awarded')
        .lastOrNull
        ?.payload['badge_id'];
    final nextProblem = _pack.problems[next]!;
    final furthest = _furthest(events);
    final nextStop = TrailStop.of(nextProblem);
    return (
      solved: _pack.problems[solvedId],
      next: nextProblem,
      sentBadge: familyHears ? badge as String? : null,
      streak: _run(events) == streakAt,
      opened: furthest != null && nextStop.index > furthest.index
          ? nextStop
          : null,
    );
  }

  bool _welcomed = false;

  /// True once per app launch, on the first Home, when a case was left
  /// unfinished: WelcomeBack greets the child instead of Home.
  Future<bool> welcomeBackDue() async {
    if (_welcomed) return false;
    _welcomed = true;
    final next = await _sessions.whereNext(_pack);
    return next?.resumeSessionId != null;
  }

  String? _name;

  /// The child's name from the last successful read, for Home's first
  /// frame.
  String? get cachedName => _name;

  /// The active child's name (`/api/children`). Offline or on a server
  /// error, the last name read; Home shows no name rather than a wrong one.
  Future<String?> childName() async {
    try {
      final id = _account.childId;
      final kids = await _family.children();
      return _name = kids.where((c) => c.id == id).firstOrNull?.name;
    } on ApiException {
      return _name;
    }
  }

  TrailStop? _furthest(List<LessonEvent> events) {
    TrailStop? far;
    for (final e in events) {
      if (e.name != 'problem_completed') continue;
      final p = _pack.problems[e.payload['problem_id']];
      if (p == null) continue;
      final stop = TrailStop.of(p);
      if (far == null || stop.index > far.index) far = stop;
    }
    return far;
  }

  /// Cases solved in a row, counted back from the latest session.
  static int _run(List<LessonEvent> events) {
    final sessions = <String, List<LessonEvent>>{};
    for (final e in events) {
      (sessions[e.sessionId] ??= []).add(e);
    }
    var run = 0;
    int? newer;
    for (final s in sessions.values.toList().reversed) {
      final done = s.where((e) => e.name == 'problem_completed').lastOrNull;
      if (done == null || newer != null && newer - done.at > sittingMs) break;
      newer = done.at;
      run++;
    }
    return run;
  }
}
