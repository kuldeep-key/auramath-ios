import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/family_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/invite_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/new_code_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/remove_phone_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'gu_fakes.dart';

void main() {
  group('Family', () {
    Widget screen(Gu g) => FamilyScreen(family: g.deps.family, repo: g.repo);

    testWidgets('at every size: grown-ups, children, phones', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_family', screen(g));
      expect(find.text('priya@gmail.com (you)'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('raj@example.com'), findsOneWidget);
      expect(find.text('Invited'), findsOneWidget);
      expect(find.text('Year 2'), findsOneWidget);
      expect(find.text("Aarav's iPhone"), findsOneWidget);
    });

    testWidgets('Remove opens the confirmation for that phone', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(
        find.text('went to ${Paths.removePhone('dev-1')}'),
        findsOneWidget,
      );
    });

    testWidgets('no phones yet says so', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/devices', {'devices': <Object>[]});
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('No phones joined yet'), findsOneWidget);
    });
  });

  group('Invite', () {
    testWidgets('at every size', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(
        tester,
        'grown_ups_invite',
        InviteScreen(repo: g.repo),
      );
      expect(find.text('Their email'), findsOneWidget);
    });

    testWidgets('sends the invitation, then says it went', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('POST /api/parent/invites', {'invite': {}}, status: 201);
      await tester.pumpWidget(shotApp(InviteScreen(repo: g.repo)));
      await tester.enterText(find.byType(TextField), 'raj@example.com');
      await tester.tap(find.text('Send invite'));
      await tester.pumpAndSettle();
      expect(g.bodyOf('POST /api/parent/invites'), {
        'email': 'raj@example.com',
      });
      expect(find.text('Invite sent'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.family}'), findsOneWidget);
    });

    testWidgets("the server's refusal shows under the field", (tester) async {
      final g = await Gu.make(tester);
      g.server.on('POST /api/parent/invites', {
        'error': 'that grown-up is already in this family',
      }, status: 409);
      await tester.pumpWidget(shotApp(InviteScreen(repo: g.repo)));
      await tester.enterText(find.byType(TextField), 'priya@gmail.com');
      await tester.tap(find.text('Send invite'));
      await tester.pumpAndSettle();
      expect(
        find.text('that grown-up is already in this family'),
        findsOneWidget,
      );
      expect(find.text('Invite sent'), findsNothing);
    });

    testWidgets('a non-address is caught before sending', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(InviteScreen(repo: g.repo)));
      await tester.enterText(find.byType(TextField), 'raj');
      await tester.tap(find.text('Send invite'));
      await tester.pumpAndSettle();
      expect(
        find.text("That doesn't look like an email address."),
        findsOneWidget,
      );
      expect(g.calls, isNot(contains('POST /api/parent/invites')));
    });
  });

  group('NewCode', () {
    void codeFor(Gu g, Duration life) =>
        g.server.on('POST /api/devices/pairing', {
          'code': '913204',
          'expiresAt': DateTime.now().add(life).millisecondsSinceEpoch,
        });

    testWidgets('at every size', (tester) async {
      final g = await Gu.make(tester);
      codeFor(g, const Duration(minutes: 10));
      await shotAllSizes(
        tester,
        'grown_ups_new_code',
        NewCodeScreen(family: g.deps.family, repo: g.repo),
      );
      expect(find.textContaining('left.'), findsOneWidget);
      expect(find.text("Type it on your child's phone"), findsOneWidget);
    });

    testWidgets('once expired, it says so and gets a new one', (tester) async {
      final g = await Gu.make(tester);
      codeFor(g, const Duration(minutes: 10));
      var now = DateTime.now();
      await tester.pumpWidget(
        shotApp(
          NewCodeScreen(family: g.deps.family, repo: g.repo, now: () => now),
        ),
      );
      await tester.pumpAndSettle();
      now = now.add(const Duration(minutes: 11));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('This code has stopped working.'), findsOneWidget);
      await tester.tap(find.text('Get a new code'));
      await tester.pumpAndSettle();
      expect(
        g.calls.where((c) => c == 'POST /api/devices/pairing'),
        hasLength(2),
      );
      expect(find.text('Here is a new code'), findsOneWidget);
    });
  });

  group('RemovePhone and Phone removed', () {
    Widget screen(Gu g) => RemovePhoneScreen(deviceId: 'dev-1', repo: g.repo);

    testWidgets('at every size', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_remove_phone', screen(g));
      expect(find.text("Remove Aarav's iPhone?"), findsOneWidget);
      await shotAllSizes(
        tester,
        'grown_ups_phone_removed',
        const PhoneRemovedScreen(),
      );
      expect(find.text('Phone removed'), findsOneWidget);
    });

    testWidgets('Remove phone deletes it and confirms', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('DELETE /api/devices/dev-1', null, status: 204);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove phone'));
      await tester.pumpAndSettle();
      expect(g.calls, contains('DELETE /api/devices/dev-1'));
      expect(find.text('went to ${Paths.phoneRemoved}'), findsOneWidget);
    });

    testWidgets('a failed remove stays and says why', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('DELETE /api/devices/dev-1', {
        'error': 'no such device',
      }, status: 404);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove phone'));
      await tester.pumpAndSettle();
      expect(find.text('no such device'), findsOneWidget);
      expect(find.textContaining('went to'), findsNothing);
    });

    testWidgets('Cancel goes back without a call', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.family}'), findsOneWidget);
      expect(g.calls, isNot(contains('DELETE /api/devices/dev-1')));
    });

    testWidgets('a phone already gone says so', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(
        shotApp(RemovePhoneScreen(deviceId: 'gone', repo: g.repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text("That phone isn't in your family any more."),
        findsOneWidget,
      );
    });

    testWidgets('Done goes to Family', (tester) async {
      await tester.pumpWidget(shotApp(const PhoneRemovedScreen()));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.family}'), findsOneWidget);
    });
  });
}
