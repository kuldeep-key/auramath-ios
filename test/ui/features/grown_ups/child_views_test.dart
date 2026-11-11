import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/book_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/month_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/plan_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/report_screen.dart';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/shots.dart';
import 'gu_fakes.dart';

/// A 1x1 PNG, the shape of the server's drawing.
const onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

void main() {
  group('Book', () {
    testWidgets("at every size: this week's session and its note", (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await shotAllSizes(
        tester,
        'grown_ups_book',
        BookScreen(childId: 'child-1', family: g.deps.family, repo: g.repo),
      );
      expect(find.text("Aarav's book"), findsOneWidget);
      expect(find.textContaining('· 12 min'), findsOneWidget);
      expect(
        find.text('Practised comparing two bars. Did the second one alone.'),
        findsOneWidget,
      );
    });

    testWidgets("PAR-09: the lesson's drawing under its note, named by its "
        'caption; none when nothing was placed', (tester) async {
      final g = await Gu.make(tester);
      g.server.raw['GET /api/sessions/s1/drawing.png'] = http.Response.bytes(
        base64Decode(onePixelPng),
        200,
        headers: {
          'content-type': 'image/png',
          'x-caption': Uri.encodeComponent('The gap, ringed: 79 cm'),
        },
      );
      await shotAllSizes(
        tester,
        'grown_ups_book_drawing',
        BookScreen(childId: 'child-1', family: g.deps.family, repo: g.repo),
      );
      expect(find.byKey(const Key('sessionDrawing')), findsOneWidget);
      expect(find.text('The gap, ringed: 79 cm'), findsOneWidget);
      expect(g.calls, contains('GET /api/sessions/s1/drawing.png'));

      g.server.raw.clear(); // the fake's 404: nothing was placed
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        shotApp(
          BookScreen(childId: 'child-1', family: g.deps.family, repo: g.repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sessionDrawing')), findsNothing);
      expect(
        find.text('Practised comparing two bars. Did the second one alone.'),
        findsOneWidget,
      );
    });

    testWidgets('no lessons yet: Nothing saved yet', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(
        tester,
        'grown_ups_book_empty',
        BookScreen(childId: 'child-2', family: g.deps.family, repo: g.repo),
      );
      expect(find.text('Nothing saved yet'), findsOneWidget);
    });

    testWidgets('tabs, and the links out', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(
        shotApp(
          BookScreen(childId: 'child-1', family: g.deps.family, repo: g.repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Badges'));
      await tester.pumpAndSettle();
      expect(find.text("Badges show on Aarav's own screens."), findsOneWidget);
      await tester.tap(find.text("What's next in the plan"));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.plan('child-1')}'), findsOneWidget);
    });

    testWidgets('a child not in this family is an error, not a blank', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(
        shotApp(
          BookScreen(childId: 'nobody', family: g.deps.family, repo: g.repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('no such child'), findsOneWidget);
    });
  });

  group('Plan', () {
    testWidgets("at every size: the server's next step, read-only", (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await shotAllSizes(
        tester,
        'grown_ups_plan',
        PlanScreen(childId: 'child-1', family: g.deps.family, repo: g.repo),
      );
      expect(find.text('A comparison that says "shorter".'), findsOneWidget);
      expect(find.textContaining('Drag'), findsNothing);
    });

    testWidgets('nothing planned yet', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(
        shotApp(
          PlanScreen(childId: 'child-2', family: g.deps.family, repo: g.repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nothing planned yet'), findsOneWidget);
    });
  });

  testWidgets('Simple report at every size: only real numbers', (tester) async {
    final g = await Gu.make(tester);
    await shotAllSizes(
      tester,
      'grown_ups_report',
      ReportScreen(childId: 'child-1', family: g.deps.family, repo: g.repo),
    );
    // the rehearsal is left out
    expect(find.text('1'), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
  });

  testWidgets('Month view at every size', (tester) async {
    final g = await Gu.make(tester);
    await shotAllSizes(
      tester,
      'grown_ups_month',
      MonthScreen(childId: 'child-1', family: g.deps.family, repo: g.repo),
    );
    expect(find.textContaining('Aarav in '), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
  });
}
