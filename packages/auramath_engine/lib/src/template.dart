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
  });

  final String id;
  final String a, b, plural, unit, text;

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
          ),
      ],
    );
  }

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
  );

  final String id;
  final String version;
  final List<Level> levels;
  final List<Story> stories;

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

  /// The problem for exact numbers, rendered from the story's frame.
  ComparisonProblem problem(
    String levelId,
    String storyId, {
    required int a,
    required int d,
    String? relation,
    required Map<String, String> pics,
    required NextProblems next,
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
      id: '$storyId-$levelId-$a-$d'.toLowerCase(),
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
      templateId: id,
      templateVersion: version,
      storyId: storyId,
      variant: 'standard',
      level: levelId,
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

/// Julia's tutor rules that the engine runs on, from the spec pack's
/// `tutor/policy.yaml`.
class Policy {
  const Policy({required this.timers, required this.maxSideLessons});

  factory Policy.fromYaml(String text) {
    final y = loadYaml(text) as YamlMap;
    final q = y['quiet'] as YamlMap;
    int ms(String key) => (q[key] as int) * 1000;
    return Policy(
      timers: Timers(
        pulseMs: ms('help_pulse_after_s'),
        glowMs: ms('glow_after_s'),
        handMs: ms('demo_after_s'),
        stillMs: ms('still_there_after_s'),
      ),
      maxSideLessons: (y['side_lessons'] as YamlMap)['max_per_session'] as int,
    );
  }

  final Timers timers;
  final int maxSideLessons;
}

/// App settings that aren't teaching rules, from the spec pack's
/// `content/app-config.yaml`.
class AppConfig {
  const AppConfig({required this.sessionCapMinutes});

  factory AppConfig.fromYaml(String text) {
    final y = loadYaml(text) as YamlMap;
    return AppConfig(
      sessionCapMinutes: (y['session'] as YamlMap)['cap_minutes'] as int,
    );
  }

  /// SES-01, D-07: "no more than half an hour".
  final int sessionCapMinutes;
}
