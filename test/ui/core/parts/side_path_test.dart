import 'package:auramath/ui/core/parts/lesson_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// JRN-04: a detour shows a small out-and-back side path in the lesson
/// header; outside one, none.
void main() {
  Widget header({bool detour = false}) => MaterialApp(
    home: Scaffold(
      body: LessonHeader(
        line: 'Take one ten across.',
        onSpeak: () {},
        muted: false,
        onSound: (_) {},
        onHome: () {},
        sidePath: detour
            ? (label: 'Side path', back: 'Back to your case')
            : null,
      ),
    ),
  );

  testWidgets('a detour: the side path, named for screen readers', (
    tester,
  ) async {
    await tester.pumpWidget(header(detour: true));
    expect(find.byKey(const Key('sidePath')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Side path. Back to your case'),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'\d')), findsNothing);
  });

  testWidgets('on the case: no side path', (tester) async {
    await tester.pumpWidget(header());
    expect(find.byKey(const Key('sidePath')), findsNothing);
  });
}
