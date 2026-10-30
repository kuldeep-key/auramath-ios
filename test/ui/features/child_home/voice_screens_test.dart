import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/child_home/views/voice_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

void main() {
  testWidgets('Sound and NoVoice fit every size', (tester) async {
    await shots(tester, 'child_home_sound', const SoundScreen());
    await shots(tester, 'child_home_no_voice', const NoVoiceScreen());
  });

  testWidgets('opened over the lesson, each pops with its choice', (
    tester,
  ) async {
    final answers = <String?>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => TextButton(
            onPressed: () async =>
                answers.add(await context.push<String>(Paths.sound)),
            child: const Text('lesson'),
          ),
        ),
        GoRoute(path: Paths.sound, builder: (_, _) => const SoundScreen()),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tapAndSettle(tester, find.text('lesson'));
    await tapAndSettle(tester, find.text('Sound is on now'));
    await tapAndSettle(tester, find.text('lesson'));
    await tapAndSettle(tester, find.text("I'll read"));
    expect(answers, ['sound_on', 'read_myself']);
  });

  testWidgets('with nothing underneath, they go home', (tester) async {
    await show(tester, const SoundScreen());
    await tapAndSettle(tester, find.text("I'll read"));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);

    await show(tester, const NoVoiceScreen());
    expect(find.text('My voice is resting'), findsOneWidget);
    await tapAndSettle(tester, find.text("OK, let's go"));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });
}
