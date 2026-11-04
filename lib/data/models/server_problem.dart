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
    big: const {'shorter', 'lighter'}.contains(j['relation']) ? BigSide.b : BigSide.a,
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
  );
}

/// The question as the voice reads it: "186 cm" as "186 centimetres".
String spokenUnits(String text) => text.replaceAllMapped(
  RegExp(r'(\d) ?(cm|kg|m|g)\b'),
  (m) => '${m[1]} ${_units[m[2]]}',
);

const _units = {'cm': 'centimetres', 'm': 'metres', 'kg': 'kilograms', 'g': 'grams'};

// ponytail: a picture by the item's name or kind until stories carry their
// own; a story the list doesn't know shows the plain magnifier.
String _pic(Map<String, Object?> story, String side) {
  final name = story[side]! as String;
  for (final MapEntry(:key, :value) in _pics.entries) {
    if (name.toLowerCase().contains(key)) return value;
  }
  return _pics[story['kind']] ?? '🔍';
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
