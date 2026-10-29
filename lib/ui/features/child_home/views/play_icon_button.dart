import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';

/// The small white square button on blue screens (home, the grown-ups'
/// lock). Figma draws it 48 pt; the tap area is 56 pt, the child minimum.
class PlayIconButton extends StatelessWidget {
  const PlayIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 56,
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AuraColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuraColors.navy, width: 3),
                boxShadow: const [
                  BoxShadow(color: AuraColors.navy, offset: Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: AuraColors.navy),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Home on the left, the screen's ribbon beside it (B1, K2).
class PlayHeader extends StatelessWidget {
  const PlayHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Row(
      spacing: 6,
      children: [
        PlayIconButton(
          icon: Icons.home_outlined,
          tooltip: AppLocalizations.of(context)!.kidHome,
          onPressed: () => context.go(Paths.home),
        ),
        Expanded(child: Ribbon(text: title)),
      ],
    ),
  );
}
