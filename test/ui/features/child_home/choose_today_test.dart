import 'package:auramath/ui/core/parts/aura_button.dart';
import 'package:auramath/ui/features/child_home/views/choose_today_screen.dart';
import 'package:auramath/ui/features/child_home/views/pick_avatar_screen.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import '../../../helpers/shots.dart';
import '../lesson/fakes.dart';
import 'helpers.dart';

/// @LES-14: A3 shows exactly two choices; either starts within one tap;
/// the choice is logged as choice_selected.
void main() {
  testWidgets('two choices, the suggestion first, each one tap away', (
    tester,
  ) async {
    await shots(tester, 'child_home_choose_today', const ChooseTodayScreen());
    await tester.pumpWidget(shotApp(const ChooseTodayScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(AuraButton), findsNWidgets(2));
    final story = tester.getTopLeft(find.byKey(const Key('todayStory')));
    final quick = tester.getTopLeft(find.byKey(const Key('todayQuick')));
    expect(story.dy, lessThan(quick.dy), reason: 'the story problem first');
    await tester.tap(find.text('Quick sums'));
    await tester.pumpAndSettle();
    expect(find.textContaining('went to /quick-sums?ms='), findsOneWidget);
  });

  testWidgets('a suggested Quick sums comes first; the story is one tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      shotApp(const ChooseTodayScreen(suggestQuickSums: true)),
    );
    await tester.pumpAndSettle();
    final story = tester.getTopLeft(find.byKey(const Key('todayStory')));
    final quick = tester.getTopLeft(find.byKey(const Key('todayQuick')));
    expect(quick.dy, lessThan(story.dy));
    await tester.tap(find.text('A story problem'));
    await tester.pumpAndSettle();
    expect(find.textContaining('went to /lesson?ms='), findsOneWidget);
  });

  testWidgets('ACC-12: the avatar picker fits every size', (tester) async {
    await shots(
      tester,
      'child_home_pick_avatar',
      PickAvatarScreen(current: 'map', onSave: (_) async {}),
    );
  });

  test('the story problem chosen is logged in its session', () async {
    final (sessions, db, _) = await memorySessions();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    )..chosenToday = 1800;
    await vm.start();
    final events = await db.forSession('s1');
    expectContract(events);
    final chose = events.singleWhere((e) => e.name == 'choice_selected');
    expect(chose.payload, {
      'step_id': 'choose_today',
      'option_id': 'story_problem',
      'ms_from_step_start': 1800,
    });
    expect(
      events.indexWhere((e) => e.name == 'problem_shown'),
      lessThan(events.indexOf(chose)),
    );
    vm.dispose();
  });
}
