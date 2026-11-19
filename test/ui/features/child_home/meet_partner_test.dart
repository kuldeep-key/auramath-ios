import 'package:auramath/app.dart';
import 'package:auramath/data/repositories/partner_intro_repository.dart';
import 'package:auramath/data/services/key_store.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/core/parts/aura_button.dart';
import 'package:auramath/ui/features/child_home/views/meet_partner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import 'child_routes_test.dart' show settle;
import 'helpers.dart';

/// @AI-07: the case partner says it is a computer helper, an AI, at the
/// first meeting, with the grown-up there.
void main() {
  final said = <String>[];
  var started = 0;
  MeetPartnerScreen screen({List<String> served = const []}) =>
      MeetPartnerScreen(
        served: served,
        onSay: said.add,
        onStart: () => started++,
      );
  setUp(() {
    said.clear();
    started = 0;
  });

  testWidgets('the first meeting fits every size', (tester) async {
    await shots(tester, 'child_home_meet_partner', screen());
  });

  testWidgets('it says it is an AI that can make mistakes, that the '
      'grown-up can see the work, and asks the grown-up to stay', (
    tester,
  ) async {
    await show(tester, screen());
    expect(find.byKey(const Key('grownUpNote')), findsOneWidget);
    expect(
      find.textContaining("I'm a computer helper, an AI. I'm not a person."),
      findsOneWidget,
    );
    expect(find.textContaining('I can make mistakes'), findsOneWidget);
    expect(
      find.textContaining('Your family can see your work.'),
      findsOneWidget,
    );
    // read aloud as it opens, and again on a tap
    expect(said.single, contains('an AI'));
    await tapAndSettle(tester, find.text('Hear it again'));
    expect(said, hasLength(2));
    final start = find.ancestor(
      of: find.text("Let's start"),
      matching: find.byType(AuraButton),
    );
    expect(tester.getSize(start).height, greaterThanOrEqualTo(56));
    await tapAndSettle(tester, find.text("Let's start"));
    expect(started, 1);
  });

  testWidgets('the content bundle\'s lines replace the drafts', (tester) async {
    await show(tester, screen(served: ['Served line one.', 'Served two.']));
    expect(find.textContaining('Served line one.'), findsOneWidget);
    expect(find.textContaining('an AI'), findsNothing);
  });

  test('served lines: policy line.intro.* in order; none, or slots the '
      'app can\'t fill, leave the drafts', () {
    expect(
      PartnerIntroRepository.lines(
        {
          'line.q.what-now': 'Q | A',
          'line.intro.ai': 'I am an AI.',
          'line.intro.see': 'Your grown-up sees this.',
          // said at breaks, not in the first meeting
          'line.intro.reminder': 'Remember, I am a computer helper.',
        },
        const ['draft'],
      ),
      ['I am an AI.', 'Your grown-up sees this.'],
    );
    expect(PartnerIntroRepository.lines(const {}, const ['draft']), ['draft']);
    expect(
      PartnerIntroRepository.lines({'line.intro.x': 'Hi {name}'}, const ['d']),
      ['d'],
    );
  });

  test('met once per child', () async {
    final repo = PartnerIntroRepository(MemoryKeyStore());
    expect(await repo.met('child-1'), isFalse);
    await repo.markMet('child-1');
    expect(await repo.met('child-1'), isTrue);
    expect(await repo.met('child-2'), isFalse);
  });

  testWidgets('Keep going before the first lesson meets the partner first; '
      "after Let's start, never again for that child", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (deps, server) =
        await tester.runAsync(
          () => testDeps(
            stored: pairedChildPhone,
            flags: {...allScreensOn, 'case_partner_intro': true},
          ),
        ) ??
        (throw StateError('no deps'));
    server.on('GET /api/children', {
      'children': [
        {'id': 'child-1', 'displayName': 'Mira'},
      ],
    });
    // the server's first run: only meeting the partner is left (H7)
    server.on('GET /api/children/child-1/look', {
      'childId': 'child-1',
      'needsFirstRun': ['meet'],
    });
    server.on('POST /api/children/child-1/first-run', {
      'childId': 'child-1',
      'needsFirstRun': <String>[],
    });
    await tester.pumpWidget(
      AuraApp(deps: deps, initialLocation: Paths.lessonNext),
    );
    await settle(tester);
    expect(find.byType(MeetPartnerScreen), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text("Let's start"));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await settle(tester);
    expect(find.byType(MeetPartnerScreen), findsNothing);
    expect(
      await tester.runAsync(
        () => PartnerIntroRepository(deps.store).met('child-1'),
      ),
      isTrue,
    );
  });

  testWidgets('H7: a child who met the partner on another phone (the '
      "server's first run says so) doesn't meet it again here", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (deps, server) =
        await tester.runAsync(
          () => testDeps(
            stored: pairedChildPhone,
            flags: {...allScreensOn, 'case_partner_intro': true},
          ),
        ) ??
        (throw StateError('no deps'));
    server.on('GET /api/children', {
      'children': [
        {'id': 'child-1', 'displayName': 'Mira'},
      ],
    });
    server.on('GET /api/children/child-1/look', {
      'childId': 'child-1',
      'needsFirstRun': <String>[],
    });
    await tester.pumpWidget(
      AuraApp(deps: deps, initialLocation: Paths.lessonNext),
    );
    await settle(tester);
    expect(find.byType(MeetPartnerScreen), findsNothing);
  });
}
