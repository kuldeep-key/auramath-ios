import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// White card with a soft line border and a flat 4 px lip.
class AuraCard extends StatelessWidget {
  const AuraCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: AuraColors.white,
      borderRadius: BorderRadius.circular(AuraRadii.card),
      border: Border.all(color: AuraColors.line, width: 2),
      boxShadow: const [
        BoxShadow(color: AuraColors.line, offset: Offset(0, 4)),
      ],
    ),
    child: child,
  );
}
