import 'package:auramath/ui/core/theme/app_theme.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/lesson/tutor_harness.dart';

/// NFR-05 (host proxy): the phone's own check of a tap shows within
/// 100 ms at the 95th percentile (PRD v4.1 §13.4). Measured here on the
/// host, in the whole lesson ([LessonFlow] over the real view model and
/// engine, the outbox in memory): from the tap reaching the board to the
/// frame that shows its feedback built, laid out and painted. It leaves
/// out the device's touch latency and the GPU's raster, so it is a proxy;
/// the reference phones' numbers still come from the device run (NFR-01).
/// Each measured tap is printed, so a slow build shows in the log.
void main() {
  /// The PRD's budget, at the 95th percentile.
  const budgetMs = 100;
  const runs = 30;

  double p95(List<double> ms) {
    final sorted = [...ms]..sort();
    return sorted[((sorted.length - 1) * 0.95).ceil()];
  }

  void report(String what, List<double> ms) {
    final sorted = [...ms]..sort();
    // ignore: avoid_print
    print(
      'NFR-05 $what: n=${ms.length} '
      'median ${sorted[sorted.length ~/ 2].toStringAsFixed(2)} ms, '
      'p95 ${p95(ms).toStringAsFixed(2)} ms, '
      'max ${sorted.last.toStringAsFixed(2)} ms',
    );
  }

  /// The tap on [target] and the frame after it, timed; [shown] says the
  /// feedback is on screen.
  Future<double> timedTap(
    WidgetTester tester,
    Finder target,
    bool Function() shown,
  ) async {
    final watch = Stopwatch()..start();
    await tester.tap(target, warnIfMissed: false);
    await tester.pump();
    watch.stop();
    expect(shown(), isTrue, reason: 'the feedback is in that frame');
    return watch.elapsedMicroseconds / 1000;
  }

  testWidgets('a size chip on the board: the bar sized, within the budget', (
    tester,
  ) async {
    final ms = <double>[];
    for (var i = 0; i < runs; i++) {
      final t = await pumpLesson(tester, theme: buildAuraTheme());
      await t.send(toSizeB);
      ms.add(
        await timedTap(
          tester,
          find.text('Shorter'),
          () => t.vm.state.step != LessonStep.sizeB,
        ),
      );
      await tester.pumpWidget(const SizedBox());
    }
    report('size chip', ms);
    expect(p95(ms), lessThan(budgetMs));
  });

  testWidgets('a wrong sum typed: the wobble, within the budget', (
    tester,
  ) async {
    final t = await pumpLesson(tester, theme: buildAuraTheme());
    await t.send(toFindB);
    final ms = <double>[];
    for (var i = 0; i < runs; i++) {
      for (final d in '300'.split('')) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      final before = t.vm.wobbles;
      ms.add(
        await timedTap(
          tester,
          find.byIcon(Icons.check_rounded),
          () => t.vm.wobbles == before + 1,
        ),
      );
      // the outbox's write finishes outside the measured frame
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pumpAndSettle();
    }
    report('wrong sum', ms);
    expect(p95(ms), lessThan(budgetMs));
  });
}
