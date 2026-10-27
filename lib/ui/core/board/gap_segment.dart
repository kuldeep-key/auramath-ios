import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The difference, drawn on top of the shorter bar.
/// Figma: Prototype parts › Gap segment.
class GapSegment extends StatelessWidget {
  const GapSegment({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AuraColors.white,
      borderRadius: BorderRadius.circular(AuraRadii.barTop),
      border: Border.all(color: AuraColors.blue, width: 3),
    ),
    child: Text(
      label,
      style: AuraText.chip.copyWith(color: AuraColors.blueInk, fontSize: 19),
    ),
  );
}
