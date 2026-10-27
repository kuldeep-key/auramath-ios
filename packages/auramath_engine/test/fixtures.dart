import 'package:auramath_engine/auramath_engine.dart';

Map<String, Object?> problemJson(
  String id, {
  required int a,
  required int diff,
  String big = 'a',
  String ask = 'total',
}) => {
  'id': id,
  'a': {'name': 'Lemon tree', 'pic': '🍋', 'value': a},
  'b': {'name': 'Fig tree', 'pic': '🌳'},
  'diff': diff,
  'big': big,
  'unit': 'cm',
  'ask': ask,
  'text': 'text',
  'say': 'say',
  'next': {'fast': 'shorter', 'helped': 'mango', 'easier': 'easier'},
};

final lemon = ComparisonProblem.fromJson(problemJson('lemon', a: 186, diff: 107));
final shorter = ComparisonProblem.fromJson(
  problemJson('shorter', a: 186, diff: 107, big: 'b'),
);
final mango = ComparisonProblem.fromJson(problemJson('mango', a: 152, diff: 68));
final easier = ComparisonProblem.fromJson(
  problemJson('easier', a: 254, diff: 132, ask: 'b'),
);

Map<String, Object?> packJson() => {
  'version': 'test-1',
  'timers': {
    'pulseMs': 15000,
    'glowMs': 25000,
    'handMs': 40000,
    'stillMs': 60000,
  },
  'hints': ['cmp.hint1', 'cmp.hint2', 'cmp.hint3'],
  'badges': {
    'tree': {'name': 'Tree Detective', 'says': 'Cracked a tree case by drawing it.'},
    'asker': {'name': 'Brave Asker', 'says': 'Asked for help and kept going.'},
  },
  'lines': {'cmp.right': 'Yes! {v} {u}!'},
  'problems': [
    problemJson('lemon', a: 186, diff: 107),
    problemJson('shorter', a: 186, diff: 107, big: 'b'),
    problemJson('mango', a: 152, diff: 68),
    problemJson('easier', a: 254, diff: 132, ask: 'b'),
  ],
};

final pack = Pack.fromJson(packJson());
