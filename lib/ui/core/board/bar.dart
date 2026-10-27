import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One bar of the model: rounded on top, square-ish at the base, with an
/// inset shade along the bottom. Figma: Prototype parts › Bar.
class Bar extends StatelessWidget {
  const Bar({super.key, required this.color, this.child});

  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AuraRadii.barTop),
        bottom: Radius.circular(AuraRadii.barBottom),
      ),
    ),
    foregroundDecoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AuraColors.barShade, width: 6)),
    ),
    alignment: Alignment.center,
    child: child,
  );
}

/// A dashed drop zone with a quiet label. Figma: Prototype parts › Bar slot.
class DashedSlot extends StatelessWidget {
  const DashedSlot({super.key, required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashPainter(highlight ? AuraColors.blue : AuraColors.blueInk),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight ? AuraColors.blueTint : AuraColors.soft,
        borderRadius: BorderRadius.circular(AuraRadii.barTop),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AuraText.body.copyWith(color: AuraColors.blueInk, fontSize: 15),
      ),
    ),
  );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AuraRadii.barTop),
    );
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
