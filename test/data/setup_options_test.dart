import 'package:auramath/data/repositories/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = SetupOptions.fromJson({
    'ages': [6, 7, 8],
    'schoolYears': [
      {'id': 'kindergarten', 'label': 'Kindergarten'},
      {'id': 'year_1', 'label': 'Year 1'},
    ],
    'goals': [
      {'id': 'catch_up', 'label': 'Catch up'},
      {'id': 'new_goal', 'label': 'Something new'},
    ],
    'canDo': [
      {'id': 'adding_to_100', 'label': 'Adding to 100', 'skillId': 'x'},
      {'id': 'not_sure', 'label': "I'm not sure"},
    ],
  });

  test("the server's lists, with not-sure kept apart from can-do", () {
    expect(options.ages, [6, 7, 8]);
    expect(options.schoolYears.map((o) => o.id), ['kindergarten', 'year_1']);
    expect(options.canDo.map((o) => o.id), ['adding_to_100']);
  });

  test("ours in the server's order: our words for ids we know, its label "
      'for one we don\'t, and ids it dropped are gone', () {
    final ours = [('Get ahead', 'get_ahead'), ('Catch up!', 'catch_up')];
    expect(
      inServerOrder(ours, (o) => o.$2, options.goals, (s) => (s.label, s.id)),
      [('Catch up!', 'catch_up'), ('Something new', 'new_goal')],
    );
    expect(
      inServerOrder(ours, (o) => o.$2, null, (s) => (s.label, s.id)),
      ours,
    );
  });
}
