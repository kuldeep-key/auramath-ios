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

  final String version;
  final Timers timers;
  final List<String> hintLineIds;
  final Map<String, BadgeInfo> badges;
  final Map<String, String> lines;
  final Map<String, ComparisonProblem> problems;
}
