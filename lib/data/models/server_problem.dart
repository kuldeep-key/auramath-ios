import 'package:auramath_engine/auramath_engine.dart';

import '../services/api.dart';

/// The engine's problem for one from `problems/next`. Its next problems
/// are the server's to choose, so they are left empty: the lesson asks
/// again instead.
ComparisonProblem problemFromServer(Map<String, Object?> j) {
  if (j['templateId'] != 'cmp.comparison') {
    throw ApiException(
      "This version of the app can't show ${j['templateId']} problems yet",
    );
  }
  final story = j['story']! as Map<String, Object?>;
  final numbers = j['numbers']! as Map<String, Object?>;
  final expected = j['expected']! as Map<String, Object?>;
  final text = j['questionText']! as String;
  String name(String s) => '${s[0].toUpperCase()}${s.substring(1)}';
  return ComparisonProblem(
    id: j['problemId']! as String,
    a: Item(name: name(story['a']! as String), pic: _pic(story, 'a')),
    b: Item(name: name(story['b']! as String), pic: _pic(story, 'b')),
    aValue: numbers['A']! as int,
    diff: numbers['D']! as int,
    // the first item is the bigger one when it is "taller" / "heavier"
    big: const {'shorter', 'lighter'}.contains(j['relation'])
        ? BigSide.b
        : BigSide.a,
    unit: story['unit']! as String,
    ask: expected.containsKey('total') ? Ask.total : Ask.b,
    text: text,
    say: spokenUnits(text),
    next: const NextProblems(fast: '', helped: '', easier: ''),
    templateId: j['templateId']! as String,
    templateVersion: j['templateVersion']! as String,
    storyId: j['storyId']! as String,
    variant: j['variant'] as String? ?? 'standard',
    level: j['level'] as String?,
    // a weight story's bars lie across (LES-04, CON-11)
    quantity: story['quantity'] as String? ?? 'height',
    steps: _steps(j['steps']),
  );
}

/// `problem.steps[]` (LES-03, LES-12): the server's order and options for
/// this problem; null when it sent none (an older server), so the
/// template's are used. A step or option missing its id is left out.
List<ServedStep>? _steps(Object? raw) {
  if (raw is! List || raw.isEmpty) return null;
  return [
    for (final st in raw)
      if (st is Map && st['id'] is String)
        ServedStep(
          id: st['id']! as String,
          optional: st['optional'] == true,
          hintStartRung: st['hintStartRung'] as String?,
          options: [
            for (final o in st['options'] as List? ?? const [])
              if (o is Map && o['id'] is String && o['text'] is String)
                ServedOption(
                  id: o['id']! as String,
                  text: o['text']! as String,
                  correct: o['correct'] == true,
                ),
          ],
        ),
  ];
}

/// The question as the voice reads it: "186 cm" as "186 centimetres".
String spokenUnits(String text) => text.replaceAllMapped(
  RegExp(r'(\d) ?(cm|kg|m|g)\b'),
  (m) => '${m[1]} ${_units[m[2]]}',
);

const _units = {
  'cm': 'centimetres',
  'm': 'metres',
  'kg': 'kilograms',
  'g': 'grams',
};

/// A case left last time, from its `problem_shown` payload (ids and numbers
/// only), drawn from [template] the way the first phone drew it. Null when
/// this phone's template is another one or another version: then the case
/// isn't offered back.
ComparisonProblem? problemFromShown(
  Map<String, Object?> shown,
  ComparisonTemplate template,
) {
  if (shown['template_id'] != template.id ||
      shown['template_version'] != template.version) {
    return null;
  }
  final numbers = shown['numbers'];
  // a total-and-difference case ({total, difference}, CON-07) isn't one
  // this phone can draw
  if (numbers is! Map || numbers['A'] is! int || numbers['D'] is! int) {
    return null;
  }
  final storyId = shown['story_id']! as String;
  final story = template.stories.where((s) => s.id == storyId).firstOrNull;
  final level = shown['level'] as String?;
  if (story == null || !template.levels.any((l) => l.id == level)) return null;
  return template.problem(
    level!,
    storyId,
    a: numbers['A'] as int,
    d: numbers['D'] as int,
    relation: shown['relation'] as String?,
    pics: {story.a: itemPic(story.a), story.b: itemPic(story.b)},
    next: const NextProblems(fast: '', helped: '', easier: ''),
    id: shown['problem_id']! as String,
    variant: shown['variant'] as String? ?? 'standard',
  );
}

String _pic(Map<String, Object?> story, String side) =>
    itemPic(story[side]! as String, kind: story['kind'] as String?);

// ponytail: a picture by the item's name or kind until stories carry their
// own; a story the list doesn't know shows the plain magnifier.
String itemPic(String name, {String? kind}) {
  for (final MapEntry(:key, :value) in _pics.entries) {
    if (name.toLowerCase().contains(key)) return value;
  }
  return _pics[kind] ?? '🔍';
}

const _pics = {
  'lemon': '🍋',
  'mango': '🥭',
  'apple': '🍎',
  'orange': '🍊',
  'banana': '🍌',
  'pear': '🍐',
  'cherry': '🍒',
  'peach': '🍑',
  'coconut': '🥥',
  'palm': '🌴',
  'pine': '🌲',
  'tree': '🌳',
  'building': '🏢',
  'tower': '🗼',
  'house': '🏠',
  'bowl': '🥣',
  'mug': '☕',
  'cup': '🥤',
};
