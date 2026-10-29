import 'package:auramath/ui/core/parts/keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> changes;
  late List<String> checks;

  Future<void> pumpPad(WidgetTester tester) async {
    changes = [];
    checks = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Keypad(onChanged: changes.add, onCheck: checks.add),
        ),
      ),
    );
  }

  Future<void> keys(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  Future<void> check(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump();
  }

  testWidgets('Keypad builds 1 2 3 and reports "123"', (tester) async {
    await pumpPad(tester);
    await keys(tester, '123');
    expect(changes.last, '123');
    await check(tester);
    expect(checks, ['123']);
    expect(changes.last, '', reason: 'clears after a check');
  });

  testWidgets('Keypad ignores a 5th digit', (tester) async {
    await pumpPad(tester);
    await keys(tester, '12345');
    expect(changes.last, '1234');
  });

  testWidgets('Keypad check with nothing typed does not call onCheck', (
    tester,
  ) async {
    await pumpPad(tester);
    await check(tester);
    expect(checks, isEmpty);
  });

  testWidgets('Keypad hands back "007" as typed; a lesson reads 7', (
    tester,
  ) async {
    await pumpPad(tester);
    await keys(tester, '007');
    await check(tester);
    expect(checks, ['007']); // a code keeps its zeros
    expect(int.parse(checks.single), 7);
  });

  testWidgets('Keypad delete removes the last digit', (tester) async {
    await pumpPad(tester);
    await keys(tester, '79');
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(changes.last, '7');
  });
}
