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

  testWidgets('no countdown: the first sum shows at once (SES-02); a right '
      'answer plays SFX.right and nothing is counted on screen (LES-16); '
      'the end is Warmed up!', (tester) async {
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
    expect(find.byKey(const Key('quickCount')), findsNothing);
    expect(find.byKey(const Key('quickSum')), findsOneWidget);
    for (final n in ['3', '2', '1', 'Go!']) {
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.data == n && (w.style?.fontSize ?? 0) > 60,
        ),
        findsNothing,
      );
    }
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
      // nothing counted: no meter mark, no tier toast
      expect(find.textContaining('Charged up'), findsNothing);
      expect(find.textContaining('On fire'), findsNothing);
    }
    expect(rec.played.where((s) => s == Sfx.right), hasLength(5));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Warmed up!'), findsOneWidget);
    expect(rec.played.last, Sfx.badge);
    await tester.pump(const Duration(seconds: 2));
    await _save(tester, 'QS3');
    await tester.pumpWidget(const SizedBox());
  });
}
