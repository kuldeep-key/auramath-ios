import 'dart:io';

import 'package:auramath/ui/features/lesson/view_models/line_check.dart';
import 'package:auramath/ui/features/lesson/view_models/line_library.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// AI-05, TUT-02: every line in the app's pack.json, in every version and
/// for every sample problem, passes the backend validator's rules: no
/// number the question doesn't have, never the step's answer before the
/// child has tried, at most two sentences and one question, no banned
/// language, and within the two-line budget.
void main() {
  final pack = samplePack();
  final forbidden = Policy.fromYaml(
    File('assets/spec/policy.yaml').readAsStringSync(),
  ).forbiddenPhrases;

  /// Lines said once the child has the unknown right: they may say it.
  const afterAnswer = {'cmp.right', 'cmp.itRight', 'cmp.partRight'};

  List<String> check(String id, String raw, ComparisonProblem p) {
    final text = fillSlots(raw, {
      ...lineSlots(p),
      ...policySlots(p),
      'v': '${p.bValue}',
    });
    final after = afterAnswer.contains(id);
    return LineCheck.reasons(
      text,
      allowed: {p.aValue, p.diff, if (after) p.bValue},
      answers: {if (!after) p.bValue, p.total},
      forbidden: forbidden,
    );
  }

  test('the checks catch what the validator catches', () {
    final p = pack.problems['lemon']!;
    List<String> r(String t) => LineCheck.reasons(
      t,
      allowed: {186, 107},
      answers: {79, 265},
      forbidden: forbidden,
    );
    expect(r('Is the fig tree 107 cm shorter?'), isEmpty);
    expect(r('The fig tree is 79 cm.'), ['states-answer']);
    expect(r('Add 12 to it.'), ['answer-numeral']);
    expect(r('Great job! Well done.'), ['banned-language']);
    expect(r('Try again.'), ['banned-language']);
    expect(r('That is easy.'), ['banned-language']);
    expect(r('One. Two. Three.'), ['too-many-sentences']);
    expect(r('Which? Why?'), ['too-many-questions']);
    expect(r('a' * 81), ['too-long']);
    expect(r(''), ['empty']);
    expect(p.bValue, 79);
  });

  test("every pack line and every drafted version passes, for every "
      "sample problem", () {
    final failures = <String, List<String>>{};
    for (final p in pack.problems.values) {
      for (final MapEntry(key: id, value: raw) in pack.lines.entries) {
        final r = check(id, raw, p);
        if (r.isNotEmpty) failures['${p.id} $id'] = r;
      }
      for (final MapEntry(key: id, value: versions)
          in pack.lineVersions.entries) {
        for (final (i, v) in versions.indexed) {
          final r = check(id, v, p);
          if (r.isNotEmpty) failures['${p.id} $id #${i + 1}'] = r;
        }
      }
    }
    expect(failures, isEmpty);
  });

  test("Julia's library lines: no banned words and no answers; the ones "
      'over the budget are listed for her (CON-09)', () {
    final over = <String>{};
    for (final p in pack.problems.values) {
      for (final MapEntry(key: id, value: raw) in pack.policyLines.entries) {
        // a question button holds the question and its answer
        for (final part in raw.split(' | ')) {
          final r = check(id, part, p);
          expect(
            r.where((x) => x == 'banned-language' || x == 'states-answer'),
            isEmpty,
            reason: '$id: $part',
          );
          if (r.isNotEmpty) over.add(id);
        }
      }
    }
    // two questions in 99 characters (Julia's Figma 15.2 words), and
    // three sentences in the case partner's hello (AI-07 draft)
    expect(over, {'line.hint.longer-or-shorter-bar', 'line.intro.hello'});
  });
}
