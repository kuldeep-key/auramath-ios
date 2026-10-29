import 'package:flutter/material.dart';

import '../theme/tokens.dart';

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
  });

  final BoardPiece piece;
  final String label;

  /// Picked up by a tap, waiting for a tap on where it goes.
  final bool armed;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final mini = switch (piece) {
      BoardPiece.bar => Container(
        width: 22,
        height: 32,
        decoration: BoxDecoration(
          color: AuraColors.blue,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      BoardPiece.gap => Container(
        width: 36,
        height: 22,
        decoration: BoxDecoration(
          border: Border.all(color: AuraColors.blue, width: 3),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      BoardPiece.total => Container(
        width: 36,
        height: 12,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AuraColors.navy, width: 3),
            right: BorderSide(color: AuraColors.navy, width: 3),
            bottom: BorderSide(color: AuraColors.navy, width: 3),
          ),
        ),
      ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(0, armed ? -6 : 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(AuraRadii.panel),
        border: Border.all(color: AuraColors.blue, width: 3),
        boxShadow: [
          const BoxShadow(color: AuraColors.blueLip, offset: Offset(0, 5)),
          if (glow || armed)
            const BoxShadow(
              color: AuraColors.yellow,
              blurRadius: 18,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mini,
          const SizedBox(width: 10),
          Text(label, style: AuraText.standing),
        ],
      ),
    );
  }
}
