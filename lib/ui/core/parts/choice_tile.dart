import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One answer in a list of choices: white with a ring, or yellow with a
/// blue tick when chosen. Figma: Prototype parts › Option (687:89) and
/// Tick (684:112, 684:115).
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.flag,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// A smaller line under the label.
  final String? detail;

  /// A small tag above the label ("Usual for age 7").
  final String? flag;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AuraRadii.button);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? AuraColors.yellowTint : AuraColors.white,
              borderRadius: radius,
              border: Border.all(
                color: selected ? AuraColors.yellow : AuraColors.line,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected ? AuraColors.yellowLip : AuraColors.line,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (flag != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AuraColors.flag,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(flag!, style: AuraText.flag),
                        ),
                      Text(label, style: AuraText.option),
                      if (detail != null)
                        Text(detail!, style: AuraText.optionDetail),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Tick(on: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The round tick on a choice.
class Tick extends StatelessWidget {
  const Tick({super.key, required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? AuraColors.blue : null,
      border: Border.all(
        color: on ? AuraColors.blue : AuraColors.tickOff,
        width: 2,
      ),
    ),
    child: on
        ? const Icon(Icons.check_rounded, size: 18, color: AuraColors.white)
        : null,
  );
}
