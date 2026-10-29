import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/pairing/views/carry_on_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';

void main() {
  testWidgets('fits every size', (tester) async {
    await shotAllSizes(
      tester,
      'pairing_carry_on',
      const CarryOnScreen(device: "Child's phone"),
    );
    expect(
      find.text("You started this case on Child's phone. It moved with you."),
      findsOneWidget,
    );
  });

  testWidgets('without a label says another phone', (tester) async {
    await tester.pumpWidget(shotApp(const CarryOnScreen()));
    expect(
      find.text('You started this case on another phone. It moved with you.'),
      findsOneWidget,
    );
  });

  testWidgets('Carry on here opens the lesson', (tester) async {
    await tester.pumpWidget(shotApp(const CarryOnScreen()));
    await tester.tap(find.text('Carry on here'));
    await tester.pumpAndSettle();
    expect(find.text('went to ${Paths.lessonCarryOnHere}'), findsOneWidget);
  });
}
