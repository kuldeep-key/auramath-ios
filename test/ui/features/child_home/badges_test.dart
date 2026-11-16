import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/child_home/views/badge_screen.dart';
import 'package:auramath/ui/features/child_home/views/badges_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lesson/fakes.dart';
import 'helpers.dart';

void main() {
  final badges = samplePack().badges;

  testWidgets('B1 fits every size, with badges and with none', (tester) async {
    await shots(
      tester,
      'child_home_badges',
      BadgesScreen(earned: const ['tree'], badges: badges),
    );
    await shots(
      tester,
      'child_home_badges_none',
      BadgesScreen(earned: const [], badges: badges),
    );
  });

  testWidgets('REW-12: the cabinet shows earned badges only: no outlines, '
      'no next to earn, no count', (tester) async {
    await show(tester, BadgesScreen(earned: const ['tree'], badges: badges));
    expect(find.text('Tree Detective'), findsOneWidget);
    expect(find.text('NEXT TO EARN'), findsNothing);
    expect(find.text('Brave Asker'), findsNothing);
    expect(find.textContaining(' of '), findsNothing);
    expect(find.textContaining('%'), findsNothing);

    await show(tester, BadgesScreen(earned: const [], badges: badges));
    expect(find.text('Your badges will live here.'), findsOneWidget);
  });

  testWidgets('REW-12: tapping a badge says so (badge_opened)', (tester) async {
    final opened = <String>[];
    await show(
      tester,
      BadgesScreen(earned: const ['tree'], badges: badges, onOpen: opened.add),
    );
    await tapAndSettle(tester, find.text('Tree Detective'));
    expect(opened, ['tree']);
  });

  testWidgets('tapping an earned badge opens it; home goes home', (
    tester,
  ) async {
    await show(tester, BadgesScreen(earned: const ['tree'], badges: badges));
    await tapAndSettle(tester, find.text('Tree Detective'));
    expect(find.text('went to ${Paths.badge('tree')}'), findsOneWidget);

    await show(tester, BadgesScreen(earned: const ['tree'], badges: badges));
    await tapAndSettle(tester, find.byTooltip('Home'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('B2 fits every size and goes back to the badges', (tester) async {
    final screen = BadgeScreen(id: 'tree', badge: badges['tree']!);
    await shots(tester, 'child_home_badge', screen);
    await show(tester, screen);
    expect(find.text('Cracked a tree case by drawing it.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Back to my badges'));
    expect(find.text('went to ${Paths.badges}'), findsOneWidget);
  });
}
