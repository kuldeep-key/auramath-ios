// Renders the lesson at the prototype's screen size (369 x 828 inside the
// device frame) so each step can be set beside the prototype's own PNG.
// Run with SHOTS=1 to write build/shots/proto/<Screen>-app.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/core/theme/app_theme.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart' show loadAppFonts;
import 'fakes.dart';

final _on = Platform.environment['SHOTS'] == '1';

Future<void> _save(WidgetTester tester, String name) async {
  if (!_on) return;
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
  testWidgets('lesson steps beside the prototype', (tester) async {
    if (_on) await tester.runAsync(loadAppFonts);
    tester.view.physicalSize = const Size(369, 828);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44);
    addTearDown(tester.view.reset);
    final (sessions, _, _) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    );
    addTearDown(vm.dispose);
    vm
      ..selfRating = true
      ..childAge = 8
      ..showBadges = false;
    await tester.runAsync(vm.start);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('protoShot'),
        child: MaterialApp(
          theme: buildAuraTheme(),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {}),
        ),
      ),
    );
    Future<void> settle() async {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
    }

    Future<void> send(LessonInput i) async {
      await tester.runAsync(() async => vm.send(i));
      await settle();
    }

    // the prototype's M0 shot catches the read-along on its 2nd word
    await tester.pump(const Duration(milliseconds: 450 + 200 + 330 + 100));
    await _save(tester, 'M0');
    await settle();
    await tester.tap(find.text("Let's draw it"));
    await settle();
    await _save(tester, 'M1-D1');
    await send(const BarADrawn());
    await _save(tester, 'M1-D2');
    await send(const BarBPlaced());
    await _save(tester, 'M1-D2s');
    await send(const BarBSized(Relation.shorter));
    await _save(tester, 'M1-D3');
    await send(const PieceDropped(Piece.gap, Target.gapSlot));
    await _save(tester, 'M1-D3b');
    await send(const PieceDropped(Piece.total, Target.totalSlot));
    await _save(tester, 'M1-D4');
    await send(const OpChosen(Op.subtract));
    await _save(tester, 'M1-D5');
    await send(const NumberEntered(79));
    await _save(tester, 'M1-D6');
    await send(const NumberEntered(265));
    await _save(tester, 'Y2');
    await tester.tap(find.text('Next'));
    await settle();
    await _save(tester, 'Rate');
    await tester.pumpWidget(const SizedBox());
  });
}
