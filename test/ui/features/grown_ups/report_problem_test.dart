import 'dart:io';

import 'package:auramath/data/repositories/problem_report_repository.dart';
import 'package:auramath/data/repositories/report_email_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/core/parts/aura_button.dart';
import 'package:auramath/ui/features/grown_ups/views/report_problem_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'gu_fakes.dart';

/// PAR-13: Report a problem in the Family area, into Key's weekly review.
void main() {
  const choices = 'GET /api/family/problem-reports/choices';
  const send = 'POST /api/family/problem-reports';
  final shown = DateTime(2026, 11, 17, 16, 5).millisecondsSinceEpoch;

  void serveChoices(Gu g) => g.server.on(choices, {
    'choices': [
      {
        'sessionId': 'sess-2',
        'childId': 'child-2',
        'startedAt': shown,
        'problemId': 'g_known',
        'contentVersion': '1.4.0',
        'shownAt': shown,
      },
      {
        'sessionId': 'sess-1',
        'childId': 'child-1',
        'startedAt': shown - 86400000,
        'problemId': 'g_0f3a9c',
        'contentVersion': '1.3.0',
        'shownAt': shown - 86400000,
      },
    ],
  });

  Widget screen(Gu g) => ReportProblemScreen(
    reports: ProblemReportRepository(g.deps.client),
    family: g.deps.family,
    storyOf: (id) => id == 'g_known' ? ('Tree', 'Lamp') : null,
  );

  Future<Gu> open(WidgetTester tester) async {
    final g = await Gu.make(tester);
    serveChoices(g);
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    return g;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  bool sendEnabled(WidgetTester tester) =>
      tester
          .widget<AuraButton>(find.widgetWithText(AuraButton, 'Send'))
          .onPressed !=
      null;

  testWidgets('at every size', (tester) async {
    final g = await Gu.make(tester);
    serveChoices(g);
    await shotAllSizes(tester, 'grown_ups_report_problem', screen(g));
    expect(find.text('Report a problem'), findsOneWidget);
  });

  testWidgets('the cases are named by story, child and day, never an id', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Tree and Lamp'), findsOneWidget);
    // a case this phone never drew: a plain name
    expect(find.text('A story problem'), findsOneWidget);
    expect(find.textContaining('Maya, '), findsOneWidget);
    expect(find.textContaining('Aarav, '), findsOneWidget);
    expect(find.textContaining('Nov'), findsNWidgets(2));
    for (final id in ['g_known', 'g_0f3a9c', 'sess-1', 'sess-2', '1.3.0']) {
      expect(find.textContaining(id), findsNothing);
    }
    expect(find.text('Something else'), findsOneWidget);
    // the note screen asks for no names (D-15)
    expect(find.text("Please don't include names."), findsOneWidget);
  });

  testWidgets(
    "the server's title names a case, before this phone's pack (PAR-13)",
    (tester) async {
      final g = await Gu.make(tester);
      g.server.on(choices, {
        'choices': [
          {
            // the pack knows it too: the server's title still wins
            'sessionId': 'sess-2',
            'childId': 'child-2',
            'startedAt': shown,
            'problemId': 'g_known',
            'contentVersion': '1.4.0',
            'shownAt': shown,
            'title': 'The lemon tree and the fig tree',
          },
          {
            'sessionId': 'sess-1',
            'childId': 'child-1',
            'startedAt': shown - 86400000,
            'problemId': 'g_0f3a9c',
            'contentVersion': '1.3.0',
            'shownAt': shown - 86400000,
            'title': 'Building A and Building B',
          },
          {
            // a generated story: no title, and the pack doesn't know it
            'sessionId': 'sess-1',
            'childId': 'child-1',
            'startedAt': shown - 86400000,
            'problemId': 'g_ai',
            'contentVersion': '1.3.0',
            'shownAt': shown - 86400000 + 60000,
            'title': null,
          },
        ],
      });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('The lemon tree and the fig tree'), findsOneWidget);
      expect(find.text('Building A and Building B'), findsOneWidget);
      expect(find.text('Tree and Lamp'), findsNothing);
      expect(find.text('A story problem'), findsOneWidget);
      g.server.on(send, {
        'report': {'id': 'r1'},
      }, status: 201);
      await tapText(tester, 'Building A and Building B');
      await tapText(tester, 'Send');
      expect(g.bodyOf(send), {
        'kind': 'problem',
        'sessionId': 'sess-1',
        'problemId': 'g_0f3a9c',
        'contentVersion': '1.3.0',
      });
    },
  );

  testWidgets('a titled case at every size', (tester) async {
    final g = await Gu.make(tester);
    g.server.on(choices, {
      'choices': [
        {
          'sessionId': 'sess-2',
          'childId': 'child-2',
          'startedAt': shown,
          'problemId': 'g_known',
          'contentVersion': '1.4.0',
          'shownAt': shown,
          'title': 'The lemon tree and the fig tree',
        },
      ],
    });
    await shotAllSizes(tester, 'grown_ups_report_problem_titled', screen(g));
    expect(find.text('The lemon tree and the fig tree'), findsOneWidget);
  });

  testWidgets('Send waits for a pick', (tester) async {
    await open(tester);
    expect(sendEnabled(tester), isFalse);
    await tapText(tester, 'A story problem');
    expect(sendEnabled(tester), isTrue);
  });

  testWidgets('a case and a note go to the review; then Thank you', (
    tester,
  ) async {
    final g = await open(tester);
    g.server.on(send, {
      'report': {'id': 'r1'},
    }, status: 201);
    await tapText(tester, 'A story problem');
    await tester.enterText(find.byType(TextField), '  The hint looked odd.  ');
    await tapText(tester, 'Send');
    expect(g.bodyOf(send), {
      'kind': 'problem',
      'sessionId': 'sess-1',
      'problemId': 'g_0f3a9c',
      'contentVersion': '1.3.0',
      'note': 'The hint looked odd.',
    });
    expect(find.text('Thank you'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);
    expect(
      find.text('We have your report. A person at Key will look at it.'),
      findsOneWidget,
    );
    await tapText(tester, 'Back to the Family area');
    expect(find.text('went to ${Paths.grownUps}'), findsOneWidget);
  });

  testWidgets('the thank-you at every size', (tester) async {
    await shotAllSizes(tester, 'grown_ups_report_sent', const ReportSentView());
    expect(find.text('Back to the Family area'), findsOneWidget);
  });

  testWidgets('Something else with no note sends only its kind', (
    tester,
  ) async {
    final g = await open(tester);
    g.server.on(send, {
      'report': {'id': 'r1'},
    }, status: 201);
    await tapText(tester, 'Something else');
    await tapText(tester, 'Send');
    expect(g.bodyOf(send), {'kind': 'something_else'});
    expect(find.text('Thank you'), findsOneWidget);
  });

  testWidgets('offline: says so kindly and keeps the note', (tester) async {
    final g = await open(tester);
    g.server.routes[send] = (_) => throw const SocketException('offline');
    await tapText(tester, 'Something else');
    await tester.enterText(find.byType(TextField), 'It froze.');
    await tapText(tester, 'Send');
    expect(
      find.text(
        'Not sent. Check the internet, then send it again. Your note is '
        'still here.',
      ),
      findsOneWidget,
    );
    expect(find.text('Thank you'), findsNothing);
    expect(find.text('It froze.'), findsOneWidget);
    expect(sendEnabled(tester), isTrue);
  });

  testWidgets('too many this hour (429): later, kindly', (tester) async {
    final g = await open(tester);
    g.server.on(send, {
      'error': 'too many reports; try again in 1200s',
    }, status: 429);
    await tapText(tester, 'Something else');
    await tapText(tester, 'Send');
    expect(
      find.text(
        "That's a lot of reports in one hour. Please send this one a little "
        'later. Your note is still here.',
      ),
      findsOneWidget,
    );
    // never the server's own words
    expect(find.textContaining('1200s'), findsNothing);
  });

  testWidgets('a lesson that is gone (404) or a refused report (400)', (
    tester,
  ) async {
    final g = await open(tester);
    g.server.on(send, {'error': 'no such session'}, status: 404);
    await tapText(tester, 'Tree and Lamp');
    await tapText(tester, 'Send');
    expect(
      find.text(
        "That lesson can't be found any more. Pick another, or Something "
        'else.',
      ),
      findsOneWidget,
    );
    g.server.on(send, {'error': 'the note is at most 500'}, status: 400);
    await tapText(tester, 'Send');
    expect(
      find.text(
        "That couldn't be sent. Please check the note, then send it again.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('no lessons yet: Something else is still there', (tester) async {
    final g = await Gu.make(tester);
    g.server.on(choices, {'choices': <Object>[]});
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    expect(
      find.text('No lessons to pick from yet. Something else is always there.'),
      findsOneWidget,
    );
    expect(find.text('Something else'), findsOneWidget);
  });

  testWidgets('the choices offline: a way to try once more', (tester) async {
    final g = await Gu.make(tester);
    g.server.routes[choices] = (_) => throw const SocketException('offline');
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    expect(find.text('Something else'), findsNothing);
    serveChoices(g);
    await tapText(tester, 'Try again');
    expect(find.text('Something else'), findsOneWidget);
  });

  testWidgets('Settings has Report a problem (reachable in the app)', (
    tester,
  ) async {
    final g = await Gu.make(tester);
    await tester.pumpWidget(
      shotApp(
        SettingsScreen(
          family: g.deps.family,
          repo: g.repo,
          email: ReportEmailRepository(g.deps.client),
          settings: g.settings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Report a problem');
    expect(find.text('went to ${Paths.reportProblem}'), findsOneWidget);
  });
}
