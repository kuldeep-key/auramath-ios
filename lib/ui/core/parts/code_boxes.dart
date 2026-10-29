import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A short code shown one digit per box: the pairing code a grown-up reads
/// out (JoinCode, NewCode), the digits a child types (GetCode), the
/// passcode dots (GPass). Boxes shrink to fit narrow phones, up to 52 pt.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    required this.length,
    required this.value,
    this.obscure = false,
    this.light = false,
  });

  final int length;
  final String value;

  /// Dots instead of digits (a passcode).
  final bool obscure;

  /// White boxes on the blue play background.
  final bool light;

  // No LayoutBuilder: pages ask their body for its intrinsic height
  // (AuraPage), which a LayoutBuilder can't answer.
  @override
  Widget build(BuildContext context) => Semantics(
    label: obscure
        ? '${value.length} of $length digits'
        : value.split('').join(' '),
    excludeSemantics: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 52),
              child: AspectRatio(
                aspectRatio: 1 / 1.15,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: light ? AuraColors.white : AuraColors.blueTint,
                    borderRadius: BorderRadius.circular(AuraRadii.small),
                    border: Border.all(
                      color: i == value.length
                          ? AuraColors.blue
                          : (light ? AuraColors.navy : AuraColors.line),
                      width: 2,
                    ),
                  ),
                  child: i < value.length
                      ? FittedBox(
                          child: Text(
                            obscure ? '•' : value[i],
                            style: AuraText.codeDigit,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
