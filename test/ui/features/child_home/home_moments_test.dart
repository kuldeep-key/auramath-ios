import 'package:auramath/data/repositories/rewards_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/child_home/views/home_moments.dart';
import 'package:auramath/ui/features/child_home/views/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import 'helpers.dart';

void main() {
  group('REW-01: one badge per session, however it stopped', () {
    Future<(HomeMomentsSource, FakeServer)> source() async {
      final (deps, server) = await testDeps();
      return (
        HomeMomentsSource(rewards: RewardsRepository(deps.client)),
        server,
      );
    }

    test('the server names it; it shows once per session', () async {
      final (m, server) = await source();
      server.on('GET /api/sessions/s1/badge', {
        'badge': {'id': 'tree', 'name': 'Tree Word Problem', 'kind': 'session'},
      });
      const stop = (sessionId: 's1', reason: 'time_up');
      final first = await m.next(lastStop: stop);
      expect(first.badge!.served!.name, 'Tree Word Problem');
      expect((await m.next(lastStop: stop)).badge, isNull);
      expect((await m.next(lastStop: null)).badge, isNull);
    });

    test('no server badge yet: still a badge, never zero', () async {
      final (m, _) = await source();
      for (final reason in ['finished', 'time_up', 'left', 'paused']) {
        final b = (await m.next(
          lastStop: (sessionId: 's-$reason', reason: reason),
        )).badge;
        expect(b, isNotNull, reason: reason);
        expect(b!.served, isNull);
      }
    });
  });

  for (final (reason, name) in [
    ('time_up', 'Detective at work'),
    ('left', 'Tried a tricky case'),
    ('paused', 'Good start on a case'),
    ('finished', 'Case cracked'),
  ]) {
    testWidgets('Home after a $reason session shows its badge', (tester) async {
      await shots(
        tester,
        'child_home_session_badge_$reason',
        HomeScreen(
          name: 'Mira',
          grownUps: Paths.kids,
          moment: HomeMomentCard(
            moments: (
              badge: (sessionId: 's1', reason: reason, served: null),
              streak: false,
            ),
          ),
        ),
      );
      expect(find.text(name), findsOneWidget);
      expect(find.text('Your badge for this session'), findsOneWidget);
    });
  }

  group('REW-05: a kind streak moment', () {
    test('only with the flag, when the server says, once a day', () async {
      final (deps, server) = await testDeps();
      final m = HomeMomentsSource(rewards: RewardsRepository(deps.client));
      server.on('GET /api/children/c1/streak', {'show': true});
      final monday = DateTime(2026, 11, 9, 16);
      Future<bool> visit({bool on = true, DateTime? at}) async => (await m.next(
        lastStop: null,
        childId: 'c1',
        streakOn: on,
        now: at ?? monday,
      )).streak;
      expect(await visit(on: false), isFalse);
      expect(await visit(), isTrue);
      expect(await visit(), isFalse); // once that day
      expect(await visit(at: monday.add(const Duration(days: 1))), isTrue);
      server.on('GET /api/children/c1/streak', {'show': false});
      expect(await visit(at: monday.add(const Duration(days: 3))), isFalse);
    });

    test('no route yet: no moment, and no error', () async {
      final (deps, _) = await testDeps();
      final m = HomeMomentsSource(rewards: RewardsRepository(deps.client));
      expect(
        (await m.next(lastStop: null, childId: 'c1', streakOn: true)).streak,
        isFalse,
      );
    });

    testWidgets('Home shows it with no number and no loss', (tester) async {
      await shots(
        tester,
        'child_home_streak',
        const HomeScreen(
          name: 'Mira',
          grownUps: Paths.kids,
          moment: HomeMomentCard(moments: (badge: null, streak: true)),
        ),
      );
      expect(find.textContaining('Back on the case again'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d')), findsNothing);
    });
  });

  test('a served badge without a name is not used', () {
    expect(RewardsRepository.badgeFrom({'id': 'x'}), isNull);
    expect(
      RewardsRepository.badgeFrom({'badge_id': 'x', 'title': 'X'})!.name,
      'X',
    );
  });
}
