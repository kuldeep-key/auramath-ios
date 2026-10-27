import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum AuraButtonColor { yellow, blue, white }

/// The chunky main button: navy outline and a solid navy lip under it that
/// shrinks when pressed. Figma: Prototype parts › Button.
class AuraButton extends StatefulWidget {
  const AuraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AuraButtonColor.yellow,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AuraButtonColor color;
  final IconData? icon;

  @override
  State<AuraButton> createState() => _AuraButtonState();
}

class _AuraButtonState extends State<AuraButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final (fill, fg) = switch (widget.color) {
      AuraButtonColor.yellow => (AuraColors.yellow, AuraColors.yellowFg),
      AuraButtonColor.blue => (AuraColors.blue, AuraColors.white),
      AuraButtonColor.white => (AuraColors.white, AuraColors.navy),
    };
    final lip = _down ? 2.0 : 6.0;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            margin: EdgeInsets.only(top: 6 - lip),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AuraRadii.button),
              border: Border.all(color: AuraColors.navy, width: 3),
              boxShadow: [
                BoxShadow(color: AuraColors.navy, offset: Offset(0, lip)),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.55],
                colors: [Color.lerp(fill, AuraColors.white, 0.18)!, fill],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: AuraText.button.copyWith(color: fg),
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(widget.icon, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
