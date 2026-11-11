import 'dart:math';

import 'package:yaml/yaml.dart';

import 'mistakes.dart';
import 'pack.dart';
import 'problem.dart';

/// One step of difficulty in a question type (template `levels`, SKL-10).
class Level {
  const Level({
    required this.id,
    required this.relations,
    required this.aMin,
    required this.aMax,
    required this.dMin,
    required this.dMax,
    required this.constraints,
    required this.twoStep,
    this.questionText,
    this.stepsEndAt,
    this.skipSteps = const [],
  });

  final String id;

  /// `taller`, `shorter`, or both.
  final List<String> relations;
  final int aMin, aMax, dMin, dMax;
  final List<String> constraints;

  /// Ends at the total (levels 3 to 5), not at the missing amount.
  final bool twoStep;

  /// Overrides the story's text (levels 1 and 2 ask only for b).
  final String? questionText;

  /// `steps_end_at`: the last answer step (`find_unknown` or `find_total`).
  final String? stepsEndAt;

  /// `skip_steps`: template steps this level leaves out.
  final List<String> skipSteps;
}

/// One option of a choice step (template `steps[].options`).
class StepOption {
  const StepOption({
    required this.id,
    required this.text,
    this.correctFor = const [],
    this.errorType,
  });

  /// `a_minus_d`; logged as `choice_selected.option_id`.
  final String id;

  /// `A - D`, `{A} {unit}`: the template's symbols, filled per problem.
  final String text;

  /// The relations (`taller`, `shorter`) this option is right for.
  final List<String> correctFor;

  /// What choosing it wrongly is charged as.
  final String? errorType;
}

/// One form a number sentence may take (template `steps[].accepts`).
class SentenceForm {
  const SentenceForm({required this.form, this.correctFor = const []});

  /// `A - D = box`.
  final String form;
  final List<String> correctFor;
}

/// One step of the question type, in the template's order (LES-03).
class TemplateStep {
  const TemplateStep({
    required this.id,
    this.screen,
    this.optional = false,
    this.options = const [],
    this.accepts = const [],
  });

  /// The spec step id: `draw_known_bar`, `choose_operation`, ...
  final String id;

  /// The Figma screen (`D4`), or `TBD (Apoorv)`.
  final String? screen;

  /// Runs only where the app turns it on (a flag).
  final bool optional;
  final List<StepOption> options;
  final List<SentenceForm> accepts;
}

/// Worked examples for "show me how" (template `worked_examples`, CON-05).
class WorkedExample {
  const WorkedExample({
    required this.storyId,
    required this.relation,
    required this.a,
    required this.d,
    required this.b,
    required this.total,
  });

  final String storyId;
  final String relation;
  final int a, d, b, total;
}

/// A story the template's numbers are dropped into.
class Story {
  const Story({
    required this.id,
    required this.a,
    required this.b,
    required this.plural,
    required this.unit,
    required this.text,
    required this.relationWords,
    this.quantity = 'height',
    this.orientation = 'upright',
  });

  final String id;
  final String a, b, plural, unit, text;

  /// `height` or `mass` (CON-11).
  final String quantity;

  /// `upright` or `horizontal` bars (LES-04).
  final String orientation;

  /// The word for each relation (`more`/`less` for weights).
  final Map<String, String> relationWords;
}

/// Julia's comparison question type, read from the spec pack's
/// `content/templates/comparison-two-step.yaml`. Code picks every number
/// and works out every answer (CON-01, CON-08).
class ComparisonTemplate {
  const ComparisonTemplate({
    required this.id,
    required this.version,
    required this.levels,
    required this.stories,
    this.hintStart = const {},
    this.steps = const [],
    this.workedExamples = const [],
  });

  factory ComparisonTemplate.fromYaml(String text) {
    final y = loadYaml(text) as YamlMap;
    final base = y['numbers'] as YamlMap;
    return ComparisonTemplate(
      id: y['id'] as String,
      version: y['version'] as String,
      levels: [
        for (final l in y['levels'] as YamlList)
          _level(l as YamlMap, (l['numbers'] as YamlMap?) ?? base),
      ],
      hintStart: {
        for (final st
            in (y['steps'] as YamlList? ?? YamlList()).cast<YamlMap>())
          if (st['hint_start_rung'] case final String rung) '${st['id']}': rung,
      },
      stories: [
        for (final s in y['stories'] as YamlList)
          Story(
            id: s['id'] as String,
            a: s['a'] as String,
            b: s['b'] as String,
            plural: s['plural'] as String,
            unit: s['unit'] as String,
            text: s['text'] as String,
            relationWords: {
              for (final MapEntry(:key, :value)
                  in ((s['relation_words'] as YamlMap?) ?? const {}).entries)
                key as String: value as String,
            },
            quantity: s['quantity'] as String? ?? 'height',
            orientation: s['orientation'] as String? ?? 'upright',
          ),
      ],
      steps: [
        for (final st in (y['steps'] as YamlList?) ?? YamlList())
          _step(st as YamlMap),
      ],
      workedExamples: [
        for (final w in (y['worked_examples'] as YamlList?) ?? YamlList())
          WorkedExample(
            storyId: (w as YamlMap)['story'] as String,
            relation: w['relation'] as String? ?? 'taller',
            a: w['A'] as int,
            d: w['D'] as int,
            b: w['B'] as int,
            total: w['total'] as int,
          ),
      ],
    );
  }

  static List<String> _strings(Object? l) => [
    for (final v in (l as YamlList?) ?? YamlList()) '$v',
  ];

  static TemplateStep _step(YamlMap st) => TemplateStep(
    id: st['id'] as String,
    screen: st['screen'] as String?,
    optional: st['optional'] == true,
    options: [
      for (final o in (st['options'] as YamlList?) ?? YamlList())
        StepOption(
          id: (o as YamlMap)['id'] as String,
          text: '${o['text']}',
          correctFor: _strings(o['correct_for']),
          errorType: o['error_type'] as String?,
        ),
    ],
    accepts: [
      for (final a in (st['accepts'] as YamlList?) ?? YamlList())
        SentenceForm(
          form: '${(a as YamlMap)['form']}',
          correctFor: _strings(a['correct_for']),
        ),
    ],
  );

  static Level _level(YamlMap l, YamlMap n) => Level(
    id: l['id'] as String,
    relations: [for (final r in l['relations'] as YamlList) r as String],
    aMin: (n['A'] as YamlMap)['min'] as int,
    aMax: (n['A'] as YamlMap)['max'] as int,
    dMin: (n['D'] as YamlMap)['min'] as int,
    dMax: (n['D'] as YamlMap)['max'] as int,
    constraints: [for (final c in n['constraints'] as YamlList) c as String],
    twoStep: l['steps_end_at'] == 'find_total',
    questionText: l['question_text'] as String?,
    stepsEndAt: l['steps_end_at'] as String?,
    skipSteps: _strings(l['skip_steps']),
  );

  final String id;
  final String version;

  /// `steps[].hint_start_rung` by step id (TUT-04).
  final Map<String, String> hintStart;
  final List<Level> levels;
  final List<Story> stories;

  /// `steps`, in the template's order (LES-03).
  final List<TemplateStep> steps;

  /// `worked_examples` (CON-05).
  final List<WorkedExample> workedExamples;

  TemplateStep? stepById(String id) =>
      steps.where((s) => s.id == id).firstOrNull;

  /// The spec step ids a problem at [levelId] runs, in the template's
  /// order: without the level's `skip_steps`, the answer steps past its
  /// `steps_end_at`, optional steps not in [optionalOn], and any step this
  /// engine can't run. Empty when the template lists no steps.
  List<String> stepsFor(String? levelId, {Set<String> optionalOn = const {}}) {
    final l = levels.where((l) => l.id == levelId).firstOrNull;
    final end = l?.stepsEndAt;
    final cut = end == 'find_unknown' ? const {'find_total'} : const <String>{};
    return [
      for (final st in steps)
        if (knownSteps.contains(st.id) &&
            !(l?.skipSteps.contains(st.id) ?? false) &&
            !cut.contains(st.id) &&
            (!st.optional || optionalOn.contains(st.id)))
          st.id,
    ];
  }

  Level level(String id) => levels.firstWhere((l) => l.id == id);
  Story story(String id) => stories.firstWhere((s) => s.id == id);

  /// A new problem at [levelId] whose numbers pass every one of the level's
  /// constraints. The same [rng] seed always gives the same problem.
  ComparisonProblem generate(
    String levelId,
    String storyId,
    Random rng, {
    required Map<String, String> pics,
    required NextProblems next,
  }) {
    final l = level(levelId);
    final relation = l.relations[rng.nextInt(l.relations.length)];
    for (var tries = 0; tries < 5000; tries++) {
      final a = l.aMin + rng.nextInt(l.aMax - l.aMin + 1);
      final d = l.dMin + rng.nextInt(l.dMax - l.dMin + 1);
      final p = problem(
        levelId,
        storyId,
        a: a,
        d: d,
        relation: relation,
        pics: pics,
        next: next,
      );
      if (l.constraints.every((c) => _holds(c, p, l))) return p;
    }
    throw StateError('$levelId: no numbers pass ${l.constraints}');
  }

  /// The problem for exact numbers, rendered from the story's frame. [id]
  /// and [variant] keep a served problem's own (a case rebuilt from its
  /// `problem_shown`).
  ComparisonProblem problem(
    String levelId,
    String storyId, {
    required int a,
    required int d,
    String? relation,
    required Map<String, String> pics,
    required NextProblems next,
    String? id,
    String variant = 'standard',
  }) {
    final l = level(levelId);
    final s = story(storyId);
    final rel = relation ?? l.relations.first;
    String render(String unit) => (l.questionText ?? s.text)
        .replaceAll('{a}', s.a)
        .replaceAll('{b}', s.b)
        .replaceAll('{A}', '$a')
        .replaceAll('{D}', '$d')
        .replaceAll('{unit}', unit)
        .replaceAll('{relation}', s.relationWords[rel] ?? rel)
        .replaceAll('{plural}', s.plural);
    Item item(String name) => Item(
      name: name[0].toUpperCase() + name.substring(1),
      pic: pics[name] ?? (throw ArgumentError('no picture for "$name"')),
    );
    return ComparisonProblem(
      id: id ?? '$storyId-$levelId-$a-$d'.toLowerCase(),
      a: item(s.a),
      b: item(s.b),
      aValue: a,
      diff: d,
      big: rel == 'shorter' ? BigSide.b : BigSide.a,
      unit: s.unit,
      ask: l.twoStep ? Ask.total : Ask.b,
      text: render(s.unit),
      say: render(_spoken[s.unit] ?? s.unit),
      next: next,
      templateId: this.id,
      templateVersion: version,
      storyId: storyId,
      variant: variant,
      level: levelId,
      quantity: s.quantity,
    );
  }
}

const _spoken = {'cm': 'centimetres', 'm': 'metres', 'g': 'grams'};

final _atLeast = RegExp(r'^B >= (\d+)$');

/// One template constraint. An unknown one fails loudly rather than being
/// skipped, so a new rule in Julia's file can't pass silently.
bool _holds(String c, ComparisonProblem p, Level l) {
  final a = p.aValue, d = p.diff, b = p.bValue;
  final findB = p.big == BigSide.a ? _borrows(a, d) : _carries(a, d);
  if (_atLeast.firstMatch(c) case final m?) return b >= int.parse(m[1]!);
  return switch (c) {
    'D < A' => d < a,
    'A + B <= 999' => a + b <= 999,
    'B != D' => b != d,
    'regrouping' => findB,
    'no_regrouping' => !findB && !(l.twoStep && _carries(a, b)),
    'error_answers_distinct' =>
      !hasCollision(p) && (!l.twoStep || _totalDistinct(p)),
    _ => throw StateError('unknown template constraint "$c"'),
  };
}

/// The total's mistake answers differ from it and from each other.
bool _totalDistinct(ComparisonProblem p) {
  final wrong = [
    p.bValue,
    ?dropCarry(p.aValue, p.bValue),
    reverseDigits(p.total),
  ].where((n) => n != p.total).toList();
  return wrong.toSet().length == wrong.length;
}

bool _borrows(int x, int y) {
  for (; y > 0; x ~/= 10, y ~/= 10) {
    if (x % 10 < y % 10) return true;
  }
  return false;
}

bool _carries(int x, int y) {
  for (; x > 0 || y > 0; x ~/= 10, y ~/= 10) {
    if (x % 10 + y % 10 >= 10) return true;
  }
  return false;
}

/// The worked example "show me how" draws for [p] (CON-05): the template's
/// one with [p]'s relation, else its first. Null when the pack has none.
WorkedExample? exampleFor(Pack pack, ComparisonProblem p) {
  final all = pack.template?.workedExamples ?? const <WorkedExample>[];
  final relation = p.big == BigSide.a ? 'taller' : 'shorter';
  return all.where((e) => e.relation == relation).firstOrNull ??
      all.firstOrNull;
}

/// Julia's tutor rules that the engine runs on, from the spec pack's
/// `tutor/policy.yaml`.
class Policy {
  const Policy({
    required this.timers,
    required this.maxSideLessons,
    required this.noProgressMs,
    required this.practiceSums,
    this.questionButtons = const {},
    this.lines = const {},
    this.version = '',
    this.forbiddenPhrases = const [],
    this.ageWordList,
    this.abandonAfterWrongPractice = 3,
    this.hintLadder = const [],
    this.quietLines = const QuietLines(),
    this.massLines = const {},
    this.versions = const {},
  });

  factory Policy.fromYaml(String text) {
    final y = loadYaml(text) as YamlMap;
    final q = y['quiet'] as YamlMap;
    int ms(String key) => (q[key] as int) * 1000;
    final buttons = y['question_buttons'] as YamlMap?;
    final every = [for (final b in buttons?['every_step'] as List? ?? []) '$b'];
    final byStep = buttons?['by_step'] as YamlMap? ?? YamlMap();
    final pack = (y['lines'] as YamlMap?)?['pack'] as List? ?? const [];
    final side = y['side_lessons'] as YamlMap;
    final story = y['story_generation'] as YamlMap?;
    final words = story?['age_word_list'];
    final ladder = y['hint_ladder'] as YamlMap?;
    return Policy(
      versions: {
        for (final l in pack.cast<YamlMap>())
          if (l['versions'] case final List v)
            l['id'] as String: [for (final t in v) '$t'],
      },
      massLines: {
        for (final l in pack.cast<YamlMap>())
          if ((l['variants'] as YamlMap?)?['mass'] case final String mass)
            l['id'] as String: mass,
      },
      quietLines: QuietLines(
        glow: q['glow_line'] as String? ?? 'cmp.takeYourTime',
        demo: q['demo_line'] as String?,
        still: q['still_there_line'] as String?,
      ),
      hintLadder: [
        for (final r in (ladder?['rungs'] as List? ?? const []).cast<YamlMap>())
          HintRung(
            id: '${r['id']}',
            step: '${r['step']}',
            lineId: '${(r['lines'] as List).first}',
            choice: [for (final c in r['choice'] as List? ?? const []) '$c'],
            highlight: r['highlight'] as String?,
            everydayExample: r['everyday_example'] == true,
          ),
      ],
      version: '${y['version'] ?? ''}',
      forbiddenPhrases: [
        for (final f
            in (y['lines'] as YamlMap?)?['forbidden_phrases'] as List? ??
                const [])
          '$f',
      ],
      ageWordList: words is YamlMap
          ? AgeWordList(
              id: '${words['id']}',
              approved: words['approved'] == true,
              words: {for (final w in words['words'] as List) '$w'},
            )
          : null,
      abandonAfterWrongPractice:
          side['abandon_after_wrong_practice'] as int? ?? 3,
      questionButtons: {
        '*': every,
        for (final MapEntry(:key, :value) in byStep.entries)
          '$key': [for (final b in value as List) '$b'],
      },
      lines: {
        for (final l in pack.cast<YamlMap>())
          if (l['id'] is String && l['text'] is String)
            l['id'] as String: l['text'] as String,
      },
      timers: Timers(
        pulseMs: ms('help_pulse_after_s'),
        glowMs: ms('glow_after_s'),
        handMs: ms('demo_after_s'),
        stillMs: ms('still_there_after_s'),
      ),
      maxSideLessons: side['max_per_session'] as int,
      noProgressMs: (y['no_progress_minutes'] as int) * 60 * 1000,
      practiceSums: side['practice_if_unsure'] as int? ?? 3,
    );
  }

  /// `lines.pack[].versions` (TUT-14), when Julia's library holds more
  /// than one version of a line; none do in v0.4.0.
  final Map<String, List<String>> versions;

  /// `lines.pack[].variants.mass`, by line id.
  final Map<String, String> massLines;

  /// `quiet.glow_line`, `demo_line`, `still_there_line` (TUT-07).
  final QuietLines quietLines;

  /// `hint_ladder.rungs` (TUT-04), in order.
  final List<HintRung> hintLadder;

  /// The policy file's own `version` (0.4.0 from spec pack v0.4).
  final String version;

  /// `lines.forbidden_phrases` (TUT-12, AI-07): no child line may contain
  /// one, in any case.
  final List<String> forbiddenPhrases;

  /// `story_generation.age_word_list` (CON-08), from v0.4; null before.
  final AgeWordList? ageWordList;

  /// `side_lessons.abandon_after_wrong_practice` (TUT-18, v0.4): this many
  /// wrong practice sums end a side lesson kindly.
  final int abandonAfterWrongPractice;

  final Timers timers;
  final int maxSideLessons;

  /// `no_progress_minutes`: this long on one step means too hard (TUT-10).
  final int noProgressMs;

  /// `side_lessons.practice_if_unsure`: smaller sums after a side lesson
  /// whose own sum the child got wrong.
  final int practiceSums;

  /// `question_buttons` (TUT-13): line ids by spec step id; `*` holds the
  /// ones every step shows.
  final Map<String, List<String>> questionButtons;

  /// `lines.pack`: Julia's line library, text by line id.
  final Map<String, String> lines;
}

/// The words a hint may use for ages 6 to 10 (policy
/// `story_generation.age_word_list`). A draft until Julia approves it.
class AgeWordList {
  const AgeWordList({
    required this.id,
    required this.approved,
    required this.words,
  });

  final String id;
  final bool approved;

  /// Lower case.
  final Set<String> words;
}

/// App settings that aren't teaching rules, from the spec pack's
/// `content/app-config.yaml`.
class AppConfig {
  const AppConfig({
    required this.sessionCapMinutes,
    this.flags = const {},
    this.cueAfterMs = 1000,
    this.fallbackAfterMs = 4000,
    this.clockPausesWhileOffline = true,
  });

  factory AppConfig.fromYaml(String text) {
    final y = loadYaml(text) as YamlMap;
    final session = y['session'] as YamlMap;
    final ai = y['ai'] as YamlMap? ?? YamlMap();
    return AppConfig(
      sessionCapMinutes: session['cap_minutes'] as int,
      cueAfterMs: ai['waiting_cue_after_ms'] as int? ?? 1000,
      fallbackAfterMs: ai['fallback_after_ms'] as int? ?? 4000,
      clockPausesWhileOffline:
          session['clock_pauses_while_offline'] as bool? ?? true,
      flags: {
        for (final MapEntry(:key, :value)
            in (y['flags'] as YamlMap? ?? YamlMap()).entries)
          key as String: value is YamlList ? value.toList() : value,
      },
    );
  }

  /// SES-01, D-07: "no more than half an hour".
  final int sessionCapMinutes;

  /// PLAT-06: the remote flags' defaults, used until the server answers.
  final Map<String, Object?> flags;

  /// `ai.waiting_cue_after_ms` (NFR-05): no decision by then, the case
  /// partner shows a small thinking cue.
  final int cueAfterMs;

  /// `ai.fallback_after_ms` (NFR-05, AI-04): no decision by then, the
  /// rules' choice shows and the lesson carries on.
  final int fallbackAfterMs;

  /// `session.clock_pauses_while_offline` (SES-04): the cap doesn't run
  /// while the lesson waits for the internet.
  final bool clockPausesWhileOffline;
}
