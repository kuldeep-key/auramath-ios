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
      server.on('GET /api/children/c1/rewards', {
        'sessionBadges': [
          {
            'badgeId': 'session.solved.mango',
            'kind': 'session',
            'name': 'Mango Word Problem',
            'for': 'solved',
            'draftName': true,
            'sessionId': 's0',
            'awardedAt': 1,
          },
          {
            'badgeId': 'session.worked_on.tree-word-problem-explorer',
            'kind': 'session',
            'name': 'Tree Word Problem Explorer',
            'for': 'worked_on',
            'draftName': true,
            'sessionId': 's1',
            'awardedAt': 2,
          },
        ],
        'trail': null,
        'streak': null,
        'levelBadges': null,
        'draft': true,
      });
      const stop = (sessionId: 's1', reason: 'time_up');
      final first = await m.next(lastStop: stop, childId: 'c1');
      expect(first.badge!.served!.name, 'Tree Word Problem Explorer');
      expect(
        first.badge!.served!.id,
        'session.worked_on.tree-word-problem-explorer',
      );
      expect((await m.next(lastStop: stop, childId: 'c1')).badge, isNull);
      expect((await m.next(lastStop: null, childId: 'c1')).badge, isNull);
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
      Map<String, Object?> rewards({required bool show}) => {
        'sessionBadges': null,
        'trail': null,
        'streak': {'show': show, 'band': show ? '2' : null},
        'levelBadges': null,
        'draft': true,
      };
      server.on('GET /api/children/c1/rewards', rewards(show: true));
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
      server.on('GET /api/children/c1/rewards', rewards(show: false));
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

  test('REW-06: the level badges the server says were earned', () async {
    final (deps, server) = await testDeps();
    server.on('GET /api/children/c1/rewards', {
      'levelBadges': [
        {
          'badgeId': 'level.cmp.comparison.l1',
          'kind': 'skill_mastered',
          'name': 'Level 1 passed',
          'questionType': 'cmp.comparison',
          'level': 'L1',
          'sessionId': 's1',
          'draftName': true,
        },
      ],
    });
    final badges = await RewardsRepository(deps.client).levelBadges('c1');
    expect(badges.map((b) => (b.id, b.name)), [
      ('level.cmp.comparison.l1', 'Level 1 passed'),
    ]);
  });

  test('a served badge without a name is not used', () {
    expect(RewardsRepository.badgeFrom({'id': 'x'}), isNull);
    expect(
      RewardsRepository.badgeFrom({'badge_id': 'x', 'title': 'X'})!.name,
      'X',
    );
  });
}
