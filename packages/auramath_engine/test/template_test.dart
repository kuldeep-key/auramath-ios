import 'dart:io';
import 'dart:math';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Julia's files, as the app bundles them (copied from spec pack v0.3.0).
final template = ComparisonTemplate.fromYaml(
  File('../../assets/spec/comparison-two-step.yaml').readAsStringSync(),
);
final policy = Policy.fromYaml(
  File('../../assets/spec/policy.yaml').readAsStringSync(),
);

const pics = {
  'lemon tree': '🍋',
  'fig tree': '🌳',
  'mango tree': '🥭',
  'guava tree': '🍐',
  'Building A': '🏢',
  'Building B': '🏬',
  'bowl': '🥣',
  'mug': '☕',
};
const next = NextProblems(fast: 'f', helped: 'h', easier: 'e');

bool regroupsSub(int x, int y) {
  for (; y > 0; x ~/= 10, y ~/= 10) {
    if (x % 10 < y % 10) return true;
  }
  return false;
}

bool regroupsAdd(int x, int y) {
  for (; x > 0 || y > 0; x ~/= 10, y ~/= 10) {
    if (x % 10 + y % 10 >= 10) return true;
  }
  return false;
}

void main() {
  test("policy question_buttons and Julia's line library (TUT-13)", () {
    expect(policy.questionButtons['*'], ['line.q.what-now']);
    expect(policy.questionButtons['size_second_bar'], ['line.q.taller-means']);
    expect(policy.lines['line.check.again'], 'Check your sum again.');
    expect(policy.lines['line.q.what-now'], startsWith('What do I do now? | '));
  });

  test('app-config: the AI timings and the offline clock (NFR-05, SES-04)', () {
    final c = AppConfig.fromYaml(
      File('../../assets/spec/app-config.yaml').readAsStringSync(),
    );
    expect(c.cueAfterMs, 1000);
    expect(c.fallbackAfterMs, 4000);
    expect(c.clockPausesWhileOffline, isTrue);
    // acted on only when switched on
    expect(c.flags['ai_decisions'], isFalse);
    expect(c.flags['self_rating_min_age'], 7);
    // a pack without the v4 keys keeps the spec's numbers
    final old = AppConfig.fromYaml('session: {cap_minutes: 30}');
    expect((old.cueAfterMs, old.fallbackAfterMs), (1000, 4000));
  });

  test('the template reads its five levels and its stories', () {
    expect(template.id, 'cmp.comparison');
    expect(template.version, '0.3.0');
    expect(template.levels.map((l) => l.id), ['L1', 'L2', 'L3', 'L4', 'L5']);
    final l4 = template.level('L4');
    expect((l4.aMin, l4.aMax, l4.dMin, l4.dMax), (100, 499, 11, 399));
    expect(l4.twoStep, isTrue);
    expect(template.level('L1').twoStep, isFalse);
    expect(template.level('L5').relations, ['shorter']);
    expect(template.stories.map((s) => s.id), contains('lemon-fig'));
  });

  test('every level generates valid problems from any seed', () {
    for (final level in template.levels) {
      for (var seed = 0; seed < 200; seed++) {
        final p = template.generate(
          level.id,
          'lemon-fig',
          Random(seed),
          pics: pics,
          next: next,
        );
        final a = p.aValue, d = p.diff, b = p.bValue;
        final why = '${level.id} seed $seed: A=$a D=$d';
        expect(a, inInclusiveRange(level.aMin, level.aMax), reason: why);
        expect(d, inInclusiveRange(level.dMin, level.dMax), reason: why);
        expect(d, lessThan(a), reason: why);
        expect(b, isNot(d), reason: why);
        expect(hasCollision(p), isFalse, reason: why);
        expect(p.ask, level.twoStep ? Ask.total : Ask.b, reason: why);
        expect(p.level, level.id);
        if (level.twoStep) expect(a + b, lessThanOrEqualTo(999), reason: why);
        final shorter = level.relations.single == 'shorter';
        expect(p.big, shorter ? BigSide.b : BigSide.a, reason: why);
        final findB = shorter ? regroupsAdd(a, d) : regroupsSub(a, d);
        final total = level.twoStep && regroupsAdd(a, b);
        if (level.constraints.contains('no_regrouping')) {
          expect(findB || total, isFalse, reason: why);
        }
        if (level.constraints.contains('regrouping')) {
          expect(findB, isTrue, reason: why);
        }
      }
    }
  });

  test("Julia's lemon tree, rendered from the template", () {
    final p = template.problem(
      'L4',
      'lemon-fig',
      a: 186,
      d: 107,
      pics: pics,
      next: next,
    );
    expect(
      p.text,
      'The lemon tree is 186 cm tall. It is 107 cm taller than the fig tree. '
      'What is the total height of the two trees?',
    );
    expect(p.say, contains('186 centimetres'));
    expect(p.a.name, 'Lemon tree');
    expect(p.a.pic, '🍋');
    expect((p.bValue, p.total), (79, 265));
    expect(p.storyId, 'lemon-fig');
  });

  test('one-step levels ask only for the missing height', () {
    final p = template.problem(
      'L1',
      'lemon-fig',
      a: 18,
      d: 6,
      pics: pics,
      next: next,
    );
    expect(
      p.text,
      'The lemon tree is 18 cm tall. It is 6 cm taller than the fig tree. '
      'How tall is the fig tree?',
    );
    expect(p.ask, Ask.b);
  });

  test('the same seed always gives the same problem', () {
    ComparisonProblem make() => template.generate(
      'L4',
      'mango-guava',
      Random(7),
      pics: pics,
      next: next,
    );
    expect(make().id, make().id);
  });

  test('the policy gives the quiet timers and the side-lesson limit', () {
    expect(
      (
        policy.timers.pulseMs,
        policy.timers.glowMs,
        policy.timers.handMs,
        policy.timers.stillMs,
      ),
      (15000, 25000, 40000, 60000),
    );
    expect(policy.maxSideLessons, 2);
  });

  test("the side-lesson limit is the policy's: past it, the step's usual "
      'help instead', () {
    const toFindB = <LessonInput>[
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.shorter),
      PieceDropped(Piece.gap, Target.gapSlot),
      PieceDropped(Piece.total, Target.totalSlot),
      OpChosen(Op.subtract),
      NumberEntered(81), // a regrouping slip
    ];
    LessonStep after(Pack p) => replay(p, lemon, toFindB).step;
    expect(
      after(pack.copyWith(maxSideLessons: policy.maxSideLessons)),
      LessonStep.sideLesson,
    );
    expect(after(pack.copyWith(maxSideLessons: 0)), LessonStep.findB);
  });
}
