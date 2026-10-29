import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum AuraButtonColor { yellow, blue, white }

/// The one button for every screen, as Figma's Button component (265:25562,
/// size M): a glossy gradient, a glare strip across the top, a dark band
/// inside the bottom edge, a 3 pt navy edge and a 6 pt navy lip that
/// shrinks to 2 pt when pressed. Yellow is the main action in play mode,
/// blue the main action, white the secondary.
class AuraButton extends StatefulWidget {
  const AuraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AuraButtonColor.yellow,
    this.icon,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final AuraButtonColor color;
  final IconData? icon;

  /// A mark before the label: the Apple logo or Google's "G" on the sign-in
  /// buttons, which their brand rules put on the left.
  final Widget? leading;

  @override
  State<AuraButton> createState() => _AuraButtonState();
}

/// One colour of the button: gradient, glare, label.
typedef _Look = ({
  Color top,
  Color bottom,
  Color edge,
  double glare,
  Color fg,
  bool labelShadow,
});

class _AuraButtonState extends State<AuraButton> {
  bool _down = false;

  static const _disabled = (
    top: AuraColors.buttonOffTop,
    bottom: AuraColors.buttonOffBottom,
    edge: AuraColors.buttonOffEdge,
    glare: 0.0,
    fg: AuraColors.buttonOffText,
    labelShadow: false,
  );

  _Look get _look => switch (widget.color) {
    AuraButtonColor.yellow => (
      top: AuraColors.yellowTop,
      bottom: AuraColors.yellowBottom,
      edge: AuraColors.navy,
      glare: 0.35,
      fg: AuraColors.buttonYellowText,
      labelShadow: false,
    ),
    AuraButtonColor.blue => (
      top: AuraColors.blueTop,
      bottom: AuraColors.blueLip,
      edge: AuraColors.navy,
      glare: 0.35,
      fg: AuraColors.white,
      labelShadow: true,
    ),
    AuraButtonColor.white => (
      top: AuraColors.white,
      bottom: AuraColors.whiteBottom,
      edge: AuraColors.navy,
      glare: 0.9,
      fg: AuraColors.navy,
      labelShadow: false,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final look = enabled ? _look : _disabled;
    final lip = _down ? 2.0 : 6.0;
    const inner = BorderRadius.all(Radius.circular(AuraRadii.button - 3));
    final shadow = look.labelShadow
        ? const [Shadow(color: AuraColors.navy, offset: Offset(0, 2))]
        : null;
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
          opacity: enabled ? 1 : 0.55,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            margin: EdgeInsets.only(top: 6 - lip),
            constraints: const BoxConstraints(minHeight: 64, minWidth: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AuraRadii.button),
              border: Border.all(color: look.edge, width: 3),
              boxShadow: [BoxShadow(color: look.edge, offset: Offset(0, lip))],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [look.top, look.bottom],
              ),
            ),
            child: ClipRRect(
              borderRadius: inner,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // the glare across the top
                  if (look.glare > 0)
                    Positioned(
                      top: 2,
                      left: 5,
                      right: 5,
                      height: 22,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AuraColors.white.withValues(alpha: look.glare),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  // the dark band inside the bottom edge
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 5,
                    child: ColoredBox(color: AuraColors.buttonInnerShade),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: AuraText.button.copyWith(
                              color: look.fg,
                              shadows: shadow,
                            ),
                          ),
                        ),
                        if (widget.icon != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            widget.icon,
                            size: 25.6,
                            color: look.fg,
                            shadows: shadow,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
