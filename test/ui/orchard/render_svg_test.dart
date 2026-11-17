import 'dart:io';
import 'dart:ui' as ui;

import 'package:auramath/ui/features/child_home/views/orchard/mini_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/shots.dart';

void main() {
  testWidgets('render', (tester) async {
    final src = Platform.environment['ORCHARD_SVG'];
    final out = Platform.environment['ORCHARD_PNG'];
    if (src == null || out == null) return;
    await loadAppFonts();
    final t = double.parse(Platform.environment['ORCHARD_T'] ?? '0');
    await tester.runAsync(() async {
      final svg = MiniSvg.parse(File(src).readAsStringSync());
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      svg.paint(
        c,
        t: t,
        still: Platform.environment['ORCHARD_STILL'] == '1',
        walked: 1e9,
      );
      final img = await rec.endRecording().toImage(
        svg.width.ceil(),
        svg.height.ceil(),
      );
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
