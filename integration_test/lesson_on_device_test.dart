import 'package:auramath/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Plays the lemon lesson on a real build (simulator or phone): the real
/// SQLite outbox, file storage and voice plugin, not test fakes.
///
/// Run on a fresh install:
/// `flutter test integration_test -d <device> --dart-define-from-file=env/dev.json`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a child solves the lemon tree case by drawing it', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    Future<void> tap(Finder f) async {
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> type(String digits) async {
      for (final d in digits.split('')) {
        await tap(find.text(d).last);
      }
      await tap(find.byIcon(Icons.check_rounded));
    }

    expect(find.text('Ready for a new case?'), findsOneWidget);
    await tap(find.text('Keep going'));
    await tap(find.text("Got it, let's draw"));
    expect(find.text('Drag a bar up here.'), findsOneWidget);
    await tap(find.byKey(const Key('slotA')));
    await tap(find.byKey(const Key('piece')));
    await tap(find.byKey(const Key('slotB')));
    await tap(find.text('Shorter'));
    await tap(find.byKey(const Key('piece')));
    await tap(find.byKey(const Key('gapSlot')));
    await tap(find.byKey(const Key('piece')));
    await tap(find.byKey(const Key('totalSlot')));
    await tap(find.text('186 − 107'));
    await type('79');
    expect(find.text('Yes! 79 cm!'), findsOneWidget);

    // the break sheet, then back to the lesson
    await tap(find.byIcon(Icons.home_rounded));
    expect(find.text('Take a break?'), findsOneWidget);
    await tap(find.text('Keep going'));

    await type('265');
    expect(find.text('Case cracked!'), findsOneWidget);
    await tap(find.text('Next'));
    expect(find.text('Tree Detective'), findsOneWidget);
    await tap(find.text('Add to my sash'));
    // the engine's next problem for a clean solve: the "shorter" wording
    expect(find.textContaining('107 cm shorter'), findsOneWidget);
  });
}
