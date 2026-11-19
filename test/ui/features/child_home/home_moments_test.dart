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

    test('FL-49: the badge and the streak from one rewards read', () async {
      final (deps, server) = await testDeps();
      final m = HomeMomentsSource(rewards: RewardsRepository(deps.client));
      server.on('GET /api/children/c1/rewards', {
        'sessionBadges': [
          {
            'badgeId': 'session.opened',
            'name': 'Case Opener',
            'sessionId': 's1',
          },
        ],
        'streak': {'show': true, 'band': '2'},
      });
      final moments = await m.next(
        lastStop: (sessionId: 's1', reason: 'left'),
        childId: 'c1',
        streakOn: true,
      );
      expect(moments.badge!.served!.name, 'Case Opener');
      expect(moments.streak, isTrue);
      expect(
        server.calls.where((c) => c.$1.endsWith('/rewards')),
        hasLength(1),
      );
    });

    test('the badge in the events reply wins, with no rewards read', () async {
      final (m, server) = await source();
      server.on('GET /api/children/c1/rewards', {
        'sessionBadges': <Object>[],
        'draft': true,
      });
      final b = (await m.next(
        lastStop: (sessionId: 's1', reason: 'finished'),
        childId: 'c1',
        replied: (id) => id == 's1'
            ? (id: 'session.solved.lemon', name: 'Lemon Case', says: null)
            : null,
      )).badge;
      expect(b!.served!.name, 'Lemon Case');
    });

    test('H6: no server badge yet: none made up now, after a short wait; '
        'a later visit shows the one the server names', () async {
      final (m, server) = await source();
      var waited = 0;
      for (final reason in ['finished', 'time_up', 'left', 'paused']) {
        final b = (await m.next(
          lastStop: (sessionId: 's-$reason', reason: reason),
          childId: 'c1',
          settle: () async => waited++,
        )).badge;
        expect(b, isNull, reason: reason);
      }
      expect(waited, 4);
      server.on('GET /api/children/c1/rewards', {
        'sessionBadges': [
          {
            'badgeId': 'session.kept_going',
            'kind': 'session',
            'name': 'Kept going',
            'sessionId': 's-time_up',
          },
        ],
      });
      final later = await m.next(
        lastStop: (sessionId: 's-time_up', reason: 'time_up'),
        childId: 'c1',
      );
      expect(later.badge?.served?.name, 'Kept going');
    });
  });

  // H6: the server's names (catalogue.yaml), never the phone's own
  for (final (reason, name) in [
    ('time_up', 'Kept going'),
    ('left', 'Back on track'),
    ('paused', 'Good start'),
    ('finished', 'Case cracked!'),
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
              badge: (
                sessionId: 's1',
                reason: reason,
                served: (id: 'session.x', name: name, says: null),
              ),
              streak: false,
            ),
          ),
        ),
      );
      expect(find.text(name), findsOneWidget);
      expect(find.text('Your badge for this session'), findsOneWidget);
    });
  }

  testWidgets('H6: a badge the server hasn\'t named shows nothing', (
    tester,
  ) async {
    await shots(
      tester,
      'child_home_session_badge_unnamed',
      const HomeScreen(
        name: 'Mira',
        grownUps: Paths.kids,
        moment: HomeMomentCard(
          moments: (
            badge: (sessionId: 's1', reason: 'finished', served: null),
            streak: false,
          ),
        ),
      ),
    );
    expect(find.text('Your badge for this session'), findsNothing);
    expect(find.text('Case cracked'), findsNothing);
  });

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

    test('DAT-03: the moment shown is handed on with its band, once', () async {
      final (deps, server) = await testDeps();
      final m = HomeMomentsSource(rewards: RewardsRepository(deps.client));
      server.on('GET /api/children/c1/rewards', {
        'streak': {'show': true, 'band': '7_plus', 'coveredMissedDay': true},
      });
      final shown = <StreakMoment>[];
      for (var i = 0; i < 2; i++) {
        await m.next(
          lastStop: null,
          childId: 'c1',
          streakOn: true,
          onStreak: shown.add,
        );
      }
      expect(shown, [(band: '7_plus', coveredMissedDay: true)]);
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
