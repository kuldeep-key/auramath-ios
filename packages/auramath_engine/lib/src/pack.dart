import 'problem.dart';
import 'template.dart';

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
    this.practiceSums = 3,
    this.questionButtons = const {},
    this.policyLines = const {},
    this.template,
    this.optionalSteps = const {},
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

  Pack copyWith({
    Timers? timers,
    int? maxSideLessons,
    int? noProgressMs,
    int? practiceSums,
    Map<String, List<String>>? questionButtons,
    Map<String, String>? policyLines,
    ComparisonTemplate? template,
    Set<String>? optionalSteps,
  }) => Pack(
    version: version,
    timers: timers ?? this.timers,
    hintLineIds: hintLineIds,
    badges: badges,
    lines: lines,
    problems: problems,
    maxSideLessons: maxSideLessons ?? this.maxSideLessons,
    noProgressMs: noProgressMs ?? this.noProgressMs,
    practiceSums: practiceSums ?? this.practiceSums,
    questionButtons: questionButtons ?? this.questionButtons,
    policyLines: policyLines ?? this.policyLines,
    template: template ?? this.template,
    optionalSteps: optionalSteps ?? this.optionalSteps,
  );

  final String version;
  final Timers timers;

  /// Tutor policy `side_lessons.max_per_session`; past it the child gets
  /// the step's usual help instead.
  final int maxSideLessons;

  /// Policy `no_progress_minutes`: this long on one step without moving
  /// on, the child is offered a way out (TUT-10).
  final int noProgressMs;

  /// Policy `side_lessons.practice_if_unsure`: how many smaller sums follow
  /// a side lesson whose own sum the child got wrong (TUT-08).
  final int practiceSums;

  /// Policy `question_buttons` (TUT-13): line ids by spec step id, `*` for
  /// every step.
  final Map<String, List<String>> questionButtons;

  /// Policy `lines.pack`, by line id (`line.q.what-now`). Kept apart from
  /// [lines], so the voice isn't warmed with all of them.
  final Map<String, String> policyLines;

  /// Julia's comparison template (served, else bundled): the step order
  /// (LES-03), the choice options (LES-12) and the worked examples (CON-05).
  /// Null: the engine's own order and options.
  final ComparisonTemplate? template;

  /// The template's optional steps turned on (by flag): `name_quantities`,
  /// `number_sentence`.
  final Set<String> optionalSteps;
  final List<String> hintLineIds;
  final Map<String, BadgeInfo> badges;
  final Map<String, String> lines;
  final Map<String, ComparisonProblem> problems;
}
