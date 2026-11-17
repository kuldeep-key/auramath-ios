import 'dart:io';
import 'dart:ui' as ui;

import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/core/parts/aura_button.dart';
import 'package:auramath/ui/core/parts/journey_art.dart';
import 'package:auramath/ui/core/parts/lesson_header.dart';
import 'package:auramath/ui/core/parts/question_strip.dart';
import 'package:auramath/ui/core/parts/speech_bubble.dart';
import 'package:auramath/ui/core/theme/app_theme.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart' show loadAppFonts;

/// The coach (the prototype's `lhead`, `coachHTML`, `wordIn`, the tutor
/// button and `speakPulse`) and the question strip.
void main() {
  Widget app(Widget child) => MaterialApp(
    theme: buildAuraTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  Widget header({ValueNotifier<bool>? speaking, String tutor = 'teacher_1'}) =>
      TutorScope(
        tutorId: tutor,
        child: Column(
          children: [
            LessonHeader(
              line: 'Now drag a bar for the fig tree.',
              onSpeak: () {},
              muted: false,
              onSound: (_) {},
              onHome: () {},
              speaking: speaking,
            ),
            const SizedBox(height: 8),
            QuestionStrip(
              chips: const [
                StripChip(label: '186', lit: true),
                StripChip(
                  label: '107 taller',
                  lit: false,
                  kind: StripChipKind.gap,
                ),
              ],
              onSeeQuestion: () {},
            ),
          ],
        ),
      );

  testWidgets('the header and strip, as the prototype draws them', (t) async {
    await t.runAsync(loadAppFonts);
    t.view.physicalSize = const Size(390, 200) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      RepaintBoundary(key: const ValueKey('shot'), child: app(header())),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tutorSpeak')), findsOneWidget);
    expect(find.text('See'), findsOneWidget);
    // the tutor button is the prototype's 60 pt; home is 56
    expect(t.getSize(find.byKey(const Key('tutorSpeak'))), const Size(60, 60));
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('shot')),
    );
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/shots/lesson_header_strip.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });

  testWidgets('the tutor talks while the line plays, and rests after', (
    t,
  ) async {
    final speaking = ValueNotifier(false);
    await t.pumpWidget(app(header(speaking: speaking)));
    TutorState state() => t.widget<TutorFigure>(find.byType(TutorFigure)).state;
    expect(state(), TutorState.idle);
    speaking.value = true;
    await t.pump();
    expect(state(), TutorState.talking);
    speaking.value = false;
    await t.pump();
    expect(state(), TutorState.idle);
  });

  testWidgets('the sound off: a speaker-off badge on the tutor', (t) async {
    addTearDown(() => AuraSound.soundOn.value = true);
    await t.pumpWidget(app(header()));
    expect(find.byKey(const Key('tutorMute')), findsNothing);
    AuraSound.soundOn.value = false;
    await t.pump();
    expect(find.byKey(const Key('tutorMute')), findsOneWidget);
  });

  testWidgets("the lesson's tutor is the child's", (t) async {
    await t.pumpWidget(app(header(tutor: 'teacher_2')));
    expect(
      t.widget<TutorFigure>(find.byType(TutorFigure)).tutorId,
      'teacher_2',
    );
  });

  testWidgets("the main buttons confirm with the prototype's blip; white "
      'ones are silent; none with the sound off', (t) async {
    final rec = RecordingSfxPlayer();
    AuraSound.player = rec;
    addTearDown(() {
      AuraSound.player = const SilentSfxPlayer();
      AuraSound.soundOn.value = true;
    });
    await t.pumpWidget(
      app(
        Column(
          children: [
            AuraButton(label: 'Go', onPressed: () {}),
            AuraButton(
              label: 'Later',
              color: AuraButtonColor.white,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    await t.tap(find.text('Go'));
    await t.tap(find.text('Later'));
    expect(rec.played, [Sfx.tap]);
    AuraSound.soundOn.value = false;
    await t.tap(find.text('Go'));
    expect(rec.played, [Sfx.tap]);
  });

  group('moving', () {
    setUp(() => AuraMotion.still = false);
    tearDown(() => AuraMotion.still = true);

    testWidgets('words come in 45 ms apart, each over 320 ms, springy', (
      t,
    ) async {
      await t.pumpWidget(app(const SpeechBubble(text: 'Now drag a bar')));
      double opacityOf(String w) => t
          .widget<Opacity>(
            find.ancestor(of: find.text(w), matching: find.byType(Opacity)),
          )
          .opacity;
      await t.pump(const Duration(milliseconds: 45));
      // "Now" is 45 ms in; "drag" just starting
      expect(
        opacityOf('Now'),
        closeTo(AuraCurves.spring.transform(45 / 320).clamp(0, 1), 0.01),
      );
      expect(opacityOf('drag'), 0);
      await t.pump(const Duration(milliseconds: 130));
      // 175 ms: "a" (third word) is 85 ms in
      expect(
        opacityOf('a'),
        closeTo(AuraCurves.spring.transform(85 / 320).clamp(0, 1), 0.01),
      );
      // the last word ends at 3 × 45 + 320 = 455 ms; then the plain line
      await t.pump(const Duration(milliseconds: 280));
      expect(find.text('Now drag a bar'), findsOneWidget);
    });

    testWidgets('while a line plays the tutor button pulses once a second', (
      t,
    ) async {
      final speaking = ValueNotifier(true);
      await t.pumpWidget(app(header(speaking: speaking)));
      BoxShadow ring() => t
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byType(TutorFigure),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == null && d.boxShadow != null)
          .boxShadow!
          .first;
      expect(ring().spreadRadius, 0);
      await t.pump(const Duration(milliseconds: 500));
      expect(ring().spreadRadius, closeTo(6, 0.01));
      await t.pump(const Duration(milliseconds: 500));
      expect(ring().spreadRadius, closeTo(0, 0.01));
      speaking.value = false;
      await t.pump();
    });
  });
}
