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
    await tester.tap(find.text('Try again'));
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
    expect(find.text('Lost the internet. Your work is saved.'), findsOneWidget);
  });
}
