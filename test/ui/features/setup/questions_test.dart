import 'package:auramath/data/repositories/account_repository.dart';
import 'package:auramath/ui/features/setup/views/age_screen.dart';
import 'package:auramath/ui/features/setup/views/data_screen.dart';
import 'package:auramath/ui/features/setup/views/goal_screen.dart';
import 'package:auramath/ui/features/setup/views/name_screen.dart';
import 'package:auramath/ui/features/setup/views/not_sure_screen.dart';
import 'package:auramath/ui/features/setup/views/start_screen.dart';
import 'package:auramath/ui/features/setup/views/year_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'setup_test_helpers.dart';

SetupDraft aarav() => SetupDraft()
  ..name = 'Aarav'
  ..age = 7;

void main() {
  group('Name (643:24)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(tester, 'setup_name', NameScreen(draft: SetupDraft()));
    });

    testWidgets('keeps the trimmed name and opens Age', (tester) async {
      final draft = SetupDraft();
      await show(tester, NameScreen(draft: draft));
      await tester.enterText(find.byType(TextField), '  Aarav ');
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.name, 'Aarav');
      expect(find.text('went to /setup/age'), findsOneWidget);
    });

    testWidgets('Continue does nothing without a name', (tester) async {
      await show(tester, NameScreen(draft: SetupDraft()));
      await tapAndWait(tester, find.text('Continue'));
      expect(find.textContaining('went to'), findsNothing);
    });
  });

  group('Age (643:40)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(tester, 'setup_age', AgeScreen(draft: aarav()));
    });

    testWidgets('uses the name and keeps the age', (tester) async {
      final draft = SetupDraft()..name = 'Aarav';
      await show(tester, AgeScreen(draft: draft));
      expect(find.text('How old is Aarav?'), findsOneWidget);
      await tapAndWait(tester, find.text('8'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.age, 8);
      expect(find.text('went to /setup/year'), findsOneWidget);
    });
  });

  group('Year (643:66)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(tester, 'setup_year', YearScreen(draft: aarav()));
    });

    testWidgets('offers Kindergarten to Year 5, the usual one chosen', (
      tester,
    ) async {
      final draft = aarav();
      await show(tester, YearScreen(draft: draft));
      expect(find.text('Usual for age 7'), findsOneWidget);
      expect(find.text('Year 5'), findsOneWidget);
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.schoolYear, 'Year 2');
      expect(find.text('went to /setup/start'), findsOneWidget);
    });

    testWidgets('a different year can be picked', (tester) async {
      final draft = aarav();
      await show(tester, YearScreen(draft: draft));
      await tapAndWait(tester, find.text('Kindergarten'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.schoolYear, 'Kindergarten');
    });
  });

  group('Start (643:102)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(tester, 'setup_start', StartScreen(draft: aarav()));
    });

    testWidgets('sends the skill ids picked, then Goal', (tester) async {
      final draft = aarav();
      await show(tester, StartScreen(draft: draft));
      await tapAndWait(tester, find.text('Adding to 1000'));
      await tapAndWait(tester, find.text('Counting to 100'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.startingPoint, 'chosen');
      expect(draft.canDo, {'arith.add-3d-regroup', 'ns.count-fwd-30'});
      expect(find.text('went to /setup/goal'), findsOneWidget);
    });

    testWidgets("I'm not sure opens StartNotSure and clears the areas", (
      tester,
    ) async {
      final draft = aarav()..canDo = ['cmp.compare-bars'];
      await show(tester, StartScreen(draft: draft));
      await tapAndWait(tester, find.text("I'm not sure"));
      expect(draft.startingPoint, 'not_sure');
      expect(draft.canDo, isEmpty);
      expect(find.text('went to /setup/not-sure'), findsOneWidget);
    });
  });

  group('StartNotSure (643:145)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(
        tester,
        'setup_not_sure',
        NotSureScreen(draft: aarav()..schoolYear = 'Year 2'),
      );
    });

    testWidgets('names the child and year; Continue opens Goal', (
      tester,
    ) async {
      await show(tester, NotSureScreen(draft: aarav()..schoolYear = 'Year 2'));
      expect(
        find.textContaining('Aarav starts at a typical Year 2 level'),
        findsOneWidget,
      );
      await tapAndWait(tester, find.text('Continue'));
      expect(find.text('went to /setup/goal'), findsOneWidget);
    });
  });

  group('Goal (643:169)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(tester, 'setup_goal', GoalScreen(draft: aarav()));
    });

    testWidgets('sends only a goal the server knows', (tester) async {
      final draft = aarav();
      await show(tester, GoalScreen(draft: draft));
      await tapAndWait(tester, find.text('Catch up'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.goal, 'school_curriculum');
      expect(find.text('went to /setup/data'), findsOneWidget);
    });

    testWidgets('a goal the server lacks is not sent', (tester) async {
      final draft = aarav()..goal = 'school_curriculum';
      await show(tester, GoalScreen(draft: draft));
      await tapAndWait(tester, find.text('Build confidence'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.goal, isNull);
    });
  });

  group('Data (643:203)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(tester, 'setup_data', DataScreen(draft: aarav()));
    });

    testWidgets('I agree records it and opens SavePlace', (tester) async {
      final draft = aarav();
      await show(tester, DataScreen(draft: draft));
      expect(find.text("Aarav's details stay safe"), findsOneWidget);
      await tapAndWait(tester, find.text('I agree'));
      expect(draft.agreed, isTrue);
      expect(find.text('went to /setup/save'), findsOneWidget);
    });
  });
}
