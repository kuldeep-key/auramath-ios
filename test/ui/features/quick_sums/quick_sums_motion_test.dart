// The prototype's rush timings (QSgo, QS2, QS3), frame by frame, with
// motion on; and, with SHOTS=1, the screens beside the prototype's.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/features/quick_sums/view_models/quick_sums_view_model.dart';
import 'package:auramath/ui/features/quick_sums/views/quick_sums_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import '../lesson/fakes.dart';
import 'quick_sums_test.dart' show sum;

final _shots = Platform.environment['SHOTS'] == '1';

Future<void> _save(WidgetTester tester, String name) async {
  if (!_shots) return;
  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('protoShot')),
  );
  await tester.runAsync(() async {
    final image = await b.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/shots/proto/$name-app.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  late RecordingSfxPlayer rec;
  setUp(() {
    AuraMotion.still = false;
    rec = RecordingSfxPlayer();
    AuraSound.player = rec;
  });
  tearDown(() {
    AuraMotion.still = true;
    AuraSound.player = const SilentSfxPlayer();
  });

  testWidgets('3, 2, 1, Go! 700 ms a beat, the first sum at 2.8 s; a right '
      'answer surges the meter and plays SFX.right; the end is Warmed up!', (
    tester,
  ) async {
    if (_shots) await tester.runAsync(loadAppFonts);
    tester.view.physicalSize = const Size(369, 828);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44);
    addTearDown(tester.view.reset);
    final vm = (await tester.runAsync(() async {
      final (sessions, _, api) = await memorySessions();
      api.sums.addAll([for (var i = 0; i < 5; i++) sum(80, 60)]);
      final vm = QuickSumsViewModel(sessions: sessions, childId: 'kid12345');
      await vm.start();
      return vm;
    }))!;
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('protoShot'),
        child: shotApp(QuickSumsScreen(vm: vm, onHome: () {}, onStory: () {})),
      ),
    );
    await tester.pump();
    String count() =>
        tester.widget<Text>(find.byKey(const Key('quickCount'))).data!;
    expect(count(), '3');
    await tester.pump(const Duration(milliseconds: 350));
    await _save(tester, 'QSgo');
    await tester.pump(const Duration(milliseconds: 350));
    expect(count(), '2');
    await tester.pump(const Duration(milliseconds: 700));
    expect(count(), '1');
    await tester.pump(const Duration(milliseconds: 700));
    expect(count(), 'Go!');
    expect(find.byKey(const Key('quickSum')), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.byKey(const Key('quickCount')), findsNothing);
    expect(find.byKey(const Key('quickSum')), findsOneWidget);
    // the card flies in over 260 ms
    await tester.pump(const Duration(milliseconds: 300));
    await _save(tester, 'QS2');

    rec.played.clear();
    for (var i = 0; i < 5; i++) {
      for (final d in '20'.split('')) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('keypadCheck')));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump(const Duration(milliseconds: 400));
      if (i == 1) {
        // the second right answer reaches the first mark
        expect(find.text('⚡ Charged up!'), findsOneWidget);
        // the new card and the toast start on this frame: 300 ms on, the
        // card has landed and the toast holds
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.getSize(find.byKey(const Key('quickSum'))).height,
          greaterThan(40),
        );
        await _save(tester, 'QS2-surge');
      }
    }
    expect(rec.played.where((s) => s == Sfx.right), hasLength(5));
    expect(rec.played, contains(Sfx.win));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Warmed up!'), findsOneWidget);
    expect(rec.played.last, Sfx.badge);
    await tester.pump(const Duration(seconds: 2));
    await _save(tester, 'QS3');
    await tester.pumpWidget(const SizedBox());
  });
}
