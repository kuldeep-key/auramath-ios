import 'package:auramath/ui/features/lesson/views/break_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';

void main() {
  testWidgets('need-the-internet fits every size and retries', (tester) async {
    var retried = 0;
    await shotAllSizes(
      tester,
      'lesson_need_internet',
      NeedInternetView(onRetry: () => retried++, onGoHome: () {}),
    );
    await tester.pumpWidget(
      shotApp(NeedInternetView(onRetry: () => retried++, onGoHome: () {})),
    );
    await tester.tap(find.text('Check again'));
    expect(retried, 1);
  });

  testWidgets('lost-the-internet pause fits every size', (tester) async {
    await shotAllSizes(
      tester,
      'lesson_lost_internet',
      Scaffold(
        body: LostInternetPause(onRetry: () {}, onGoHome: () {}),
      ),
    );
    expect(find.text('Lost the internet'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
  });

  testWidgets("time's up (TU) fits every size: Call it a day, or finish "
      'first while a case is open', (tester) async {
    var stopped = 0, finished = 0;
    await shotAllSizes(
      tester,
      'lesson_time_up',
      Scaffold(body: TimeUpView(onStop: () {})),
    );
    expect(find.text('Call it a day'), findsOneWidget);
    expect(find.text('Finish this one'), findsNothing);
    await tester.pumpWidget(
      shotApp(TimeUpView(onStop: () => stopped++, onFinish: () => finished++)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish this one'));
    await tester.tap(find.text('Call it a day'));
    expect((finished, stopped), (1, 1));
  });
}
