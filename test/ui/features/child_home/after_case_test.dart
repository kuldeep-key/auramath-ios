import 'package:auramath/data/repositories/progress_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/child_home/views/after_case_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lesson/fakes.dart';
import 'helpers.dart';

void main() {
  final problems = samplePack().problems;

  AfterCase after({
    String solved = 'lemon',
    String next = 'shorter',
    String? sentBadge,
    bool streak = false,
    TrailStop? opened,
  }) => (
    solved: problems[solved],
    next: problems[next]!,
    sentBadge: sentBadge,
    streak: streak,
    opened: opened,
  );

  testWidgets('each moment fits every size', (tester) async {
    await shots(
      tester,
      'child_home_after_sent',
      AfterCaseScreen(after: after(sentBadge: 'tree')),
    );
    await shots(
      tester,
      'child_home_after_streak',
      AfterCaseScreen(after: after(streak: true)),
    );
    await shots(
      tester,
      'child_home_after_up',
      AfterCaseScreen(after: after(opened: TrailStop.trickyWords)),
    );
    await shots(
      tester,
      'child_home_after_closed',
      AfterCaseScreen(after: after()),
    );
  });

  testWidgets('Y4, Streak and Up come first, in that order, then X1', (
    tester,
  ) async {
    await show(
      tester,
      AfterCaseScreen(
        after: after(
          sentBadge: 'tree',
          streak: true,
          opened: TrailStop.trickyWords,
        ),
      ),
    );
    expect(find.text('My sash'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next case'));
    expect(find.text('On a roll!'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next'));
    expect(
      find.text('A new stop opened on your trail: Tricky word cases.'),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.text('See my trail'));
    expect(find.text('went to ${Paths.trail}'), findsOneWidget);
  });

  testWidgets('with nothing to add, X1 shows the next case at once', (
    tester,
  ) async {
    await show(tester, AfterCaseScreen(after: after()));
    expect(find.text('Ready for a trickier one?'), findsOneWidget);
    expect(find.text('Tree Word Problem'), findsOneWidget);
    expect(find.text('Same trees. Watch the words!'), findsOneWidget);
    expect(find.text('My sash'), findsNothing);
  });

  testWidgets('X1: a harder level of the same words is just trickier', (
    tester,
  ) async {
    await show(
      tester,
      AfterCaseScreen(
        after: after(solved: 'easier', next: 'lemon'),
      ),
    );
    expect(find.text('Ready for a trickier one?'), findsOneWidget);
    expect(find.text('Same trees. Watch the words!'), findsNothing);
  });

  testWidgets('X1 for a case at the same or an easier level', (tester) async {
    await show(tester, AfterCaseScreen(after: after(next: 'easier')));
    expect(find.text('Ready for a new case?'), findsOneWidget);
    expect(find.text('Same trees. Watch the words!'), findsNothing);
  });

  testWidgets("Let's go opens a fresh lesson on the next case", (tester) async {
    await show(tester, AfterCaseScreen(after: after()));
    await tapAndSettle(tester, find.text("Let's go"));
    expect(
      find.textContaining(
        RegExp('^went to ${Paths.lesson('shorter')}\\?s=[0-9a-f-]{36}\$'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Done for today and Y4 Home go home', (tester) async {
    await show(tester, AfterCaseScreen(after: after()));
    await tapAndSettle(tester, find.text('Done for today'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);

    await show(tester, AfterCaseScreen(after: after(sentBadge: 'tree')));
    await tapAndSettle(tester, find.text('Home'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });
}
