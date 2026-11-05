import 'package:auramath/data/repositories/progress_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/child_home/views/check_screen.dart';
import 'package:auramath/ui/features/child_home/views/trail_screen.dart';
import 'package:auramath/ui/features/child_home/views/trail_top_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('K2 fits every size', (tester) async {
    await shots(
      tester,
      'child_home_trail',
      const TrailScreen(here: TrailStop.trees),
    );
  });

  testWidgets('K2: two stops behind, here, and only the next', (tester) async {
    await show(tester, const TrailScreen(here: TrailStop.trees));
    expect(find.text('Adding to 1000'), findsOneWidget);
    expect(find.text('Taking away to 1000'), findsOneWidget);
    expect(find.text('Done'), findsNWidgets(2));
    expect(find.text('Tree cases'), findsOneWidget);
    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Tricky word cases'), findsOneWidget);
    expect(find.text('Next stop'), findsOneWidget);
    // nothing further: the child never sees how much is left
    expect(find.text('Burger cases'), findsNothing);

    await show(tester, const TrailScreen(here: TrailStop.totalAndDifference));
    expect(find.text('Next stop'), findsNothing);
    expect(find.text('Adding to 1000'), findsNothing);
  });

  testWidgets('K2 Keep going opens the next case; home goes home', (
    tester,
  ) async {
    await show(tester, const TrailScreen(here: TrailStop.trees));
    await tapAndSettle(tester, find.text('Keep going'));
    expect(find.text('went to ${Paths.lessonNext}'), findsOneWidget);

    await show(tester, const TrailScreen(here: TrailStop.trees));
    await tapAndSettle(tester, find.byTooltip('Home'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('TrailTop fits every size, without Quick sums', (tester) async {
    await shots(tester, 'child_home_trail_top', const TrailTopScreen());
    await show(tester, const TrailTopScreen());
    expect(find.text('Play Quick sums'), findsNothing);
    await tapAndSettle(tester, find.text('Home'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('Check fits every size and opens the next case', (tester) async {
    await shots(tester, 'child_home_check', const CheckScreen());
    await show(tester, const CheckScreen());
    await tapAndSettle(tester, find.text("Let's play"));
    expect(find.text('went to ${Paths.lessonNext}'), findsOneWidget);
  });
}
