import 'package:auramath/ui/core/parts/aura_button.dart';
import 'package:auramath/ui/core/parts/aura_page.dart';
import 'package:auramath/ui/core/parts/choice_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';

void main() {
  testWidgets('a long list scrolls and the button stays at every size', (
    tester,
  ) async {
    await shotAllSizes(
      tester,
      'core_aura_page',
      AuraPage(
        top: const AuraTopBar(progress: 0.25, fallback: '/'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuraHeading(title: 'Which school year is Aarav in?'),
            for (final y in [
              'Kindergarten',
              'Year 1',
              'Year 2',
              'Year 3',
              'Year 4',
              'Year 5',
              'Year 6',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChoiceTile(
                  label: y,
                  selected: y == 'Year 2',
                  flag: y == 'Year 2' ? 'Usual for age 7' : null,
                  onTap: () {},
                ),
              ),
          ],
        ),
        bottom: AuraButton(
          label: 'Continue',
          color: AuraButtonColor.blue,
          onPressed: () {},
        ),
      ),
    );
    expect(find.text('Continue'), findsOneWidget);
  });
}
