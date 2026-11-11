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
            moments: (badge: (sessionId: 's1', reason: reason, served: null)),
          ),
        ),
      );
      expect(find.text(name), findsOneWidget);
      expect(find.text('Your badge for this session'), findsOneWidget);
    });
  }

  test('a served badge without a name is not used', () {
    expect(RewardsRepository.badgeFrom({'id': 'x'}), isNull);
    expect(
      RewardsRepository.badgeFrom({'badge_id': 'x', 'title': 'X'})!.name,
      'X',
    );
  });
}
