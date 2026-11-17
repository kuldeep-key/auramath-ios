import 'dart:io';
import 'dart:ui' as ui;

import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/core/parts/journey_art.dart';
import 'package:auramath/ui/features/child_home/views/choose_today_screen.dart';
import 'package:auramath/ui/features/child_home/views/home_screen.dart';
import 'package:auramath/ui/features/child_home/views/journey_screens.dart';
import 'package:auramath/ui/features/child_home/views/loaded.dart';
import 'package:auramath/ui/features/child_home/views/meet_partner_screen.dart';
import 'package:auramath/ui/features/child_home/views/welcome_back_screen.dart';
import 'package:auramath/ui/features/pairing/views/kids_screen.dart';
import 'package:auramath/ui/features/pairing/views/open_screen.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';
import '../pairing/pairing_helpers.dart';

/// The first-run and Home screens beside the prototype's (Endless Orchard
/// path, 16 Nov): saved as `<Screen>-app.png` at the prototype's 393 x 852
/// for the side-by-side check. Set PROTO_SHOTS to the folder to write.
void main() {
  final out = Platform.environment['PROTO_SHOTS'];

  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget screen, {
    Duration at = const Duration(seconds: 2),
  }) async {
    await tester.runAsync(loadAppFonts);
    await tester.runAsync(ArtAssets.load);
    tester.view.physicalSize = const Size(393, 852) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() async {
      for (final f in [
        ...Directory('assets/proto').listSync(),
        ...Directory('assets/images').listSync(),
      ].whereType<File>().where((f) => f.path.endsWith('.jpg'))) {
        await precacheImage(AssetImage(f.path), context);
      }
    });
    await tester.pumpWidget(
      RepaintBoundary(key: const ValueKey('shot'), child: shotApp(screen)),
    );
    for (
      var t = Duration.zero;
      t < at;
      t += const Duration(milliseconds: 100)
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (out == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('shot')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name-app.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  final config = bundledJourney();

  testWidgets('Open', (tester) async {
    await shot(tester, 'Open', const OpenScreen());
  });

  testWidgets('A1', (tester) async {
    final (deps, server) = (await tester.runAsync(
      () => testDeps(stored: parentPhone),
    ))!;
    server.on('GET /api/children', familyJson(['Aarav', 'Maya']));
    await loadPortraits(tester);
    await shot(
      tester,
      'A1',
      KidsScreen(account: deps.account, family: deps.family),
    );
  });

  testWidgets('LookPick', (tester) async {
    await shot(
      tester,
      'LookPick',
      Builder(
        builder: (context) => JourneyPicker(
          prompt: 'Pick your detective',
          chooseLabel: 'This is me!',
          firstRun: true,
          surprise: true,
          current: 'look_02',
          choices: lookChoices(
            AppLocalizations.of(context)!,
            config,
            'detective',
          ),
          onChoose: (_) async {},
        ),
      ),
    );
  });

  testWidgets('TutorPick', (tester) async {
    await shot(
      tester,
      'TutorPick',
      Builder(
        builder: (context) => JourneyPicker(
          prompt: 'Pick your teacher',
          chooseLabel: 'This is my teacher!',
          aspect: 0.8,
          firstRun: true,
          surprise: true,
          current: config.pickable.first.id,
          choices: tutorChoices(
            AppLocalizations.of(context)!,
            config,
            'detective',
          ),
          onChoose: (_) async {},
        ),
      ),
    );
  });

  testWidgets('Meet', (tester) async {
    await shot(
      tester,
      'Meet',
      MeetPartnerScreen(
        served: const [],
        onSay: (_) {},
        onStart: () {},
        figure: TutorFigure(
          tutorId: config.pickable.first.id,
          size: 190,
          state: TutorState.talking,
        ),
      ),
    );
  });

  testWidgets('Home', (tester) async {
    await shot(
      tester,
      'Home',
      HomeScreen(
        name: 'Aarav',
        grownUps: Paths.kids,
        lookId: 'look_02',
        tutorId: config.pickable.first.id,
        greeting: 'Your case is waiting.',
      ),
    );
  });

  testWidgets('Me', (tester) async {
    await shot(
      tester,
      'Me',
      MeScreen(
        name: 'Aarav',
        lookId: 'look_02',
        tutorId: config.pickable.first.id,
        tutorKind: 'grown_up_teacher',
        world: 'detective',
        showWorld: false,
      ),
    );
  });

  testWidgets('WelcomeBack', (tester) async {
    await shot(
      tester,
      'WelcomeBack',
      WelcomeBackScreen(
        name: 'Aarav',
        caseWaiting: false,
        figure: TutorFigure(
          tutorId: config.pickable.first.id,
          size: 180,
          state: TutorState.talking,
        ),
      ),
    );
  });

  testWidgets('ErrChild', (tester) async {
    await shot(
      tester,
      'ErrChild',
      Loaded<int>(
        load: () async => throw Exception('offline'),
        builder: (_) => const SizedBox(),
      ),
    );
  });

  testWidgets('A3', (tester) async {
    await shot(tester, 'A3', const ChooseTodayScreen());
  });
}
