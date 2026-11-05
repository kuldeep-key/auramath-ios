import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/family_remove_screens.dart';
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
      expect(find.text('raj@example.com (invited)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Year 2'), findsOneWidget);
      expect(find.text("Aarav's iPhone"), findsOneWidget);
      expect(find.text('iPhone'), findsOneWidget);
      expect(find.text('This phone'), findsOneWidget);
      expect(find.text('Chrome on Mac'), findsOneWidget);
    });

    testWidgets('the owner can remove a grown-up and cancel an invite', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/parent/members', {
        'members': [
          {
            'id': null,
            'email': 'priya@gmail.com',
            'role': 'owner',
            'you': true,
          },
          {
            'id': 'mem-1',
            'email': 'raj@example.com',
            'role': 'member',
            'invitedBy': null,
            'revokedAt': null,
            'you': false,
          },
        ],
      });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      // the owner's own row has no Remove; the phone's does
      expect(find.text('Remove'), findsNWidgets(2));
      await tester.tap(find.text('Remove').first);
      await tester.pumpAndSettle();
      expect(
        find.text('went to ${Paths.removeGrownUp('mem-1')}'),
        findsOneWidget,
      );
    });

    testWidgets("an invited grown-up can't remove the others' grown-ups", (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/parent/members', {
        'members': [
          {'id': null, 'email': 'priya@gmail.com', 'role': 'owner'},
          {
            'id': 'mem-1',
            'email': 'raj@example.com',
            'role': 'member',
            'invitedBy': null,
            'you': true,
          },
          {
            'id': 'mem-2',
            'email': 'nan@example.com',
            'role': 'member',
            'invitedBy': null,
          },
        ],
      });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      // only the phone's Remove: not the owner, not themselves, not mem-2;
      // and the owner's invite stays the owner's to cancel
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Invited'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('Cancel opens the invite confirmation', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        find.text('went to ${Paths.cancelInvite('inv-1')}'),
        findsOneWidget,
      );
    });

    testWidgets('another browser signs out; this phone has no link', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(
        find.text('went to ${Paths.removeBrowser('cred-2')}'),
        findsOneWidget,
      );
    });

    testWidgets('a child opens where they are', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.learning('child-2')}'), findsOneWidget);
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

  group('Remove a grown-up, cancel an invite, sign a browser out', () {
    void withMember(Gu g) => g.server.on('GET /api/parent/members', {
      'members': [
        {'id': null, 'email': 'priya@gmail.com', 'role': 'owner', 'you': true},
        {'id': 'mem-1', 'email': 'raj@example.com', 'role': 'member'},
      ],
    });

    testWidgets('at every size', (tester) async {
      final g = await Gu.make(tester);
      withMember(g);
      await shotAllSizes(
        tester,
        'grown_ups_remove_grown_up',
        RemoveGrownUpScreen(memberId: 'mem-1', repo: g.repo),
      );
      expect(find.text('Remove raj@example.com?'), findsOneWidget);
      await shotAllSizes(
        tester,
        'grown_ups_cancel_invite',
        CancelInviteScreen(inviteId: 'inv-1', repo: g.repo),
      );
      expect(
        find.text('Cancel the invite to raj@example.com?'),
        findsOneWidget,
      );
      expect(find.text('Keep it'), findsOneWidget);
      await shotAllSizes(
        tester,
        'grown_ups_remove_browser',
        RemoveBrowserScreen(browserId: 'cred-2', repo: g.repo),
      );
      expect(find.text('Sign out Chrome on Mac?'), findsOneWidget);
    });

    testWidgets('removing a grown-up deletes them and goes back', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      withMember(g);
      g.server.on('DELETE /api/parent/members/mem-1', {'ok': true});
      await tester.pumpWidget(
        shotApp(RemoveGrownUpScreen(memberId: 'mem-1', repo: g.repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove them'));
      await tester.pumpAndSettle();
      expect(g.calls, contains('DELETE /api/parent/members/mem-1'));
      expect(find.text('went to ${Paths.family}'), findsOneWidget);
    });

    testWidgets("the server's refusal stays and says why", (tester) async {
      final g = await Gu.make(tester);
      withMember(g);
      g.server.on('DELETE /api/parent/members/mem-1', {
        'error':
            'only the first parent or whoever invited them can remove them',
      }, status: 403);
      await tester.pumpWidget(
        shotApp(RemoveGrownUpScreen(memberId: 'mem-1', repo: g.repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove them'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'only the first parent or whoever invited them can remove them',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('went to'), findsNothing);
    });

    testWidgets('cancelling an invite; Keep it changes nothing', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('DELETE /api/parent/invites/inv-1', {'ok': true});
      await tester.pumpWidget(
        shotApp(CancelInviteScreen(inviteId: 'inv-1', repo: g.repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel the invite'));
      await tester.pumpAndSettle();
      expect(g.calls, contains('DELETE /api/parent/invites/inv-1'));
      expect(find.text('went to ${Paths.family}'), findsOneWidget);
    });

    testWidgets('signing a browser out deletes its credential', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('DELETE /api/parent/browsers/cred-2', null, status: 204);
      await tester.pumpWidget(
        shotApp(RemoveBrowserScreen(browserId: 'cred-2', repo: g.repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign it out'));
      await tester.pumpAndSettle();
      expect(g.calls, contains('DELETE /api/parent/browsers/cred-2'));
      expect(find.text('went to ${Paths.family}'), findsOneWidget);
    });

    testWidgets('this phone, or one already gone, says so', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(
        shotApp(RemoveBrowserScreen(browserId: 'cred-1', repo: g.repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('That browser is already signed out.'), findsOneWidget);
      await tester.pumpWidget(
        shotApp(CancelInviteScreen(inviteId: 'gone', repo: g.repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text("That invite isn't waiting any more."), findsOneWidget);
    });
  });
}
