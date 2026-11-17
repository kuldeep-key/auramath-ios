import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/core/parts/journey_art.dart';
import 'package:auramath/ui/core/parts/ribbon.dart';
import 'package:auramath/ui/features/child_home/views/home_screen.dart';
import 'package:auramath/ui/features/child_home/views/journey_screens.dart';
import 'package:auramath/ui/features/child_home/views/loaded.dart';
import 'package:auramath/ui/features/child_home/views/welcome_back_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'helpers.dart';

/// The first run and Home as the prototype draws them (Endless Orchard
/// path, 16 Nov): the pickers' tiles, Me's rows, Home's ribbon greeting,
/// WelcomeBack's tutor and the child's error screen.
void main() {
  Widget picker({String? current, ValueChanged<String>? onHear}) =>
      JourneyPicker(
        prompt: 'Pick your detective',
        firstRun: true,
        surprise: true,
        current: current,
        chooseLabel: 'This is me!',
        onHear: onHear,
        choices: [
          for (var i = 1; i <= 8; i++)
            (
              id: 'look_0$i',
              label: 'Look $i',
              art: LookPortrait(lookId: 'look_0$i', size: 130),
            ),
        ],
        onChoose: (_) async {},
      );

  double scaleOf(WidgetTester tester, String id) => tester
      .widget<AnimatedScale>(
        find.descendant(
          of: find.byKey(Key('choice-$id')),
          matching: find.byType(AnimatedScale),
        ),
      )
      .scale;

  testWidgets('LookPick: two tiles to a row, This is me! and a Surprise me '
      'link; the tile tapped turns yellow and grows to 1.04', (tester) async {
    await show(tester, picker());
    final one = tester.getTopLeft(find.byKey(const Key('choice-look_01')));
    final two = tester.getTopLeft(find.byKey(const Key('choice-look_02')));
    final three = tester.getTopLeft(find.byKey(const Key('choice-look_03')));
    expect(one.dy, two.dy);
    expect(three.dy, greaterThan(one.dy));
    expect(find.text('This is me!'), findsOneWidget);
    expect(find.text('Surprise me'), findsOneWidget);
    expect(find.byIcon(Icons.casino_rounded), findsOneWidget);
    expect(find.text('Hear hello'), findsNothing);

    await tapAndSettle(tester, find.byKey(const Key('choice-look_02')));
    expect(scaleOf(tester, 'look_02'), 1.04);
    expect(scaleOf(tester, 'look_01'), 1);
    final tile = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('choice-look_02')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(tile.duration, const Duration(milliseconds: 200));
  });

  testWidgets('LookPick: the tiles pop in 400 ms each, 50 ms apart', (
    tester,
  ) async {
    AuraMotion.still = false;
    addTearDown(() => AuraMotion.still = true);
    tester.view.physicalSize = shotSizes['iphone15']! * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    double opacity(int i) => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(Key('choice-look_0$i')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    await tester.pumpWidget(shotApp(picker()));
    await tester.pump();
    expect(opacity(1), lessThan(0.05));
    await tester.pump(const Duration(milliseconds: 200));
    // CSS `pop .4s both`: the default ease, so 0.80 at half time
    expect(opacity(1), closeTo(Curves.ease.transform(.5), 0.03));
    expect(opacity(8), 0); // its 350 ms delay is still running
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(1), 1);
    // the eighth starts once its delay is up, and takes its own 400 ms
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(opacity(8), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity(8), 1);
    // the backdrop's loops run on: leave without settling
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TutorPick: tapping a tutor plays its hello', (tester) async {
    final heard = <String>[];
    await show(tester, picker(onHear: heard.add));
    await tapAndSettle(tester, find.byKey(const Key('choice-look_03')));
    expect(heard, ['look_03']);
  });

  testWidgets('Me: Home, the title, the look and name, and a row for each '
      'choice with what it does', (tester) async {
    await show(
      tester,
      const MeScreen(
        name: 'Aarav',
        lookId: 'look_02',
        tutorId: 'teacher_1',
        tutorKind: 'grown_up_teacher',
        world: 'detective',
        showWorld: false,
      ),
    );
    expect(find.text('Me'), findsOneWidget);
    expect(find.text('Aarav'), findsOneWidget);
    expect(find.byType(MeRow), findsNWidgets(3));
    expect(find.text('Change how you look'), findsOneWidget);
    expect(find.text('Pick who teaches you'), findsOneWidget);
    await tapAndSettle(tester, find.byIcon(Icons.home_rounded));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets("Home: the tutor large and its greeting on the ribbon, no "
      'second line', (tester) async {
    await show(
      tester,
      const HomeScreen(
        name: 'Aarav',
        grownUps: Paths.kids,
        lookId: 'look_02',
        tutorId: 'teacher_1',
        greeting: 'Your case is waiting.',
      ),
    );
    expect(
      tester.widget<Ribbon>(find.byType(Ribbon)).text,
      'Your case is waiting.',
    );
    expect(find.text('Ready for a new case?'), findsNothing);
    expect(tester.widget<TutorFigure>(find.byType(TutorFigure)).size, 220);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  testWidgets('Home: a greeting the pack does not serve (not approved yet) '
      'leaves the tutor large and the ribbon with our own words', (
    tester,
  ) async {
    await show(
      tester,
      const HomeScreen(
        name: 'Aarav',
        grownUps: Paths.kids,
        lookId: 'look_02',
        tutorId: 'teacher_1',
      ),
    );
    expect(
      tester.widget<Ribbon>(find.byType(Ribbon)).text,
      'Ready for a new case?',
    );
    expect(tester.widget<TutorFigure>(find.byType(TutorFigure)).size, 220);
  });

  testWidgets("WelcomeBack: the tutor talking, Home on the right, Let's go", (
    tester,
  ) async {
    await show(
      tester,
      const WelcomeBackScreen(
        name: 'Aarav',
        caseWaiting: false,
        figure: TutorFigure(
          tutorId: 'teacher_1',
          size: 180,
          state: TutorState.talking,
        ),
      ),
    );
    expect(find.byType(TutorFigure), findsOneWidget);
    expect(find.text('Welcome back, Aarav!'), findsOneWidget);
    expect(find.text('Ready for a case?'), findsOneWidget);
    expect(find.text("Let's go"), findsOneWidget);
    final home = tester.getCenter(find.byIcon(Icons.home_rounded));
    expect(home.dx, greaterThan(390 / 2));
  });

  testWidgets('ErrChild: a failed read says nothing technical, tries again, '
      'and offers the way home', (tester) async {
    var reads = 0;
    await show(
      tester,
      Loaded<int>(
        load: () async {
          reads++;
          // as a network read fails: later, not at once
          await Future<void>.delayed(const Duration(milliseconds: 10));
          throw Exception('socket closed 503');
        },
        builder: (_) => const SizedBox(),
      ),
    );
    expect(find.text("That didn't work"), findsOneWidget);
    expect(find.text("Let's have another go."), findsOneWidget);
    expect(find.textContaining('503'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    await tapAndSettle(tester, find.text('Have another go'));
    expect(reads, 2);
    await tapAndSettle(tester, find.text('Go home'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });
}
