import 'package:auramath/ui/core/parts/aura_page.dart';
import 'package:auramath/ui/core/parts/code_boxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';

void main() {
  testWidgets('code boxes sit in a scrolling page at every size', (
    tester,
  ) async {
    await shotAllSizes(
      tester,
      'core_code_boxes',
      const AuraPage(
        body: Column(
          children: [
            AuraHeading(title: 'Type your code'),
            CodeBoxes(length: 6, value: '0123'),
          ],
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget); // a leading zero stays
  });
}
