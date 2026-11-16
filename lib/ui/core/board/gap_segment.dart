import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The difference, drawn on top of the shorter bar: white, with the
/// prototype's dashed blue edge (`.gapseg`: 3 px dashed, radius 14).
/// Figma: Prototype parts › Gap segment.
class GapSegment extends StatelessWidget {
  const GapSegment({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: const DashedEdge(color: AuraColors.blue),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(AuraRadii.barTop),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: AuraText.gap),
      ),
    ),
  );
}

/// A dashed rounded edge, 3 px: 7 on, 5 off.
class DashedEdge extends CustomPainter {
  const DashedEdge({
    required this.color,
    this.width = 3,
    this.radius = AuraRadii.barTop,
  });

  final Color color;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedEdge old) =>
      old.color != color || old.width != width || old.radius != radius;
}
