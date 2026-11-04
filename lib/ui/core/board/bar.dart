import 'package:flutter/material.dart';

import '../motion/motion.dart';
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
/// While a piece is on its way ([waiting]) it pulses blue (1.1 s); with the
/// piece over it ([hot]) it grows a touch and its edge goes solid.
class DashedSlot extends StatelessWidget {
  const DashedSlot({
    super.key,
    required this.label,
    this.waiting = false,
    this.hot = false,
  });

  final String label;
  final bool waiting;
  final bool hot;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: hot && !calmMotion(context) ? 1.05 : 1,
    duration: const Duration(milliseconds: 300),
    child: Loop(
      key: ValueKey(waiting && !hot),
      period: const Duration(milliseconds: 1100),
      times: waiting && !hot ? null : 0,
      builder: (context, t, child) {
        final k = waiting && !hot ? halfway(t) : 0.0;
        final on = waiting || hot;
        return CustomPaint(
          painter: _DashPainter(
            on ? AuraColors.blue : AuraColors.blueInk,
            solid: hot,
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hot
                  ? Color.alphaBlend(
                      AuraColors.blue.withValues(alpha: 0.18),
                      AuraColors.white,
                    )
                  : Color.lerp(
                      on ? AuraColors.blueTint : AuraColors.soft,
                      Color.alphaBlend(
                        AuraColors.blue.withValues(alpha: 0.12),
                        AuraColors.white,
                      ),
                      k,
                    ),
              borderRadius: BorderRadius.circular(AuraRadii.barTop),
              boxShadow: [
                if (k > 0)
                  BoxShadow(
                    color: AuraColors.blue.withValues(alpha: 0.10 * k),
                    spreadRadius: 6 * k,
                  ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AuraText.slotLabel,
      ),
    ),
  );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, {this.solid = false});

  final Color color;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AuraRadii.barTop),
    );
    final paint = Paint()
      ..color = color.withValues(alpha: solid ? 1 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = solid ? 3 : 2.5;
    if (solid) return canvas.drawRRect(rrect, paint);
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.solid != solid;
}
