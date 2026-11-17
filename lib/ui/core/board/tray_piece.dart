import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';
import 'gap_segment.dart' show DashedEdge;

/// What the child can place next.
enum BoardPiece { bar, gap, total }

/// A piece waiting in the tray. Figma: Prototype parts › Tray piece.
class TrayPiece extends StatelessWidget {
  const TrayPiece({
    super.key,
    required this.piece,
    required this.label,
    this.armed = false,
    this.glow = false,
    this.barColor = AuraColors.blue,
  });

  /// The bar piece in its bar's colour: yellow for A, blue for B.
  final Color barColor;

  final BoardPiece piece;
  final String label;

  /// Picked up by a tap, waiting for a tap on where it goes.
  final bool armed;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final mini = switch (piece) {
      // the prototype's minis: a little bar, a dashed gap, a brace
      BoardPiece.bar => Container(
        width: 22,
        height: 36,
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(8),
            bottom: Radius.circular(3),
          ),
        ),
        foregroundDecoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AuraColors.barShade, width: 4),
          ),
        ),
      ),
      BoardPiece.gap => const SizedBox(
        width: 40,
        height: 22,
        child: CustomPaint(
          painter: DashedEdge(color: AuraColors.blue, radius: 8),
        ),
      ),
      BoardPiece.total => Container(
        width: 44,
        height: 14,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AuraColors.navy, width: 3),
            right: BorderSide(color: AuraColors.navy, width: 3),
            bottom: BorderSide(color: AuraColors.navy, width: 3),
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
      ),
    };
    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mini,
        const SizedBox(width: 10),
        Text(label, style: AuraText.standing),
      ],
    );
    // the quiet child's glow: a yellow halo swelling and fading, 1.2 s
    return Loop(
      key: ValueKey(glow),
      period: const Duration(milliseconds: 1200),
      times: glow ? null : 0,
      child: body,
      builder: (context, t, child) {
        final k = glow ? (calmMotion(context) ? 1.0 : halfway(t)) : 0.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, armed ? -6 : 0, 0),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
          decoration: BoxDecoration(
            color: AuraColors.white,
            borderRadius: BorderRadius.circular(AuraRadii.panel),
            border: Border.all(color: AuraColors.blue, width: 3),
            boxShadow: [
              const BoxShadow(color: AuraColors.blueLip, offset: Offset(0, 5)),
              if (armed)
                const BoxShadow(
                  color: AuraColors.yellow,
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              if (k > 0)
                BoxShadow(
                  color: AuraColors.yellow.withValues(alpha: 0.55 * k),
                  spreadRadius: 10 * k,
                ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
