import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/child_home/views/home_screen.dart';
import 'package:auramath/ui/features/child_home/views/welcome_back_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const home = HomeScreen(name: 'Mira', grownUps: Paths.kids);

  testWidgets('Home fits every size', (tester) async {
    await shots(tester, 'child_home_home', home);
  });

  testWidgets('Home shows the name, and none when unknown', (tester) async {
    await show(tester, home);
    expect(find.text('Mira'), findsOneWidget);
    expect(find.text('Ready for a new case?'), findsOneWidget);
    await show(tester, const HomeScreen(name: null, grownUps: Paths.kids));
    expect(find.text('Mira'), findsNothing);
  });

  testWidgets('Keep going opens the next case', (tester) async {
    await show(tester, home);
    await tapAndSettle(tester, find.text('Keep going'));
    expect(find.text('went to ${Paths.lessonNext}'), findsOneWidget);
  });

  testWidgets('My trail and My badges are pushed', (tester) async {
    await show(tester, home);
    await tapAndSettle(tester, find.text('My trail'));
    expect(find.text('went to ${Paths.trail}'), findsOneWidget);

    await show(tester, home);
    await tapAndSettle(tester, find.text('My badges'));
    expect(find.text('went to ${Paths.badges}'), findsOneWidget);
  });

  testWidgets('each button hides while its flag is off', (tester) async {
    await show(
      tester,
      const HomeScreen(name: 'Mira', grownUps: Paths.kids, trail: false),
    );
    expect(find.text('My trail'), findsNothing);
    expect(find.text('My badges'), findsOneWidget);
    await show(
      tester,
      const HomeScreen(
        name: 'Mira',
        grownUps: Paths.kids,
        trail: false,
        badges: false,
      ),
    );
    expect(find.text('My badges'), findsNothing);
    expect(find.text('Keep going'), findsOneWidget);
  });

  testWidgets('the lock goes where the role says', (tester) async {
    await show(tester, home);
    await tapAndSettle(tester, find.byTooltip('For grown-ups'));
    expect(find.text('went to ${Paths.kids}'), findsOneWidget);

    await show(tester, const HomeScreen(name: 'Mira', grownUps: Paths.signIn));
    await tapAndSettle(tester, find.byTooltip('For grown-ups'));
    expect(find.text('went to ${Paths.signIn}'), findsOneWidget);
  });

  testWidgets('WelcomeBack fits every size', (tester) async {
    await shots(
      tester,
      'child_home_welcome_back',
      const WelcomeBackScreen(name: 'Mira'),
    );
  });

  testWidgets('WelcomeBack greets by name and opens the case', (tester) async {
    await show(tester, const WelcomeBackScreen(name: 'Mira'));
    expect(find.text('Welcome back, Mira!'), findsOneWidget);
    await tapAndSettle(tester, find.text("Let's see"));
    expect(find.text('went to ${Paths.lessonNext}'), findsOneWidget);

    await show(tester, const WelcomeBackScreen(name: null));
    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('WelcomeBack has a way home (SES-07)', (tester) async {
    await show(tester, const WelcomeBackScreen(name: 'Mira'));
    await tapAndSettle(tester, find.byIcon(Icons.home_outlined));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('@SES-07 the last case first, then choose today\'s work', (
    tester,
  ) async {
    await shots(
      tester,
      'child_home_welcome_back_choose',
      const WelcomeBackScreen(name: 'Mira', chooseToday: true),
    );
    await show(
      tester,
      const WelcomeBackScreen(name: 'Mira', chooseToday: true),
    );
    final carry = tester.getTopLeft(find.byKey(const Key('carryOn')));
    final choose = tester.getTopLeft(find.byKey(const Key('chooseToday')));
    expect(carry.dy, lessThan(choose.dy));
    await tapAndSettle(tester, find.text("Choose today's work"));
    expect(find.text('went to ${Paths.chooseToday}'), findsOneWidget);
  });

  testWidgets('@SES-07 back on a later day with no case: Keep going', (
    tester,
  ) async {
    await show(
      tester,
      const WelcomeBackScreen(name: 'Mira', caseWaiting: false),
    );
    expect(find.text('Ready for a new case?'), findsOneWidget);
    await tapAndSettle(tester, find.text('Keep going'));
    expect(find.text('went to ${Paths.lessonNext}'), findsOneWidget);
  });
}
