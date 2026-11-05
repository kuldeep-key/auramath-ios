import 'package:auramath/data/repositories/setup_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/edit_child_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/learning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'gu_fakes.dart';

void main() {
  group('Learning', () {
    Widget screen(Gu g, String id) =>
        LearningScreen(childId: id, family: g.deps.family, repo: g.repo);

    testWidgets('at every size: the level and its changes in plain words', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_learning', screen(g, 'child-1'));
      expect(find.text('Where Aarav is'), findsOneWidget);
      expect(find.text('Comparing amounts'), findsOneWidget);
      expect(find.text('Level 4'), findsOneWidget);
      expect(find.text('Moved up to level 4'), findsNWidgets(2));
      expect(
        find.text('Went back a level to build confidence'),
        findsOneWidget,
      );
    });

    testWidgets('no score, count or mistake is shown', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g, 'child-1')));
      await tester.pumpAndSettle();
      // the server's problems (9), mistakes (E3: 2) and clean solves (1)
      expect(find.textContaining('9'), findsNothing);
      expect(find.textContaining('E3'), findsNothing);
      expect(find.textContaining('mistake'), findsNothing);
      expect(find.textContaining('score'), findsNothing);
    });

    testWidgets('before the first lesson it says so', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g, 'child-2')));
      await tester.pumpAndSettle();
      expect(
        find.text("This fills in after Maya's first lesson."),
        findsOneWidget,
      );
    });

    testWidgets('links on to changing the details', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g, 'child-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Change Aarav's details"));
      await tester.pumpAndSettle();
      expect(
        find.text('went to ${Paths.editChild('child-1')}'),
        findsOneWidget,
      );
    });

    test('levels and reasons read plainly; an unknown reason is neutral', () {
      expect(levelLabel('L5'), '5');
      expect(levelLabel('top'), 'top');
    });
  });

  group('EditChild', () {
    void options(Gu g) => g.server.on('GET /api/setup/options', {
      'ages': [6, 7, 8, 9, 10],
      'schoolYears': [
        {'id': 'kindergarten', 'label': 'Kindergarten'},
        {'id': 'year_1', 'label': 'Year 1'},
        {'id': 'year_2', 'label': 'Year 2'},
      ],
      'goals': <Object>[],
      'canDo': <Object>[],
    });

    Widget screen(Gu g) => EditChildScreen(
      childId: 'child-1',
      family: g.deps.family,
      setup: SetupRepository(g.deps.client),
    );

    testWidgets("at every size: the setup lists, the child's answers", (
      tester,
    ) async {
      final g = await Gu.make(tester);
      options(g);
      await shotAllSizes(tester, 'grown_ups_edit_child', screen(g));
      expect(find.text("Aarav's details"), findsOneWidget);
      expect(find.text('Aarav'), findsOneWidget);
      expect(find.text('Year 2'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('sends only what changed, then goes back', (tester) async {
      final g = await Gu.make(tester);
      options(g);
      g.server.on('PATCH /api/children/child-1', {
        'id': 'child-1',
        'displayName': 'Arav',
        'age': 7,
        'schoolYear': 'year_2',
      });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), ' Arav ');
      await tester.tap(find.text('7'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(g.bodyOf('PATCH /api/children/child-1'), {
        'displayName': 'Arav',
        'age': 7,
      });
      expect(find.text('went to ${Paths.learning('child-1')}'), findsOneWidget);
    });

    testWidgets('nothing changed: no call', (tester) async {
      final g = await Gu.make(tester);
      options(g);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(g.calls, isNot(contains('PATCH /api/children/child-1')));
      expect(find.text('went to ${Paths.learning('child-1')}'), findsOneWidget);
    });

    testWidgets('a name is needed, and no longer than 40', (tester) async {
      final g = await Gu.make(tester);
      options(g);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Type a first name.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'A' * 41);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Keep it to 40 letters or fewer.'), findsOneWidget);
      expect(g.calls, isNot(contains('PATCH /api/children/child-1')));
    });

    testWidgets("the server's refusal stays and says why", (tester) async {
      final g = await Gu.make(tester);
      options(g);
      g.server.on('PATCH /api/children/child-1', {
        'error': 'another child in this family already has that name',
      }, status: 409);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Maya');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('another child in this family already has that name'),
        findsOneWidget,
      );
      expect(find.textContaining('went to'), findsNothing);
    });
  });
}
