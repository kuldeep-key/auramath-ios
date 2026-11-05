import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The total: a bracket under both bars with its value in a pill.
/// Figma: Prototype parts › Brace.
class Brace extends StatelessWidget {
  const Brace({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        height: 16,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AuraColors.navy, width: 3),
            right: BorderSide(color: AuraColors.navy, width: 3),
            bottom: BorderSide(color: AuraColors.navy, width: 3),
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AuraRadii.small),
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AuraColors.navy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: AuraText.braceLabel),
        ),
      ),
    ],
  );
}
