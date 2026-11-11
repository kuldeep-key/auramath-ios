import 'package:auramath/ui/features/lesson/view_models/line_library.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// TUT-14: for the comparison type every step, hint rung and mistake line
/// has at least three versions, and a session never shows the same one
/// twice in a row.
void main() {
  final pack = samplePack();
  final lemon = pack.problems['lemon']!;

  const steps = [
    'cmp.drawA',
    'cmp.placeB',
    'cmp.sizeB',
    'cmp.placeGap',
    'cmp.placeTotal',
    'cmp.chooseOp',
    'cmp.findB',
    'cmp.findTotal',
  ];
  // the engine's wrong-move and route lines (lesson.dart)
  const mistakes = [
    'cmp.sizeBWrong',
    'cmp.gapWrong',
    'cmp.totalWrong',
    'cmp.opWrong',
    'cmp.opposite',
    'cmp.tryAgain',
    'cmp.addBoth',
    'cmp.recheck',
    'cmp.regrouping',
    'cmp.carry',
    'cmp.drawIt',
    'cmp.twoBars',
  ];
  final rungs = [for (final r in pack.hintLadder) r.lineId];

  test('every step, rung and mistake line has three versions or more', () {
    final lines = LineLibrary(pack);
    expect(rungs, hasLength(9));
    for (final id in [...steps, ...rungs, ...mistakes]) {
      final v = lines.versions(id);
      expect(v.toSet(), hasLength(greaterThanOrEqualTo(3)), reason: id);
      expect(v.where((t) => t.isEmpty), isEmpty, reason: id);
    }
  });

  test('the same line asked for again never shows the same version twice '
      'in a row, and the first is the library\'s own', () {
    for (final id in [...steps, ...rungs, ...mistakes]) {
      final lines = LineLibrary(pack); // a new session
      final shown = [for (var i = 0; i < 7; i++) lines.next(id, lemon)];
      expect(shown.first, lines.line(id, lemon), reason: id);
      for (var i = 1; i < shown.length; i++) {
        expect(shown[i], isNot(shown[i - 1]), reason: '$id #$i');
      }
      expect(shown.where((t) => t.contains('{')), isEmpty, reason: id);
    }
  });

  test('a pack line and the rung it stands for share their turns', () {
    final lines = LineLibrary(pack);
    final a = lines.next('cmp.sizeBWrong', lemon);
    final b = lines.next('line.hint.taller-or-shorter', lemon);
    expect(a, isNot(b));
  });
}
