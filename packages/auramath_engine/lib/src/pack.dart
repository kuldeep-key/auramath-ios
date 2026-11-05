import 'problem.dart';

/// Quiet-child thresholds, in milliseconds since the child's last move.
class Timers {
  const Timers({
    required this.pulseMs,
    required this.glowMs,
    required this.handMs,
    required this.stillMs,
  });

  factory Timers.fromJson(Map<String, Object?> j) => Timers(
    pulseMs: j['pulseMs'] as int,
    glowMs: j['glowMs'] as int,
    handMs: j['handMs'] as int,
    stillMs: j['stillMs'] as int,
  );

  final int pulseMs;
  final int glowMs;
  final int handMs;
  final int stillMs;
}

class BadgeInfo {
  const BadgeInfo({required this.name, required this.says});

  factory BadgeInfo.fromJson(Map<String, Object?> j) =>
      BadgeInfo(name: j['name'] as String, says: j['says'] as String);

  final String name;
  final String says;
}

/// A content pack: problems, the line library, hints, timers and badges.
class Pack {
  const Pack({
    required this.version,
    required this.timers,
    required this.hintLineIds,
    required this.badges,
    required this.lines,
    required this.problems,
    this.maxSideLessons = 2,
    this.noProgressMs = 5 * 60 * 1000,
  });

  factory Pack.fromJson(Map<String, Object?> j) => Pack(
    version: j['version'] as String,
    timers: Timers.fromJson(j['timers'] as Map<String, Object?>),
    hintLineIds: [for (final h in j['hints'] as List) h as String],
    badges: {
      for (final e in (j['badges'] as Map<String, Object?>).entries)
        e.key: BadgeInfo.fromJson(e.value as Map<String, Object?>),
    },
    lines: (j['lines'] as Map<String, Object?>).cast<String, String>(),
    problems: {
      for (final p in j['problems'] as List)
        (p as Map<String, Object?>)['id'] as String: ComparisonProblem.fromJson(
          p,
        ),
    },
  );

  Pack copyWith({Timers? timers, int? maxSideLessons, int? noProgressMs}) =>
      Pack(
        version: version,
        timers: timers ?? this.timers,
        hintLineIds: hintLineIds,
        badges: badges,
        lines: lines,
        problems: problems,
        maxSideLessons: maxSideLessons ?? this.maxSideLessons,
        noProgressMs: noProgressMs ?? this.noProgressMs,
      );

  final String version;
  final Timers timers;

  /// Tutor policy `side_lessons.max_per_session`; past it the child gets
  /// the step's usual help instead.
  final int maxSideLessons;

  /// Policy `no_progress_minutes`: this long on one step without moving
  /// on, the child is offered a way out (TUT-10).
  final int noProgressMs;
  final List<String> hintLineIds;
  final Map<String, BadgeInfo> badges;
  final Map<String, String> lines;
  final Map<String, ComparisonProblem> problems;
}
