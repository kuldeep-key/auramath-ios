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

/// The lines the quiet-child nudges say (policy `quiet.glow_line`,
/// `demo_line`, `still_there_line`, TUT-07). Null: no line with that one.
class QuietLines {
  const QuietLines({this.glow = 'cmp.takeYourTime', this.demo, this.still});

  final String glow;
  final String? demo;
  final String? still;
}

/// One rung of the tutor policy's `hint_ladder` (TUT-04): the step it
/// belongs to (a spec step id, or `any` for the everyday example) and its
/// line. A rung with [choice] asks the child to pick (TUT-16 H1-4a); one
/// with [highlight] colours words of the question (H1-4b).
class HintRung {
  const HintRung({
    required this.id,
    required this.step,
    required this.lineId,
    this.choice = const [],
    this.highlight,
    this.everydayExample = false,
  });

  final String id;
  final String step;
  final String lineId;
  final List<String> choice;
  final String? highlight;

  /// The last rung (H1-6, TUT-06): a grown-up and a child, not bars.
  final bool everydayExample;

  @override
  bool operator ==(Object other) => other is HintRung && other.id == id;

  @override
  int get hashCode => id.hashCode;
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
    this.hintLineIds = const [],
    required this.badges,
    required this.lines,
    required this.problems,
    this.maxSideLessons = 2,
    this.noProgressMs = 5 * 60 * 1000,
    this.practiceSums = 3,
    this.questionButtons = const {},
    this.policyLines = const {},
    this.hintLadder = const [],
    this.hintStart = const {},
    this.quietLines = const QuietLines(),
    this.libraryIds = const {},
    this.policyMassLines = const {},
    this.lineVersions = const {},
    this.abandonAfterWrongPractice = 3,
    this.template,
    this.optionalSteps = const {},
    this.addingUp = false,
  });

  factory Pack.fromJson(Map<String, Object?> j) => Pack(
    version: j['version'] as String,
    timers: Timers.fromJson(j['timers'] as Map<String, Object?>),
    hintLineIds: [for (final h in j['hints'] as List? ?? const []) '$h'],
    badges: {
      for (final e in (j['badges'] as Map<String, Object?>).entries)
        e.key: BadgeInfo.fromJson(e.value as Map<String, Object?>),
    },
    lines: (j['lines'] as Map<String, Object?>).cast<String, String>(),
    libraryIds: (j['library'] as Map<String, Object?>? ?? const {})
        .cast<String, String>(),
    lineVersions: {
      for (final MapEntry(:key, :value)
          in (j['versions'] as Map<String, Object?>? ?? const {}).entries)
        if (value is List) key: [for (final v in value) '$v'],
    },
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
    List<HintRung>? hintLadder,
    Map<String, String>? hintStart,
    QuietLines? quietLines,
    Map<String, String>? policyMassLines,
    Map<String, List<String>>? lineVersions,
    int? abandonAfterWrongPractice,
    ComparisonTemplate? template,
    Set<String>? optionalSteps,
    bool? addingUp,
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
    hintLadder: hintLadder ?? this.hintLadder,
    hintStart: hintStart ?? this.hintStart,
    quietLines: quietLines ?? this.quietLines,
    libraryIds: libraryIds,
    policyMassLines: policyMassLines ?? this.policyMassLines,
    lineVersions: lineVersions ?? this.lineVersions,
    abandonAfterWrongPractice:
        abandonAfterWrongPractice ?? this.abandonAfterWrongPractice,
    template: template ?? this.template,
    optionalSteps: optionalSteps ?? this.optionalSteps,
    addingUp: addingUp ?? this.addingUp,
  );

  /// The content bundle's `praise` lines (TUT-12) over the policy's own.
  Pack withPraise(Map<String, String> praise) => praise.isEmpty
      ? this
      : copyWith(policyLines: {...policyLines, ...praise});

  final String version;
  final Timers timers;

  /// Policy `quiet.*_line` (TUT-07).
  final QuietLines quietLines;

  /// Tutor policy `side_lessons.max_per_session`; past it the child gets
  /// the step's usual help instead.
  final int maxSideLessons;

  /// Policy `no_progress_minutes`: this long on one step without moving
  /// on, the child is offered a way out (TUT-10).
  final int noProgressMs;

  /// Policy `side_lessons.practice_if_unsure`: how many smaller sums follow
  /// a side lesson whose own sum the child got wrong (TUT-08).
  final int practiceSums;

  /// Policy `side_lessons.abandon_after_wrong_practice` (TUT-18): this many
  /// wrong practice sums end the side lesson kindly.
  final int abandonAfterWrongPractice;

  /// Policy `question_buttons` (TUT-13): line ids by spec step id, `*` for
  /// every step.
  final Map<String, List<String>> questionButtons;

  /// Policy `lines.pack`, by line id (`line.q.what-now`). Kept apart from
  /// [lines], so the voice isn't warmed with all of them.
  final Map<String, String> policyLines;

  /// Policy `lines.pack[].variants.mass`: a line's words for a weight
  /// story ("heavier", not "taller"), by line id.
  final Map<String, String> policyMassLines;

  /// The pack's `library`: the policy line each pack line stands for
  /// (TUT-11). Such a line shows the library's words; the pack's own text
  /// is only its fallback for a policy without that id.
  final Map<String, String> libraryIds;

  /// More versions of a line, by its library id (or pack id when the
  /// library hasn't it), after its own text (TUT-14): the pack's drafted
  /// `versions`, then any the policy gives as `lines.pack[].versions`.
  final Map<String, List<String>> lineVersions;

  /// Julia's comparison template (served, else bundled): the step order
  /// (LES-03), the choice options (LES-12) and the worked examples (CON-05).
  /// Null: the engine's own order and options.
  final ComparisonTemplate? template;

  /// The template's optional steps turned on (by flag): `name_quantities`,
  /// `number_sentence`.
  final Set<String> optionalSteps;

  /// choose_operation also offers adding up, "D + ? = A" (LES-06, Julia's
  /// J14), until the template has it: a draft for Apoorv and Julia.
  final bool addingUp;

  /// A pack's own flat hint list, used only when there is no policy
  /// [hintLadder] (older packs and the golden vectors).
  final List<String> hintLineIds;

  /// Policy `hint_ladder.rungs`, in order (TUT-04).
  final List<HintRung> hintLadder;

  /// The template's `steps[].hint_start_rung`, by spec step id. A step not
  /// named starts at its first rung on the ladder.
  final Map<String, String> hintStart;

  /// The rungs a hint request walks on [stepId], in order: from the step's
  /// start rung ([start], the server's `hintStartRung` when it sent one,
  /// else the template's), then the everyday example (`step: any`). Empty
  /// when the step has no rung (policy `steps_without_rung`): Help me
  /// offers show me how and something easier there.
  List<HintRung> rungsFor(String? stepId, {String? start}) {
    final own = [
      for (final r in hintLadder)
        if (r.step == stepId) r,
    ];
    if (own.isEmpty) return const [];
    var from = own.indexWhere((r) => r.id == start);
    if (from < 0) from = own.indexWhere((r) => r.id == hintStart[stepId]);
    return [
      ...own.skip(from < 0 ? 0 : from),
      for (final r in hintLadder)
        if (r.step == 'any') r,
    ];
  }

  final Map<String, BadgeInfo> badges;
  final Map<String, String> lines;
  final Map<String, ComparisonProblem> problems;
}
