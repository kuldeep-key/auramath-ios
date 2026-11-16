// The prototype's timings, frame by frame: what shows at each point of an
// animation (motion on, unlike the rest of the suite).
import 'package:auramath/ui/core/motion/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tutor_harness.dart';

/// The word lit on the story (a span with the yellow tint behind it).
String? litWord(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find.descendant(
      of: find.byKey(const Key('story')),
      matching: find.byType(RichText),
    ),
  );
  String? lit;
  rich.text.visitChildren((s) {
    if (s is TextSpan && s.style?.backgroundColor != null) lit = s.text;
    return true;
  });
  return lit;
}

void main() {
  setUp(() => AuraMotion.still = false);
  tearDown(() => AuraMotion.still = true);

  testWidgets('M0 reads along: from 650 ms one word lights every 330 ms', (
    tester,
  ) async {
    final t = await pumpLessonMoving(tester);
    expect(litWord(tester), isNull);
    await tester.pump(const Duration(milliseconds: 450)); // read starts
    await tester.pump(const Duration(milliseconds: 199));
    expect(litWord(tester), isNull, reason: '200 ms lead');
    await tester.pump(const Duration(milliseconds: 11));
    expect(litWord(tester), 'The');
    await tester.pump(const Duration(milliseconds: 330));
    expect(litWord(tester), 'lemon');
    await tester.pump(const Duration(milliseconds: 330));
    expect(litWord(tester), 'tree');
    await tester.pump(const Duration(seconds: 30));
    expect(litWord(tester), isNull, reason: 'cleared at the end');
    // Hear it again runs it again from the first word
    await tester.ensureVisible(find.byKey(const Key('hearItAgain')));
    await tester.tap(find.byKey(const Key('hearItAgain')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 210));
    expect(litWord(tester), 'The');
    expect(t.voice.said, hasLength(2), reason: 'and the story is read');
    await tester.pumpWidget(const SizedBox());
  });
}
