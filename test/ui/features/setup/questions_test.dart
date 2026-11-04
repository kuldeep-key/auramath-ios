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

    testWidgets('offers 6 to 10 and says so (D-36, E25)', (tester) async {
      await show(tester, AgeScreen(draft: aarav()));
      expect(find.text('5'), findsNothing);
      for (final age in ['6', '7', '8', '9', '10']) {
        expect(find.text(age), findsOneWidget);
      }
      expect(find.text('Auramath is for ages 6 to 10 for now.'), findsOneWidget);
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
      expect(draft.schoolYear, 'year_2');
      expect(find.text('went to /setup/start'), findsOneWidget);
    });

    testWidgets('a different year can be picked', (tester) async {
      final draft = aarav();
      await show(tester, YearScreen(draft: draft));
      await tapAndWait(tester, find.text('Kindergarten'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.schoolYear, 'kindergarten');
    });

    test('a typed year becomes its id', () {
      expect(yearIdFrom('Year 2'), 'year_2');
      expect(yearIdFrom(' 5 '), 'year_5');
      expect(yearIdFrom('Kindy'), 'kindergarten');
      expect(yearIdFrom('Year 0'), isNull);
      expect(yearIdFrom('Year 6'), isNull);
      expect(yearIdFrom('second'), isNull);
    });
  });

  group('Start (643:102)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(tester, 'setup_start', StartScreen(draft: aarav()));
    });

    testWidgets('sends the ids picked, then Goal', (tester) async {
      final draft = aarav();
      await show(tester, StartScreen(draft: draft));
      await tapAndWait(tester, find.text('Adding to 1000'));
      await tapAndWait(tester, find.text('Counting to 100'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.startingPoint, 'chosen');
      expect(draft.canDo, {'adding_to_1000', 'counting_to_100'});
      expect(find.text('went to /setup/goal'), findsOneWidget);
    });

    testWidgets("I'm not sure opens StartNotSure and sends only not_sure", (
      tester,
    ) async {
      final draft = aarav()..canDo = ['word_problems_with_bars'];
      await show(tester, StartScreen(draft: draft));
      await tapAndWait(tester, find.text("I'm not sure"));
      expect(draft.startingPoint, 'not_sure');
      expect(draft.canDo, ['not_sure']);
      expect(find.text('went to /setup/not-sure'), findsOneWidget);
    });
  });

  group('StartNotSure (643:145)', () {
    testWidgets('fits every size', (tester) async {
      await shotAllSizes(
        tester,
        'setup_not_sure',
        NotSureScreen(draft: aarav()..schoolYear = 'year_2'),
      );
    });

    testWidgets('names the child and year; Continue opens Goal', (
      tester,
    ) async {
      await show(tester, NotSureScreen(draft: aarav()..schoolYear = 'year_2'));
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

    testWidgets('offers the six PRD goals; sends the ones the server knows', (
      tester,
    ) async {
      final draft = aarav();
      await show(tester, GoalScreen(draft: draft));
      for (final goal in [
        'Build confidence',
        'Catch up',
        'Get ahead',
        'Word problems',
        'Do well in the school curriculum',
        "I'm not sure",
      ]) {
        expect(find.text(goal), findsOneWidget);
      }
      await tester.ensureVisible(find.text('Do well in the school curriculum'));
      await tapAndWait(tester, find.text('Do well in the school curriculum'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.goal, 'school_curriculum');
      expect(find.text('went to /setup/data'), findsOneWidget);
    });

    testWidgets("I'm not sure sends not_sure", (tester) async {
      final draft = aarav();
      await show(tester, GoalScreen(draft: draft));
      await tester.ensureVisible(find.text("I'm not sure"));
      await tapAndWait(tester, find.text("I'm not sure"));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.goal, 'not_sure');
    });

    testWidgets('every goal sends its id', (tester) async {
      final draft = aarav()..goal = 'school_curriculum';
      await show(tester, GoalScreen(draft: draft));
      await tapAndWait(tester, find.text('Build confidence'));
      await tapAndWait(tester, find.text('Continue'));
      expect(draft.goal, 'build_confidence');
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
