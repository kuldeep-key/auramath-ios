import 'package:auramath/ui/core/parts/aura_button.dart';
import 'package:auramath/ui/core/parts/lesson_header.dart';
import 'package:auramath/ui/core/parts/question_strip.dart';
import 'package:auramath/ui/core/parts/standing_button.dart';
import 'package:auramath/ui/core/parts/ribbon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AuraButton calls onPressed once per tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(AuraButton(label: 'Keep going', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Keep going'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('AuraButton is inert when onPressed is null', (tester) async {
    await tester.pumpWidget(
      host(const AuraButton(label: 'Next', onPressed: null)),
    );
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('StandingButton shake shows the nudge, then hides it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        StandingButton(
          icon: Icons.support_rounded,
          label: 'Help me',
          onPressed: () {},
          attention: Attention.shake,
          nudge: 'Tricky one? Tap me!',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Tricky one? Tap me!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 4300));
    expect(find.text('Tricky one? Tap me!'), findsNothing);
  });

  testWidgets('StandingButton without attention shows no nudge', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        StandingButton(
          icon: Icons.lightbulb_rounded,
          label: 'I know it',
          onPressed: () {},
          nudge: 'Tricky one? Tap me!',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Tricky one? Tap me!'), findsNothing);
  });

  testWidgets('a portrait stays round in a column that stretches', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Portrait(size: 88)],
        ),
      ),
    );
    final box = find.descendant(
      of: find.byType(Portrait),
      matching: find.byType(DecoratedBox),
    );
    expect(tester.getSize(box), const Size(88, 88));
  });

  testWidgets('StandingButton fills the width it is given', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: StandingButton(
            icon: Icons.lightbulb_rounded,
            label: 'I know it',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GestureDetector).first).width, 400);
  });

  testWidgets('QuestionStrip shows chips and opens the question', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      host(
        QuestionStrip(
          chips: const [
            StripChip(label: '🍋 186', lit: true),
            StripChip(label: '107 taller', lit: false),
          ],
          onSeeQuestion: () => opened = true,
        ),
      ),
    );
    expect(find.text('🍋 186'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_rounded));
    expect(opened, isTrue);
  });

  testWidgets('LessonHeader shows the line and its buttons work', (
    tester,
  ) async {
    var spoke = 0, home = 0;
    await tester.pumpWidget(
      host(
        LessonHeader(
          line: 'Drag a bar up here.',
          onSpeak: () => spoke++,
          onHome: () => home++,
        ),
      ),
    );
    expect(find.text('Drag a bar up here.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.tap(find.byIcon(Icons.home_rounded));
    expect((spoke, home), (1, 1));
  });
}
