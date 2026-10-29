import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A short code shown one digit per box: the pairing code a grown-up reads
/// out (JoinCode, NewCode), the digits a child types (GetCode), the
/// passcode dots (GPass). Shrinks its boxes to fit narrow phones.
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

  @override
  Widget build(BuildContext context) => Semantics(
    label: obscure
        ? '${value.length} of $length digits'
        : value.split('').join(' '),
    excludeSemantics: true,
    child: LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0;
        final size = ((box.maxWidth - gap * (length - 1)) / length).clamp(
          28.0,
          52.0,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Container(
                width: size,
                height: size * 1.15,
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
                    ? Text(
                        obscure ? '•' : value[i],
                        style: AuraText.title.copyWith(color: AuraColors.navy),
                      )
                    : null,
              ),
            ],
          ],
        );
      },
    ),
  );
}
