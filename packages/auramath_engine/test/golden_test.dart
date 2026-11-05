import 'dart:convert';
import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The cases the golden files are written from. Run with UPDATE_GOLDEN=1 to
/// rewrite `test/golden/*.json`, then review every changed `expect` by hand.
const _toFindB = <LessonInput>[
  Started(),
  BarADrawn(),
  BarBPlaced(),
  BarBSized(Relation.shorter),
  PieceDropped(Piece.gap, Target.gapSlot),
  PieceDropped(Piece.total, Target.totalSlot),
  OpChosen(Op.subtract),
];

const cases = <(String, String, List<LessonInput>)>[
  (
    'lemon_clean',
    'lemon',
    [..._toFindB, NumberEntered(79), NumberEntered(265)],
  ),
  (
    'lemon_regrouping_81',
    'lemon',
    [..._toFindB, NumberEntered(81), SideLessonDone(), NumberEntered(79)],
  ),
  (
    'lemon_carry_255',
    'lemon',
    [..._toFindB, NumberEntered(79), NumberEntered(255)],
  ),
  ('lemon_know_265', 'lemon', [Started(), KnowIt(265)]),
  ('lemon_know_near_268', 'lemon', [Started(), KnowIt(268)]),
  (
    'lemon_two_wrong_moves',
    'lemon',
    [
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.taller),
      BarBSized(Relation.taller),
    ],
  ),
  (
    'lemon_quiet',
    'lemon',
    [
      Started(),
      QuietFor(15000),
      QuietFor(25000),
      QuietFor(40000),
      QuietFor(60000),
    ],
  ),
  ('easier_know_122', 'easier', [Started(), KnowIt(122)]),
];

final _dir = Directory('test/golden');

Map<String, Object?> _expect(String problemId, List<LessonInput> inputs) {
  final p = pack.problems[problemId]!;
  var s = initialState();
  final decisions = <Map<String, Object?>>[];
  for (final i in inputs) {
    final r = step(pack, p, s, i);
    s = r.state;
    decisions.addAll(r.decisions.map(decisionToJson));
  }
  return {'step': s.step.name, 'decisions': decisions};
}

void main() {
  if (Platform.environment['UPDATE_GOLDEN'] == '1') {
    _dir.createSync(recursive: true);
    for (final (name, problemId, inputs) in cases) {
      final vector = {
        'name': name,
        'pack': packJson(),
        'problemId': problemId,
        'inputs': inputs.map(inputToJson).toList(),
        'expect': _expect(problemId, inputs),
      };
      final json = const JsonEncoder.withIndent('  ').convert(vector);
      File('${_dir.path}/$name.json').writeAsStringSync('$json\n');
    }
  }

  test('there is one golden file per case', () {
    final names = _dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toSet();
    expect(names, {for (final (n, _, _) in cases) '$n.json'});
  });

  for (final (name, _, _) in cases) {
    test('golden $name', () {
      final v =
          jsonDecode(File('${_dir.path}/$name.json').readAsStringSync())
              as Map<String, Object?>;
      final pk = Pack.fromJson(v['pack'] as Map<String, Object?>);
      final p = pk.problems[v['problemId']]!;
      var s = initialState();
      final decisions = <Map<String, Object?>>[];
      for (final j in v['inputs'] as List) {
        final r = step(pk, p, s, inputFromJson(j as Map<String, Object?>));
        s = r.state;
        decisions.addAll(r.decisions.map(decisionToJson));
      }
      final want = v['expect'] as Map<String, Object?>;
      expect(s.step.name, want['step']);
      expect(decisions, want['decisions']);
    });
  }
}
